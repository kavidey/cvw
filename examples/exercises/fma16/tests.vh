///////////////////////////////////////////
// tests.vh
//
// Written: Kavi Dey kdey@hmc.edu
// Created: Feb 8, 2025
//
// Purpose: Test selector file for fma16
///////////////////////////////////////////

localparam TEST_MUL = 1;
localparam TEST_ADD = 1;
localparam TEST_FMA = 1;
localparam TEST_SPECIAL = 1;
localparam TEST_EXTRA = 1;

// localparam TEST_MUL = 1;
// localparam TEST_ADD = 0;
// localparam TEST_FMA = 0;
// localparam TEST_SPECIAL = 0;
// localparam TEST_EXTRA = 0;

string mul_tests[] = {
    "fmul_0.tv"
    // "fmul_1.tv",
    // "fmul_2.tv"
};

string add_tests[] = {
    "fadd_0.tv",
    "fadd_1.tv",
    "fadd_2.tv"
};

string fma_tests[] = {
    "fma_0.tv",
    "fma_1.tv",
    "fma_2.tv"
};

// 48 errors for rm and rp each due to underflow
string special_tests[] = {
    "fma_special_rn.tv",
    "fma_special_rne.tv",
    "fma_special_rp.tv",
    "fma_special_rz.tv"
};

string extra_tests[] = {
    "../work/custom_0.tv",
    "../work/random_rz.tv",
    "../work/random_rne.tv",
    "../work/random_rn.tv",
    "../work/random_rp.tv",
    "../tests/baby_torture.tv"
};