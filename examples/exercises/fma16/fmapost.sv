///////////////////////////////////////////
// fmapost
//
// Written: Kavi Dey kdey@hmc.edu
// Created: Feb 8, 2025
//
// Purpose: Postprocessing logic for fused floating point multiply accumulate
///////////////////////////////////////////

`include "fma.vh"

module fmapost (
    input  logic             mul, add,                             // Skip adding or multiplying
    input  logic             x_zero, y_zero, z_zero,               // Inputs are zero
    input  logic             x_inf, y_inf, z_inf,                  // Inputs are infinity
    input  logic             x_nan, y_nan, z_nan,                  // Inputs are NaN
    input  logic             x_snan, y_snan, z_snan,               // Inputs are signalling NaN
    input  logic             x_sign, y_sign, z_sign,               // Sign of inputs
    input  logic             kill_z, kill_prod,                    // Kill addend or product
    input  logic             a_sticky,                             // Sticky bits from killing addend/product or throwing away bits
    input  logic             p_sign, a_sign, r_sign,               // Sign of product, addend, and rounded result
    input  logic             diff_sign,                            // Product and sum have different signs
    input  logic             round_overflow,                       // Overflow occurred during the rounding process
    input  logic             m_zero,                               // Output was zero
    input  logic [4:0]       round_flags,                          // Bits used to determine rounding mode (sign, overflow, lsb, guard, sticky)
    input  logic [`NE-1:0]   r_exp,                                // Rounded exponent
    input  logic [`NF-1:0]   r_fract,                              // Rounded mantissa
    output logic [`FLEN-1:0] result,                               // Output result
    output logic             invalid, overflow, underflow, inexact // Output flags
);
    logic nan, snan, zero_mul_inf, nan_mul_inf, sub_inf, p_inf;
    // Any inputs are NaN
    assign nan = x_nan | (y_nan & mul) | (z_nan & add);
    // Any inputs are signalling NaN
    assign snan = x_snan | (y_snan & mul) | (z_snan & add);
    // Product is infinity
    assign p_inf = x_inf | (y_inf & mul);

    // Effective zero times infinity
    assign zero_mul_inf = (x_zero & (y_inf & mul)) | ((y_zero & mul) & x_inf);
    // Effective nan times infinity
    assign nan_mul_inf = (x_nan & (y_inf & mul)) | ((y_nan & mul) & x_inf);
    // Effective subtraction of infinities
    assign sub_inf = (p_inf & (z_inf & add) & diff_sign);

    // check for invalid combinations
    // if there was an invalid combination than kill the other flags
    logic kill_flags;
    always_comb begin
        if (nan | zero_mul_inf) begin
            // any inputs are nan OR (0 * inf)
            result = {1'b0, {`NE{1'b1}}, 1'b1, {(`NF-1){1'b0}}}; // nan
            kill_flags = 1;
        end
        else if (p_inf & (~(z_inf & add))) begin
            // x or y are inf but not z
            result = {p_sign, {`NE{1'b1}}, {`NF{1'b0}}}; // inf with sign of x*y
            kill_flags = 1;
        end
        else if (~p_inf & (z_inf & add)) begin
            // z is inf but not x and y
            result = {a_sign, {`NE{1'b1}}, {`NF{1'b0}}}; // inf with sign of z
            kill_flags = 1;
        end
        else if (sub_inf) begin
            // effective subtraction of infs
            result = {1'b0, {`NE{1'b1}}, 1'b1, {(`NF-1){1'b0}}}; // nan
            kill_flags = 1;
        end
        else if (p_inf & (z_inf & add) & (~diff_sign)) begin
            // effective addition of inf
            result = {a_sign, {`NE{1'b1}}, {`NF{1'b0}}}; // inf with sign of z
            kill_flags = 1;
        end
        else begin
            result = {r_sign, r_exp, r_fract};
            kill_flags = 0;
        end
    end
    
    // invalid if there are any signalling nans, or zero times infinity, or subtraction of infinities (and not nan)
    assign invalid = (x_snan | (y_snan & mul) | (z_snan & add)) | zero_mul_inf | (sub_inf & (~(x_nan | (y_nan & mul))));
    assign overflow = round_overflow & (~(invalid | kill_flags));
    // assign underflow = m_zero & inexact;
    assign underflow = 0;
    // inexact if overflow or sticky or guard bits
    assign inexact = (overflow | (|round_flags[1:0])) & (~(invalid | kill_flags));
endmodule
