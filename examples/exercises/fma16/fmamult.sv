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
    output logic [15:0] a
);
    logic x_sign, y_sign, a_sign;
    logic [4:0] x_exp, y_exp, a_exp;
    logic [9:0] x_fract, y_fract, a_fract;

    assign {x_sign, x_exp, x_fract} = x;
    assign {y_sign, y_exp, y_fract} = y;

    // calculate sign bit
    assign a_sign = x_sign ^ y_sign;

    // calculate fract multiplication
    // 1.x_fract * 1.y_fract = AA.BBBBBBBBBBBBBBBBBBBB [2].[20]
    logic [21:0] mul_result;
    assign mul_result = ({1'b1, x_fract} * {1'b1, y_fract});

    // if the highest bit of mul_result is 1 then there was an overflow
    logic mul_overflow;
    assign mul_overflow = mul_result[21];

    // assign a_fract to the correct set of bits from mul_result based on overflow
    assign a_fract = mul_overflow ? mul_result[20:11] : mul_result[19:10];

    // assign a_exp including mul_overflow and bias compensation
    logic [5:0] add_result;
    assign add_result = (x_exp + y_exp) - 5'd15 + {{4{1'b0}}, mul_overflow};
    assign a_exp = add_result[4:0];

    assign a = {a_sign, a_exp, a_fract};
endmodule