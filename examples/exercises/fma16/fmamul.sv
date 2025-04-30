///////////////////////////////////////////
// fmamul
//
// Written: Kavi Dey kdey@hmc.edu
// Created: Feb 8, 2025
//
// Purpose: Multiply logic for fused floating point multiply accumulate
///////////////////////////////////////////

`include "fma.vh"

module fmamul (
    input  logic             mul,              // Whether to multiply
    input  logic             negp,             // Invert the sign of the product
    input  logic             x_zero, y_zero,   // X and Y are zero
    input  logic             x_sign, y_sign,   // X and Y sign
    input  logic [`NE-1:0]   x_exp, y_exp,     // X and Y exponent
    input  logic [`NF-1:0]   x_fract, y_fract, // X and Y mantissa
    output logic             p_sign,           // Product sign
    output logic [`NE+1:0]   p_exp             // Product exponent
    output logic [2*`NF+1:0] p_fract,          // Product mantissa
);
    // if mul is 0 then set y=1
    logic y_sign_mul;
    logic [`NE-1:0] y_exp_mul;
    logic [`NF-1:0] y_fract_mul;
    assign y_sign_mul = mul ? y_sign: 0;
    assign y_exp_mul = mul ? y_exp: {1'b0, {(`NE-1){1'b1}}};
    assign y_fract_mul = mul ? y_fract : 0;

    ///// 1. Multiply the significands of X and Y: P_m = X_m + Y_m /////
    // calculate sign bit
    assign p_sign = x_sign ^ y_sign_mul ^ negp;

    // 1.x_fract * 1.y_fract = AA.BBBBBBBBBBBBBBBBBBBB [2].[20] (half precision)
    assign p_fract = ({1'b1, x_fract} * {1'b1, y_fract_mul});

    ///// 2. Add the exponents of X and Y: P_e = X_e + Y_e - bias /////
    // set exponent to zero if either inputs are zero
    assign p_exp = (x_zero | (y_zero & mul)) ? 0 : ({1'b0, x_exp} + {1'b0, y_exp_mul} - `BIAS);
endmodule