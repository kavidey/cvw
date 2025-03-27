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
    input  logic [`WIDTH-1:0] x,
    input  logic [`WIDTH-1:0] y,
    input  logic [`WIDTH-1:0] z,
    input  logic              mul,
    input  logic              add,
    input  logic              negp,
    input  logic              negz,
    input  logic        [1:0] roundmode,
    output logic [`WIDTH-1:0] result,
    output logic        [3:0] flags
);
    logic [15:0] a;

    logic MInvalid, MOverflow, MUnderflow, MInexact;
    fmamult fmamult(.x, .y, .a, .MInvalid, .MOverflow, .MUnderflow, .MInexact);

    fmaadd fmaadd(.a, .z, .w(result));

    assign flags = {MInvalid, MOverflow, MUnderflow, MInexact};
endmodule