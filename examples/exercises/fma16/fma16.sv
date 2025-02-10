///////////////////////////////////////////
// fma16
//
// Written: Kavi Dey kdey@hmc.edu
// Created: Feb 8, 2025
//
// Purpose: Half precision multiply and accumulate unit
///////////////////////////////////////////

module fma16 (
    input  logic [15:0] x,
    input  logic [15:0] y,
    input  logic [15:0] z,
    input  logic        mul,
    input  logic        add,
    input  logic        negp,
    input  logic        negz,
    input  logic  [1:0] roundmode,
    output logic [15:0] result,
    output logic  [3:0] flags
);
    logic [15:0] a;

    fmamult fmamult(.x, .y, .a);

    fmaadd fmaadd(.a, .z, .w(result));

    assign flags = 4'b0;
endmodule