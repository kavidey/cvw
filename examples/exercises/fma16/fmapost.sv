///////////////////////////////////////////
// fmamul
//
// Written: Kavi Dey kdey@hmc.edu
// Created: Feb 8, 2025
//
// Purpose: Postprocessing logic for fused floating point multiply accumulate
///////////////////////////////////////////

`include "fma.vh"

module fmapost (
    input  logic             x_zero, y_zero, z_zero,
    input  logic             x_inf, y_inf, z_inf,
    input  logic             x_nan, y_nan, z_nan,
    input  logic             x_snan, y_snan, z_snan,
    input  logic             x_sign, y_sign, z_sign,
    input  logic             kill_z, kill_prod, a_sticky,
    input  logic             p_sign, a_sign, diff_sign, m_sign, r_sign,
    input  logic             round_overflow,
    input  logic [4:0]       round_flags,
    input  logic [`NE+1:0]   m_exp,
    input  logic [`NE-1:0]   r_exp,
    input  logic [`NF-1:0]   r_fract,
    output logic [`FLEN-1:0] result,
    output logic             invalid, overflow, underflow, inexact
);
    logic nan, snan, zero_mul_inf, nan_mul_inf, sub_inf, p_inf;
    assign nan = x_nan | y_nan | z_nan; // anything is nan
    assign snan = x_snan | y_snan | z_snan; // anything is a signalling nan
    assign p_inf = x_inf | y_inf; // product is infinitiy

    assign zero_mul_inf = (x_zero & y_inf) | (y_zero & x_inf);
    assign nan_mul_inf = (x_nan & y_inf) | (y_nan & x_inf);
    assign sub_inf = (p_inf & z_inf & diff_sign);

    logic kill_flags;
    always_comb begin
        if (nan | zero_mul_inf) begin // any inputs are nan OR (0 * inf)
            result = {1'b0, {`NE{1'b1}}, 1'b1, {(`NF-1){1'b0}}}; // nan
            kill_flags = 1;
        end
        else if (p_inf & (~z_inf)) begin// x or y are inf but not z
            result = {p_sign, {`NE{1'b1}}, {`NF{1'b0}}}; // inf with sign of x*y
            kill_flags = 1;
        end
        else if (~p_inf & z_inf) begin // z is inf but not x and y
            result = {a_sign, {`NE{1'b1}}, {`NF{1'b0}}}; // inf with sign of z
            kill_flags = 1;
        end
        else if (sub_inf) begin // effective subtraction of inf
            result = {1'b0, {`NE{1'b1}}, 1'b1, {(`NF-1){1'b0}}}; // nan
            kill_flags = 1;
        end
        else if (p_inf & z_inf & (~diff_sign)) begin // effective addition of inf
            result = {a_sign, {`NE{1'b1}}, {`NF{1'b0}}}; // inf with sign of z
            kill_flags = 1;
        end
        else begin
            result = {r_sign, r_exp, r_fract};
            kill_flags = 0;
        end
    end
    
    assign invalid = (x_snan | y_snan | z_snan) | zero_mul_inf | (sub_inf & (~(x_nan | y_nan))); // todo improve logic
    assign overflow = round_overflow & (~(invalid | kill_flags));
    assign underflow = 0;
    assign inexact = (a_sticky | overflow | (|round_flags[1:0])) & (~(invalid | kill_flags));
endmodule
