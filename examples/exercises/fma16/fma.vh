///////////////////////////////////////////
// fma.vh
//
// Written: Kavi Dey kdey@hmc.edu
// Created: Feb 8, 2025
//
// Purpose: configuration for FMA unit
///////////////////////////////////////////

// HALF PRECISION
`define FLEN 16 // floating point bit length
`define NF 10   // fractional bit length

// SINGLE PRECISION
// `define FLEN = 32;
// `define NF = 12;

// CALCULATED PARAMETERS
`define NE (`FLEN - `NF - 1)  // exponent bit length
`define BIAS (2**(`NE-1) - 1) // exponent bias
`define EMAX (2**(`NE) - 2)   // maximum exponent