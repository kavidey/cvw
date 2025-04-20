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
    input  logic             negp, x_zero, y_zero,
    input  logic             x_sign, y_sign,
    input  logic [`NE-1:0]   x_exp, y_exp,
    input  logic [`NF-1:0]   x_fract, y_fract,
    output logic             p_sign,
    output logic [2*`NF+1:0] p_fract,
    output logic [`NE+1:0]   p_exp
);
    ///// 1. Multiply the significands of X and Y: P_m = X_m + Y_m /////
    // calculate sign bit
    assign p_sign = x_sign ^ y_sign ^ negp;

    // 1.x_fract * 1.y_fract = AA.BBBBBBBBBBBBBBBBBBBB [2].[20] (half precision)
    assign p_fract = ({1'b1, x_fract} * {1'b1, y_fract});

    ///// 2. Add the exponents of X and Y: P_e = X_e + Y_e - bias /////
    assign p_exp = (x_zero | y_zero) ? 0 : ({1'b0, x_exp} + {1'b0, y_exp} - `BIAS);
endmodule