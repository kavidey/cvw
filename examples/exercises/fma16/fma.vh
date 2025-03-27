/// PRECISION ///

// HALF PRECISION
`define WIDTH 16
`define NF 10

// SINGLE PRECISION
// `define WIDTH = 32;
// `define NF = 12;

// CALCULATED PARAMETERS
`define NE (`WIDTH - `NF - 1)
`define BIAS (2**(`NE-1) - 1)