///////////////////////////////////////////
// fma16
//
// Written: Kavi Dey kdey@hmc.edu
// Created: Feb 8, 2025
//
// Purpose: Half precision multiply and accumulate unit
///////////////////////////////////////////

`include "fma.vh"

module fma16 (
    input  logic [`FLEN-1:0] x,
    input  logic [`FLEN-1:0] y,
    input  logic [`FLEN-1:0] z,
    input  logic              mul,
    input  logic              add,
    input  logic              negp,
    input  logic              negz,
    input  logic        [1:0] roundmode,
    output logic [`FLEN-1:0] result,
    output logic        [3:0] flags
);
    logic x_sign, y_sign, z_sign, p_sign;
    logic [`NE-1:0] x_exp, y_exp, z_exp;
    logic [`NF-1:0] x_fract, y_fract, z_fract;

    logic x_zero, x_inf, x_nan, x_snan;
    unpackfloat unpackX(.f(x), .sign(x_sign), .exp(x_exp), .fract(x_fract), .zero(x_zero), .inf(x_inf), .nan(x_nan), .snan(x_snan));

    logic y_zero, y_inf, y_nan, y_snan;
    unpackfloat unpackY(.f(y), .sign(y_sign), .exp(y_exp), .fract(y_fract), .zero(y_zero), .inf(y_inf), .nan(y_nan), .snan(y_snan));
    
    logic z_zero, z_inf, z_nan, z_snan;
    unpackfloat unpackZ(.f(z), .sign(z_sign), .exp(z_exp), .fract(z_fract), .zero(z_zero), .inf(z_inf), .nan(z_nan), .snan(z_snan));

    // calculate sign bit
    assign p_sign = x_sign ^ y_sign ^ negp;

    ///// 1. Multiply the significands of X and Y: P_m = X_m + Y_m /////
    // 1.x_fract * 1.y_fract = AA.BBBBBBBBBBBBBBBBBBBB [2].[20] (half precision)
    logic [2*`NF+1:0] p_fract;
    assign p_fract = ({1'b1, x_fract} * {1'b1, y_fract});

    ///// 2. Add the exponents of X and Y: P_e = X_e + Y_e - bias /////
    logic [`NE:0] p_exp;
    assign p_exp = (x_zero | y_zero) ? 0 : (x_exp + y_exp - `BIAS);

    ///// 3. Determine the alignment shift count: A_cnt = P_e - Z_e /////
    logic signed [`NE+1:0] a_cnt;
    assign a_cnt = {p_exp[`NE], p_exp} - {1'b0, z_exp} + `NF + 2;
    logic kill_z, kill_prod;
    assign kill_z = (a_cnt > (3*`NF + 3)) | z_zero;
    assign kill_prod = (a_cnt < 0) | x_zero | y_zero;

    ///// 4. Shift the significand of Z into alignment: A_m = Z_m >> A_cnt /////
    logic [`NF+2:0] z_preshift;
    assign z_preshift = {1'b1, z_fract, 2'b00}; // preshift left by NF+2

    logic [4*`NF+3:0] z_shifted;
    always_comb begin
        if (kill_prod)
            z_shifted = {{`NF+2{1'b0}}, 1'b1, z_fract, {2*`NF+1{1'b0}}};
        else if (kill_z)
            z_shifted = 0;
        else
            z_shifted = {z_preshift, {(3*`NF+1){1'b0}}} >> a_cnt;
    end

    logic [3*`NF+2:0] a_fract;
    assign a_fract = z_shifted[4*`NF+3:`NF+1];

    logic a_sticky;
    always_comb begin
        if (kill_prod)
            a_sticky = ~(x_zero | y_zero);
        else if (kill_z)
            a_sticky = ~z_zero;
        else
            a_sticky = |z_shifted[`NF-1:0];
    end

    ///// 5. Add the aligned significands: S_m = P_m + A_m /////
    logic a_sign, diff_sign;
    assign a_sign = z_sign ^ negz;
    assign diff_sign = a_sign ^ p_sign;

    logic [3*`NF+2:0] aligned_p_fract;
    assign aligned_p_fract = ~kill_prod ? {{`NF+1{1'b0}}, p_fract} : 0;

    logic [3*`NF+3:0] pre_sum, neg_pre_sum;
    assign pre_sum = a_fract + (diff_sign ? (~{1'b0, aligned_p_fract} + {{3*`NF+2{1'b0}}, (~a_sticky)|~kill_prod}) : {1'b0, aligned_p_fract});
    assign neg_pre_sum = aligned_p_fract + ~{1'b0, a_fract} + {{3*`NF+2{1'b0}}, (~a_sticky)|(kill_prod)};

    logic pos_sum;
    assign pos_sum = pre_sum[3*`NF+3]; // pos_sum is 0 if pre_sum > 0 and 1 if neg_pre_sum > 0

    logic [3*`NF+3:0] s_fract;
    assign s_fract = pos_sum ? neg_pre_sum[3*`NF+3:0] : pre_sum[3*`NF+3:0];

    logic s_sign;
    assign s_sign = diff_sign ? a_sign ^ pos_sum : a_sign;

    ///// 6. Find the leading 1 for normalization shift: Mcnt = # of bits to shift /////
    logic [$clog2(3*`NF+4)-1:0] lzero, m_cnt;
    priorityencoder #(.N(3*`NF+4)) priorityencoder(.A(s_fract), .Y(lzero));
    assign m_cnt = (2*`NF) - lzero;

    ///// 7. Shift the result to renormalize: Mm = Sm << Mcnt; Me = Pe - Mcnt /////
    logic [4*`NF+5:0] m_shifted;
    logic [`NF-1:0] m_fract;
    assign m_shifted = {{`NF+2{1'b0}}, s_fract} << (`NF + 2 + $signed(m_cnt));
    assign m_fract = m_shifted[3*`NF+1:2*`NF+2];

    logic [`NE:0] m_exp;
    assign m_exp = kill_prod ? (z_exp - m_cnt) : (p_exp[`NE-1:0] - m_cnt);
        
    assign result = {s_sign, m_exp[`NE-1:0], m_fract};

    ///// 8. Round the result and handle special cases: R = round(M) /////
    // logic [6:0] round_flags; // sign_overflow_L_G_sticky_roundmode
    // assign round_flags = {s_sign, 0, m_fract[0], m_shifted[2*`NF+1], |m_shifted[2*`NF:0], roundmode}
    // logic [2:0] round_op;
    // // 0: TRUNC, 1: RND, 2: +inf, 3: -inf, 4: +MAXNUM, 5: -MAXNUM
    // always_comb begin
    //     casez (round_flags)
    //         7'b0_0_?_0_0_??: round_op = 0;
    //         7'b0_0_?_0_1_??: round_op = 0;
    //         7'b0_0_0_1_0_??: round_op = 0;
    //         default: 
    //     endcase
    // end

    ///// 9. Handle flags and special cases: W = specialcase(R, X, Y, Z) /////

    logic invalid, overflow, underflow, inexact;
    assign invalid = (x_snan | y_snan) | (x_zero & y_inf) | (x_inf & y_zero);
    // assign MOverflow = add_result[`NE];
    assign overflow = 0;
    assign underflow = 0;
    // assign MInexact = |mul_shifted[`NF:0] | MOverflow;
    // assign MInexact = (|z_shifted[`NF+1:0]) | (|m_shifted[2*`NF+2:0]);
    assign inexact = 0;

    assign flags = {invalid, overflow, underflow, inexact};
endmodule