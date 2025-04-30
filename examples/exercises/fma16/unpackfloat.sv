///////////////////////////////////////////
// unpackfloat
//
// Written: Kavi Dey kdey@hmc.edu
// Created: Mar 25, 2025
//
// Purpose: Unpack IEEE-754 floating point number
///////////////////////////////////////////

`include "fma.vh"

module unpackfloat(
    input  logic [`FLEN-1:0] f,                    // Input float
    output logic              sign,                // Output sign
    output logic [`NE-1:0]    exp,                 // Output exponent
    output logic [`NF-1:0]    fract,               // Output mantissa
    output logic              zero, inf, nan, snan // Output flags
);
    // split up f into sign, exponent, and mantissa
    assign {sign, exp, fract} = f;

    // auxiliary singals used to calculate flags
    logic exp_nonzero, fract_zero, max_exponent;
    assign exp_nonzero = |exp;
    assign fract_zero = fract == 0;
    assign max_exponent = &exp;

    // calculate flags
    assign zero = (~exp_nonzero) & fract_zero;
    assign inf = max_exponent & fract_zero;
    assign nan = max_exponent & (~fract_zero);
    assign snan = nan & (~fract[`NF-1]);
endmodule