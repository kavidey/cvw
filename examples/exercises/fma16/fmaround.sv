///////////////////////////////////////////
// fmaround
//
// Written: Kavi Dey kdey@hmc.edu
// Created: Feb 8, 2025
//
// Purpose: Round logic fused floating point multiply accumulate
///////////////////////////////////////////

`include "fma.vh"

module fmaround (
    input  logic [1:0]       roundmode,         // Rounding mode to use
    input  logic             kill_prod, kill_z, // Kill addend or product
    input  logic             diff_sign,         // Product and sum have different signs
    input  logic             kill_guard,        // Whether to kill the guard bit during rounding
    input  logic             a_sticky,          // Sticky bit result from killed bits before addition
    input  logic             p_sign,            // Product sign
    input  logic             m_sign,            // Sum sign
    input  logic [`NE+1:0]   m_exp,             // Sum exponent
    input  logic [`NF-1:0]   m_fract,           // Sum mantissa
    input  logic [4*`NF+5:0] m_shifted,         // Additional bits of mantissa (for rounding)
    output logic             r_sign,            // Rounded sign
    output logic [`NE-1:0]   r_exp,             // Rounded exponent
    output logic [`NF-1:0]   r_fract,           // Rounded mantissa
    output logic             m_zero,            // Sum is zero
    output logic             round_overflow,    // Overflow during rounding process
    output logic [4:0]       round_flags        // Bits used to determine rounding mode (sign, overflow, lsb, guard, sticky)
);

    ///// 8. Round the result and handle special cases: R = round(M) /////
    // Sum is equal to zero
    assign m_zero = ~((|m_fract) | (|m_exp));

    // Overflow with original m_exp (before rounding)
    logic round_overflow_orig;
    assign round_overflow_orig = (m_exp > `EMAX);

    // Calculate which rounding mode to use
    logic rne, rz, rp, rn;
    assign rz = roundmode == 2'b00; // round to zero
    assign rne = roundmode == 2'b01; // round to even
    assign rn = roundmode == 2'b10; // round down (toward negative infinity)
    assign rp = roundmode == 2'b11; // round up (toward positive infinity)

    // Determine rounding flags: sign_overflow_L_G_sticky
    assign round_flags = {m_sign, round_overflow_orig, m_shifted[2*`NF+2], m_shifted[2*`NF+1] & ~kill_guard, (|m_shifted[2*`NF:0]) | a_sticky};
    // Rounding flags are used to determine which rounding operation to do
    enum {TRUNC, RND, P_INF, N_INF, P_MAXNUM, N_MAXNUM} round_op;

    // Use the rounding table from the textbook to determine the rounding operation
    always_comb begin
        casez (round_flags)
            5'b?_0_?_0_0: round_op = TRUNC;
            5'b0_0_?_0_1:
                if (rp)
                    round_op = RND;
                else
                    round_op = TRUNC;
            5'b0_0_0_1_0:
                if (rp)
                    round_op = RND;
                else
                    round_op = TRUNC;
            5'b0_0_1_1_0:
                if (rne | rp)
                    round_op = RND;
                else
                    round_op = TRUNC;
            5'b0_0_?_1_1:
                if (rne | rp)
                    round_op = RND; 
                else
                    round_op = TRUNC;
            5'b0_1_?_?_?:
                if (rz | rn)
                    round_op = P_MAXNUM;
                else
                    round_op = P_INF;
            5'b1_0_?_0_1:
                if (rn)
                    round_op = RND;
                else
                    round_op = TRUNC;
            5'b1_0_0_1_0:
                if (rn)
                    round_op = RND;
                else
                    round_op = TRUNC;
            5'b1_0_1_1_0:
                if (rne | rn)
                    round_op = RND;
                else
                    round_op = TRUNC;
            5'b1_0_?_1_1:
                if (rne | rn)
                    round_op = RND; 
                else
                    round_op = TRUNC;
            5'b1_1_?_?_?:
                if (rz | rp)
                    round_op = N_MAXNUM;
                else
                    round_op = N_INF;
            default: round_op = TRUNC;
        endcase
    end

    // precompute exponent+1 and mantissa+1 in case the rounding operation is RND and there is an overflow
    logic [`NF+1:0] m_fract_p1;
    logic [`NE+1:0] m_exp_p1;
    assign m_fract_p1 = {1'b0, 1'b1, m_fract} + 1; // add the leading 1 and an extra overflow bit
    assign m_exp_p1 = m_exp + 1;

    // if the round mode was used and adding 1 overflowed into the exponent
    // then check if the new exponent overflowed since the old value maybe wrong
    assign round_overflow = (m_fract_p1[`NF+1] & (round_op == RND)) ? (m_exp_p1 > `EMAX) : round_overflow_orig;

    // Apply the rounding operation computed in the previous step
    always_comb begin
        case (round_op)
            TRUNC: begin
                r_exp = m_exp[`NE-1:0];
                r_fract = m_fract;
            end
            RND: begin
                // if the mantissa overflowed then pick the upper bits
                r_fract = m_fract_p1[`NF+1] ? m_fract_p1[`NF:1] : m_fract_p1[`NF-1:0];
                // if the mantissa overflowed use exponent plus 1
                r_exp = m_fract_p1[`NF+1] ? m_exp_p1[`NE-1:0] : m_exp[`NE-1:0];
            end
            P_INF: begin
                // replace with infinity (sign is set below)
                r_exp = {`NE{1'b1}};
                r_fract = {`NF{1'b0}};
            end
            N_INF: begin
                // replace with infinity (sign is set below)
                r_exp = {`NE{1'b1}};
                r_fract = {`NF{1'b0}};
            end
            P_MAXNUM: begin
                // replace with maxnum (sign is set below)
                r_exp = {{(`NE-1){1'b1}}, 1'b0};
                r_fract = {`NF{1'b1}};
            end
            N_MAXNUM: begin
                // replace with maxnum (sign is set below)
                r_exp = {{(`NE-1){1'b1}}, 1'b0};
                r_fract = {`NF{1'b1}};
            end
            default: begin
                r_exp = m_exp[`NE-1:0];
                r_fract = m_fract;
            end
        endcase
    end

    always_comb begin
        // override sign if the sum is zero and product/addend had different signs
        if (m_zero & diff_sign)
            // if z is 0 and x*y is non zero (but rounded to 0) use sign of x*y
            if (kill_z & (|round_flags[1:0]))
                r_sign = p_sign;
            else
                // "default" sign is 0 unless we're in RN rounding mode
                r_sign = rn ? 1 : 0;
        else
            r_sign = m_sign;
    end
endmodule