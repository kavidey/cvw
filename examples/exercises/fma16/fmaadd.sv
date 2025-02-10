///////////////////////////////////////////
// fmaadd
//
// Written: Kavi Dey kdey@hmc.edu
// Created: Feb 9, 2025
//
// Purpose: Half precision addition unit used by fma16
///////////////////////////////////////////

module fmaadd(
    input  logic [15:0] a,
    input  logic [15:0] z,
    output logic [15:0] w
);
    logic a_sign, z_sign, w_sign;
    logic [4:0] a_exp, z_exp, w_exp;
    logic [9:0] a_fract, z_fract, w_fract;

    assign {a_sign, a_exp, a_fract} = a;
    assign {z_sign, z_exp, z_fract} = z;

    assign w = {a_sign, a_exp, a_fract};
endmodule