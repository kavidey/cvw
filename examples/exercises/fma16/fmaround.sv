///////////////////////////////////////////
// fmamul
//
// Written: Kavi Dey kdey@hmc.edu
// Created: Feb 8, 2025
//
// Purpose: Round logic fused floating point multiply accumulate
///////////////////////////////////////////

`include "fma.vh"

module fmaround (
    input  logic [1:0]       roundmode,
    input  logic             kill_prod, kill_z,
    input  logic             diff_sign, a_sticky,
    input  logic             m_sign,
    input  logic [`NF-1:0]   m_fract,
    input  logic [`NE+1:0]   m_exp,
    input  logic [4*`NF+5:0] m_shifted,
    output logic             r_sign,
    output logic [`NE-1:0]   r_exp,
    output logic [`NF-1:0]   r_fract
);
    // roundmode:
    //      00: round to zero
    //      01: round to even
    //      10: round down (toward negative infinity)
    //      11: round up (toward positive infinity)

    // 01 00 11 10


    ///// 8. Round the result and handle special cases: R = round(M) /////
    logic overflow;
    assign overflow = (m_exp > `EMAX);

    logic rne, rz, rp, rn;
    assign rne = roundmode == 2'b01;
    assign rz = roundmode == 2'b00;
    assign rp = roundmode == 2'b11;
    assign rn = roundmode == 2'b10;

    logic [4:0] round_flags; // sign_overflow_L_G_sticky
    assign round_flags = {m_sign, overflow, m_fract[0], m_shifted[2*`NF+1], |m_shifted[2*`NF:0]};
    logic [2:0] round_op;

    // 0: TRUNC, 1: RND, 2: +inf, 3: -inf, 4: +MAXNUM, 5: -MAXNUM
    always_comb begin
        casez (round_flags)
            5'b?_0_?_0_0: round_op = 0;
            5'b?_0_?_0_1:
                if (rp)
                    round_op = 1;
                else
                    round_op = 0;
            5'b?_0_0_1_0:
                if (rp)
                    round_op = 1;
                else
                    round_op = 0;
            5'b?_0_1_1_0:
                if (rne | rp)
                    round_op = 1;
                else
                    round_op = 0;
            5'b?_0_?_1_1:
                if (rne | rp)
                    round_op = 1;
                    // if (a_sticky & diff_sign) // could also use (kill_prod | kill_z) instead of a_sticky
                    //     round_op = 0;
                    // else
                    //     round_op = 1;
                else
                    round_op = 0;
            5'b0_1_?_?_?:
                if (rz | rn)
                    round_op = 4;
                else
                    round_op = 2;
            5'b1_1_?_?_?:
                if (rz | rp)
                    round_op = 5;
                else
                    round_op = 3;
            default: round_op = 0;
        endcase
    end

    logic [`NF+1:0] m_fract_p1;
    logic [`NE+1:0] m_exp_p1;
    assign m_fract_p1 = {1'b0, 1'b1, m_fract} + 1; // add the leading 1 and an extra overflow bit
    assign m_exp_p1 = m_exp + 1;

    always_comb begin
        case (round_op)
            3'd0: begin // TRUNC
                r_exp = m_exp[`NE-1:0];
                r_fract = m_fract;
            end
            3'd1: begin // RND
                r_fract = m_fract_p1[`NF+1] ? m_fract_p1[`NF:1] : m_fract_p1[`NF-1:0];
                r_exp = m_fract_p1[`NF+1] ? m_exp_p1[`NE-1:0] : m_exp[`NE-1:0];
            end
            3'd2: begin
                r_exp = {`NE{1'b1}};
                r_fract = {`NF{1'b0}};
            end
            3'd3: begin
                r_exp = {`NE{1'b1}};
                r_fract = {`NF{1'b0}};
            end
            3'd4: begin
                r_exp = {{(`NE-1){1'b1}}, 1'b0};
                r_fract = {`NF{1'b1}};
            end
            3'd5: begin
                r_exp = {{(`NE-1){1'b1}}, 1'b0};
                r_fract = {`NF{1'b1}};
            end
            default: begin
                r_exp = m_exp[`NE-1:0];
                r_fract = m_fract;
            end
        endcase
    end

    assign r_sign = m_sign;
    // assign r_exp = m_exp[`NE-1:0];
    // assign r_fract = m_fract;
endmodule