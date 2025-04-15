localparam TEST_MUL = 1;
localparam TEST_ADD = 1;
localparam TEST_FMA = 1;
localparam TEST_SPECIAL = 1;

string mul_tests[] = {
    "fmul_0.tv",
    "fmul_1.tv",
    "fmul_2.tv"
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

string special_tests[] = {
    // "fma_special_rn.tv",
    // "fma_special_rne.tv",
    // "fma_special_rp.tv",
    "fma_special_rz.tv"
};