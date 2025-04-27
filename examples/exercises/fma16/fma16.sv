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
    input  logic             mul,
    input  logic             add,
    input  logic             negp,
    input  logic             negz,
    input  logic [1:0]       roundmode,
    output logic [`FLEN-1:0] result,
    output logic [3:0]       flags
);
    logic x_sign, y_sign, z_sign;
    logic [`NE-1:0] x_exp, y_exp, z_exp;
    logic [`NF-1:0] x_fract, y_fract, z_fract;

    logic x_zero, x_inf, x_nan, x_snan;
    unpackfloat unpackX(.f(x), .sign(x_sign), .exp(x_exp), .fract(x_fract), .zero(x_zero), .inf(x_inf), .nan(x_nan), .snan(x_snan));

    logic y_zero, y_inf, y_nan, y_snan;
    unpackfloat unpackY(.f(y), .sign(y_sign), .exp(y_exp), .fract(y_fract), .zero(y_zero), .inf(y_inf), .nan(y_nan), .snan(y_snan));
    
    logic z_zero, z_inf, z_nan, z_snan;
    unpackfloat unpackZ(.f(z), .sign(z_sign), .exp(z_exp), .fract(z_fract), .zero(z_zero), .inf(z_inf), .nan(z_nan), .snan(z_snan));


    ///// 1. Multiply the significands of X and Y: P_m = X_m + Y_m /////
    ///// 2. Add the exponents of X and Y: P_e = X_e + Y_e - bias /////
    logic p_sign;
    logic [2*`NF+1:0] p_fract;
    logic [`NE+1:0] p_exp;
    fmamul fmamul(
        // auxiliary inputs
        .mul, .negp, .x_zero, .y_zero,
        // multiplicand inputs
        .x_sign, .x_exp, .x_fract,
        .y_sign, .y_exp, .y_fract,
        // product output
        .p_sign, .p_fract, .p_exp
    );

    ///// 3. Determine the alignment shift count: A_cnt = P_e - Z_e /////
    ///// 4. Shift the significand of Z into alignment: A_m = Z_m >> A_cnt /////
    ///// 5. Add the aligned significands: S_m = P_m + A_m /////
    ///// 6. Find the leading 1 for normalization shift: Mcnt = # of bits to shift /////
    ///// 7. Shift the result to renormalize: Mm = Sm << Mcnt; Me = Pe - Mcnt /////
    logic m_sign;
    logic [`NF-1:0] m_fract;
    logic [`NE+1:0] m_exp;
    logic [4*`NF+5:0] m_shifted;
    logic kill_z, kill_prod, a_sign, diff_sign, a_sticky;
    fmaadd fmaadd(
        // auxiliary inputs
        .mul, .add, .negz, .x_zero, .y_zero, .z_zero,
        // addend inputs
        .z_sign, .z_exp, .z_fract,
        .p_sign, .p_exp, .p_fract,
        // sum output
        .m_sign, .m_exp, .m_fract, .m_shifted,
        // auxiliary outputs
        .kill_z, .kill_prod, .a_sign, .diff_sign, .a_sticky
    );

    ///// 8. Round the result and handle special cases: R = round(M) /////
    logic round_overflow;
    logic [4:0] round_flags;
    logic r_sign;
    logic [`NE-1:0] r_exp;
    logic [`NF-1:0] r_fract;
    fmaround fmaround (
        .roundmode,
        // auxiliary inputs
        .kill_prod, .kill_z, .diff_sign, .a_sticky,
        // sum input
        .m_sign, .m_exp, .m_fract, .m_shifted,
        // rounded output
        .r_sign, .r_exp, .r_fract,
        // auxiliary outputs
        .round_overflow, .round_flags
    );

    ///// 9. Handle flags and special cases: W = specialcase(R, X, Y, Z) /////
    logic invalid, overflow, underflow, inexact;
    fmapost fmapost(
        // inputs
        .x_zero, .y_zero, .z_zero,
        .x_inf, .y_inf, .z_inf,
        .x_nan, .y_nan, .z_nan,
        .x_snan, .y_snan, .z_snan,
        .x_sign, .y_sign, .z_sign,
        .kill_z, .kill_prod, .a_sticky,
        .p_sign, .a_sign, .diff_sign, .m_sign, .r_sign,
        .round_overflow, .round_flags,
        .m_exp,
        .r_exp,
        .r_fract,
        // outputs
        .result,
        .invalid, .overflow, .underflow, .inexact
    );

    assign flags = {invalid, overflow, underflow, inexact};
endmodule