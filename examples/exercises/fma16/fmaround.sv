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
    input  logic             m_sign,
    input  logic [`NF-1:0]   m_fract,
    input  logic [`NE+1:0]   m_exp,
    input  logic [4*`NF+5:0] m_shifted,
    output logic             r_sign,
    output logic [`NE-1:0]   r_exp,
    output logic [`NF-1:0]   r_fract
);
    ///// 8. Round the result and handle special cases: R = round(M) /////
    logic [6:0] round_flags; // sign_overflow_L_G_sticky_roundmode
    assign round_flags = {m_sign, 1'b0, m_fract[0], m_shifted[2*`NF+1], |m_shifted[2*`NF:0], roundmode};
    logic [2:0] round_op;
    // 0: TRUNC, 1: RND, 2: +inf, 3: -inf, 4: +MAXNUM, 5: -MAXNUM
    always_comb begin
        casez (round_flags)
            7'b0_0_?_0_0_??: round_op = 0;
            7'b0_0_?_0_1_??: round_op = 0;
            7'b0_0_0_1_0_??: round_op = 0;
            default: round_op = 0;
        endcase
    end

    assign r_sign = m_sign;
    assign r_exp = m_exp[`NE-1:0];
    assign r_fract = m_fract;
endmodule