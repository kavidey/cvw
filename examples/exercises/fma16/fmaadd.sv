///////////////////////////////////////////
// fmaadd
//
// Written: Kavi Dey kdey@hmc.edu
// Created: Feb 8, 2025
//
// Purpose: Add logic for fused floating point multiply accumulate
///////////////////////////////////////////

`include "fma.vh"

module fmaadd (
    input  logic             add, mul,               // Skip adding or multiplying
    input  logic             negz,                   // Invert the sign of Z
    input  logic             x_zero, y_zero, z_zero, // Inputs are zero
    input  logic             z_sign, p_sign,         // Addend's and product's sign
    input  logic [`NE-1:0]   z_exp,                  // Addend's exponent
    input  logic [`NF-1:0]   z_fract,                // Addend's mantissa
    input  logic [`NE+1:0]   p_exp,                  // Product's exponent
    input  logic [2*`NF+1:0] p_fract,                // Product's mantissa
    output logic             m_sign,                 // Sum's sign
    output logic [`NE+1:0]   m_exp,                  // Sum'sj exponent
    output logic [`NF-1:0]   m_fract,                // Sum's mantissa
    output logic [4*`NF+5:0] m_shifted,              // Additional bits of mantissa (for rounding)
    output logic             kill_z, kill_prod,      // Product or addend were killed
    output logic             a_sign,                 // Modified sign of addend
    output logic             diff_sign,              // Product and addend have different signs
    output logic             a_sticky,               // Sticky bit result from killed bits before addition
    output logic             kill_guard              // Whether to kill the guard bit during rounding
);
    // if mul is 0 then set replace Y with floating point representation of 1
    logic z_sign_add;
    logic [`NE-1:0] z_exp_add;
    logic [`NF-1:0] z_fract_add;
    assign z_sign_add = add ? z_sign: 0;
    assign z_exp_add = add ? z_exp: 0;
    assign z_fract_add = add ? z_fract : 0;

    ///// 3. Determine the alignment shift count: A_cnt = P_e - Z_e /////
    logic signed [`NE+1:0] a_cnt;
    assign a_cnt = p_exp - {1'b0, z_exp_add} + `NF + 2;
    assign kill_z = (a_cnt > (3*`NF + 3)) | (z_zero | (~add));
    assign kill_prod = (a_cnt < 0) | x_zero | (y_zero & mul);

    ///// 4. Shift the significand of Z into alignment: A_m = Z_m >> A_cnt /////
    logic [`NF+2:0] z_preshift;
    assign z_preshift = {1'b1, z_fract_add, 2'b00}; // preshift left by NF+2

    logic [4*`NF+3:0] z_shifted;
    always_comb begin
        if (kill_prod)
            // if the product was killed then don't shift z_fract at all
            z_shifted = {{`NF+2{1'b0}}, 1'b1, z_fract_add, {2*`NF+1{1'b0}}};
        else if (kill_z)
            // if z was killed then z_shifted is zero
            z_shifted = 0;
        else
            // if nothing was killed then preshift z_fract left and shift right by a_cnt
            z_shifted = {z_preshift, {(3*`NF+1){1'b0}}} >> a_cnt;
    end

    // Select the bits to add to the product after shifting
    logic [3*`NF+2:0] a_fract;
    assign a_fract = z_shifted[4*`NF+3:`NF+1];

    always_comb begin
        if (kill_prod)
            // if the product was non-zero and killed then sticky bit
            a_sticky = ~(x_zero | (y_zero & mul));
        else if (kill_z)
            // if z was non-zero and killed then sticky bit
            a_sticky = ~(z_zero | (~add));
        else
            // otherwise the sticky bit comes from the part of z that we threw away
            a_sticky = |z_shifted[`NF:0];
    end

    ///// 5. Add the aligned significands: S_m = P_m + A_m /////
    // invert the sign of the addend if negz
    assign a_sign = z_sign_add ^ negz;
    
    // if the product and addend have different signs then we're doing effective subtraction
    assign diff_sign = a_sign ^ p_sign;

    // if product was killed replace it with 0
    logic [3*`NF+2:0] aligned_p_fract;
    assign aligned_p_fract = ~kill_prod ? {{`NF+1{1'b0}}, p_fract} : 0;

    // precompute P +/- A and A - P
    // when we invert for subtraction we need to add 1 because of twos complement
    // but depending on the sticky bit and whether the product is killed sometimes we don't want to add 1
    logic [3*`NF+3:0] pre_sum, neg_pre_sum;
    assign pre_sum = a_fract + (diff_sign ? (~{1'b0, aligned_p_fract} + {{3*`NF+2{1'b0}}, (~a_sticky)|~kill_prod}) : {1'b0, aligned_p_fract});
    assign neg_pre_sum = aligned_p_fract + ~{1'b0, a_fract} + {{3*`NF+2{1'b0}}, (~a_sticky)|(kill_prod)};

    // figure out which sum was positive
    logic pos_sum;
    assign pos_sum = pre_sum[3*`NF+3]; // pos_sum is 0 if pre_sum > 0 and 1 if neg_pre_sum > 0

    // pick the positive sum 
    logic s_fract_zero;
    logic [3*`NF+3:0] s_fract;
    assign s_fract = pos_sum ? neg_pre_sum : pre_sum;
    assign s_fract_zero = (s_fract==0); // the sum cancelled perfectly to 0

    // compute the sign of the sum
    logic s_sign;
    assign s_sign = diff_sign ? a_sign ^ pos_sum : a_sign;

    ///// 6. Find the leading 1 for normalization shift: Mcnt = # of bits to shift /////
    localparam SHIFT_WIDTH = $clog2(3*`NF+4);
    logic [SHIFT_WIDTH-1:0] lzero, m_cnt;
    priorityencoder #(.N(3*`NF+4)) priorityencoder(.A(s_fract), .Y(lzero));
    // the priority encoder is indexed so 0 is the LSB, shift the result to have the correct sign and align with where the decimal is
    assign m_cnt = (2*`NF) - lzero;

    ///// 7. Shift the result to renormalize: Mm = Sm << Mcnt; Me = Pe - Mcnt /////
    // preshift s_fract to the right and then variable shift left to normalize it
    assign m_shifted = {{`NF+2{1'b0}}, s_fract} << (`NF + 2 + $signed(m_cnt));

    // handle the special case where the a_sticky is negative and larger than the sticky bit from m_shifted
    // in this case specifically we want to kill the guard bit and TRUNC instead of RND
    assign kill_guard = (z_fract == 0) & (diff_sign & kill_prod) & ((a_cnt == {(`NE+2){1'b1}}) & p_fract[2*`NF+1]);

    // handle special cases where the inputs and/or outputs are zero
    always_comb begin
        if (kill_prod & kill_z) begin
            // if both inputs were killed then output is zero and sign depends on sticky bits
            m_exp = 0;
            m_fract = 0;

            if (diff_sign & ((|m_shifted[2*`NF+1:0]) | a_sticky))
                m_sign = p_sign;
            else
                m_sign = s_sign;
        end
        else begin
            // calculate the fractional bits of the sum from the list of all fractional bits
            m_fract = m_shifted[3*`NF+1:2*`NF+2];

            if (s_fract_zero) begin
                // if the sum cancelled out then set the sign and exponent to 0
                m_sign = 0;
                m_exp = 0;
            end
            else begin
                // otherwise set the sign and calculate exponent based off normalization shift amount
                m_sign = s_sign;
                m_exp = kill_prod ? ({1'b0, z_exp_add} - {m_cnt[SHIFT_WIDTH-1], m_cnt}) : (p_exp - {m_cnt[SHIFT_WIDTH-1], m_cnt});
            end
        end
    end
endmodule