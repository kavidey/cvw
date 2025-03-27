///////////////////////////////////////////
// unpack float
//
// Written: Kavi Dey kdey@hmc.edu
// Created: Mar 25, 2025
//
// Purpose: Unpack IEEE-754 floating point number
///////////////////////////////////////////

module unpackfloat(
    input  logic [15:0] f,
    output logic sign,
    output logic [4:0] exp,
    output logic [9:0] fract,
    output logic zero, inf, nan, snan
);
    assign {sign, exp, fract} = f;

    logic exp_nonzero, fract_zero, max_exponent;
    assign exp_nonzero = |exp;
    assign fract_zero = &fract;
    assign max_exponent = &exp; // exp == 5'b11111;

    assign zero = (~exp_nonzero) & fract_zero;
    assign inf = max_exponent & fract_zero;
    assign nan = max_exponent & (~fract_zero);
    assign snan = nan & (~fract[9]);
endmodule