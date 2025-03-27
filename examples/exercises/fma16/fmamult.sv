///////////////////////////////////////////
// fmamult
//
// Written: Kavi Dey kdey@hmc.edu
// Created: Feb 8, 2025
//
// Purpose: Half precision multiply unit used by fma16
///////////////////////////////////////////

module fmamult(
    input  logic [15:0] x,
    input  logic [15:0] y,
    output logic [15:0] a,
    output logic        MInvalid, MOverflow, MUnderflow, MInexact
);
    logic x_sign, y_sign, a_sign;
    logic [4:0] x_exp, y_exp, a_exp;
    logic [9:0] x_fract, y_fract, a_fract;

    logic x_zero, x_inf, x_nan, x_snan;
    unpackfloat unpackX(.f(x), .sign(x_sign), .exp(x_exp), .fract(x_fract), .zero(x_zero), .inf(x_inf), .nan(x_nan), .snan(x_snan));

    logic y_zero, y_inf, y_nan, y_snan;
    unpackfloat unpackY(.f(y), .sign(y_sign), .exp(y_exp), .fract(y_fract), .zero(y_zero), .inf(y_inf), .nan(y_nan), .snan(y_snan));

    // calculate sign bit
    assign a_sign = x_sign ^ y_sign;

    // calculate fract multiplication
    // 1.x_fract * 1.y_fract = AA.BBBBBBBBBBBBBBBBBBBB [2].[20]
    logic [21:0] mul_result;
    assign mul_result = ({1'b1, x_fract} * {1'b1, y_fract});

    // if the highest bit of mul_result is 1 then there was an overflow
    logic mul_overflow;
    assign mul_overflow = mul_result[21];

    logic [20:0] mul_shifted;
    assign mul_shifted = mul_overflow ? mul_result[20:0] : {mul_result[19:0], 1'b0};

    // assign a_fract to the correct set of bits from mul_result based on overflow
    assign a_fract = mul_shifted[20:11];

    // assign a_exp including mul_overflow and bias compensation
    logic [5:0] add_result;
    assign add_result = (x_exp + y_exp) - 5'd15 + {{4{1'b0}}, mul_overflow};
    assign a_exp = add_result[4:0];

    assign a = {a_sign, a_exp, a_fract};

    // flags
    assign MInvalid = (x_snan | y_snan) | (x_zero & y_inf) | (x_inf & y_zero);
    assign MOverflow = add_result[5];
    assign MUnderflow = 0;
    assign MInexact = |mul_shifted[10:0] | MOverflow;
endmodule