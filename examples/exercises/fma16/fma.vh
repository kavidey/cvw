/// PRECISION ///

// HALF PRECISION
`define FLEN 16
`define NF 10

// SINGLE PRECISION
// `define FLEN = 32;
// `define NF = 12;

// CALCULATED PARAMETERS
`define NE (`FLEN - `NF - 1)
`define BIAS (2**(`NE-1) - 1)