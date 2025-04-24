///////////////////////////////////////////
// fmamul
//
// Written: Kavi Dey kdey@hmc.edu
// Created: Feb 8, 2025
//
// Purpose: Add logic for fused floating point multiply accumulate
///////////////////////////////////////////

`include "fma.vh"

module fmaadd (
    input  logic             negz, x_zero, y_zero, z_zero,
    input  logic             z_sign, p_sign,
    input  logic [`NE-1:0]   z_exp,
    input  logic [`NF-1:0]   z_fract,
    input  logic [2*`NF+1:0] p_fract,
    input  logic [`NE+1:0]   p_exp,
    output logic             m_sign,
    output logic [`NF-1:0]   m_fract,
    output logic [`NE+1:0]   m_exp,
    output logic [4*`NF+5:0] m_shifted,
    output logic             kill_z, kill_prod, a_sign, diff_sign, a_sticky
);
    ///// 3. Determine the alignment shift count: A_cnt = P_e - Z_e /////
    logic signed [`NE+1:0] a_cnt;
    assign a_cnt = p_exp - {1'b0, z_exp} + `NF + 2;
    assign kill_z = (a_cnt > (3*`NF + 3)) | z_zero;
    assign kill_prod = (a_cnt < 0) | x_zero | y_zero;

    ///// 4. Shift the significand of Z into alignment: A_m = Z_m >> A_cnt /////
    logic [`NF+2:0] z_preshift;
    assign z_preshift = {1'b1, z_fract, 2'b00}; // preshift left by NF+2

    logic [4*`NF+3:0] z_shifted;
    always_comb begin
        if (kill_prod)
            z_shifted = {{`NF+2{1'b0}}, 1'b1, z_fract, {2*`NF+1{1'b0}}};
        else if (kill_z)
            z_shifted = 0;
        else
            z_shifted = {z_preshift, {(3*`NF+1){1'b0}}} >> a_cnt;
    end

    logic [3*`NF+2:0] a_fract;
    assign a_fract = z_shifted[4*`NF+3:`NF+1];

    always_comb begin
        if (kill_prod)
            a_sticky = ~(x_zero | y_zero);
        else if (kill_z)
            a_sticky = ~z_zero;
        else
            a_sticky = |z_shifted[`NF-1:0];
    end

    ///// 5. Add the aligned significands: S_m = P_m + A_m /////
    assign a_sign = z_sign ^ negz;
    assign diff_sign = a_sign ^ p_sign; // 1 means they have different signs and we're doing effective subtraction

    logic [3*`NF+2:0] aligned_p_fract;
    assign aligned_p_fract = ~kill_prod ? {{`NF+1{1'b0}}, p_fract} : 0;

    logic [3*`NF+3:0] pre_sum, neg_pre_sum;
    assign pre_sum = a_fract + (diff_sign ? (~{1'b0, aligned_p_fract} + {{3*`NF+2{1'b0}}, (~a_sticky)|~kill_prod}) : {1'b0, aligned_p_fract});
    assign neg_pre_sum = aligned_p_fract + ~{1'b0, a_fract} + {{3*`NF+2{1'b0}}, (~a_sticky)|(kill_prod)};

    logic pos_sum;
    assign pos_sum = pre_sum[3*`NF+3]; // pos_sum is 0 if pre_sum > 0 and 1 if neg_pre_sum > 0

    logic s_fract_zero;
    logic [3*`NF+3:0] s_fract;
    assign s_fract = pos_sum ? neg_pre_sum : pre_sum;
    assign s_fract_zero = (s_fract==0); // the sum cancelled perfectly to 0

    logic s_sign;
    assign s_sign = diff_sign ? a_sign ^ pos_sum : a_sign;
    assign m_sign = s_fract_zero ? 0 : s_sign; // if the sum cancelled out to 0 then we need to set the sign to positive

    ///// 6. Find the leading 1 for normalization shift: Mcnt = # of bits to shift /////
    localparam SHIFT_WIDTH = $clog2(3*`NF+4);
    logic [SHIFT_WIDTH-1:0] lzero, m_cnt;
    priorityencoder #(.N(3*`NF+4)) priorityencoder(.A(s_fract), .Y(lzero));
    assign m_cnt = (2*`NF) - lzero;

    ///// 7. Shift the result to renormalize: Mm = Sm << Mcnt; Me = Pe - Mcnt /////
    assign m_shifted = {{`NF+2{1'b0}}, s_fract} << (`NF + 2 + $signed(m_cnt));
    assign m_fract = m_shifted[3*`NF+1:2*`NF+2];

    always_comb begin
        if (s_fract_zero)
            m_exp = 0;
        else 
            m_exp = kill_prod ? ({1'b0, z_exp} - {m_cnt[SHIFT_WIDTH-1], m_cnt}) : (p_exp - {m_cnt[SHIFT_WIDTH-1], m_cnt});
    end
endmodule