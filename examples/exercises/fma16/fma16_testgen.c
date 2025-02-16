// fma16_testgen.c
// Created by: David_Harris 8 February 2025
// Modified by: Kavi Dey 16 Februrary 2025
// Generate tests for 16-bit FMA
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "softfloat.h"
#include "softfloat_types.h"

typedef union sp {
  float32_t v;
  float f;
} sp;

// lists of tests, terminated with 0x8000
uint16_t easyExponents[] = {15, 0x8000};
uint16_t easyFracts[] = {0, 0x200, 0x8000}; // 1.0 and 1.1

uint16_t medExponents[] = {15, 28, 1, 17, 24, 8, 20, 30, 6, 10, 0x8000};
uint16_t medFracts[] = {0x0, 0xE1, 0x28D, 0x100, 0x3D0, 0x11E, 0x140, 0x3FF, 0x221, 0x15C, 0x160, 0x8000};

uint16_t smlExponents[] = {15, 28, 1, 8, 30, 0x8000};
uint16_t smlFracts[] = {0x0, 0xE1, 0x28D, 0x11E, 0x140, 0x221, 0x8000};

uint16_t specialExponents[] = {0, 31, 15, 20, 7, 1, 0x8000};
uint16_t specialFracts[] = {0x0, 0x200, 0x140, 0x4D, 0x8000};

float16_t custom_x[] = {0x5200, 0x5200, 0x4248, 0x7E01, 0x7C01};
float16_t custom_y[] = {0x3500, 0x3500, 0x3C00, 0x3C00, 0x3C00};
float16_t custom_z[] = {0xCA80, 0x4F00, 0xC247, 0x3C00, 0x3C00};

#define NUM_RAND_TESTS 100000
float16_t random_x[NUM_RAND_TESTS];
float16_t random_y[NUM_RAND_TESTS];
float16_t random_z[NUM_RAND_TESTS];

void softfloatInit(void) {
    softfloat_roundingMode = softfloat_round_minMag; 
    softfloat_exceptionFlags = 0;
    softfloat_detectTininess = softfloat_tininess_beforeRounding;
}

float convFloat(float16_t f16) {
    float32_t f32;
    float res;
    sp r;

    // convert half to float for printing
    f32 = f16_to_f32(f16);
    r.v = f32;
    res = r.f;
    return res;
}

void genCase(FILE *fptr, float16_t x, float16_t y, float16_t z, int mul, int add, int negp, int negz, int roundingMode, int zeroAllowed, int infAllowed, int nanAllowed) {
    float16_t result;
    int op, flagVals;
    char calc[80], flags[80];
    float32_t x32, y32, z32, r32;
    float xf, yf, zf, rf;
    float16_t smallest;

    if (!mul) y.v = 0x3C00; // force y to 1 to avoid multiply
    if (!add) z.v = 0x0000; // force z to 0 to avoid add
    if (negp) x.v ^= 0x8000; // flip sign of x to negate p
    if (negz) z.v ^= 0x8000; // flip sign of z to negate z
    op = roundingMode << 4 | mul<<3 | add<<2 | negp<<1 | negz;
//    printf("op = %02x rm %d mul %d add %d negp %d negz %d\n", op, roundingMode, mul, add, negp, negz);
    softfloat_exceptionFlags = 0; // clear exceptions
    result = f16_mulAdd(x, y, z); // call SoftFloat to compute expected result

    // Extract expected flags from SoftFloat
    sprintf(flags, "NV: %d OF: %d UF: %d NX: %d", 
        (softfloat_exceptionFlags >> 4) % 2,
        (softfloat_exceptionFlags >> 2) % 2,
        (softfloat_exceptionFlags >> 1) % 2,
        (softfloat_exceptionFlags) % 2);
    // pack these four flags into one nibble, discarding DZ flag
    flagVals = softfloat_exceptionFlags & 0x7 | ((softfloat_exceptionFlags >> 1) & 0x8);

    // convert to floats for printing
    xf = convFloat(x);
    yf = convFloat(y);
    zf = convFloat(z);
    rf = convFloat(result);
    if (mul)
        if (add) sprintf(calc, "%f * %f + %f = %f", xf, yf, zf, rf);
        else     sprintf(calc, "%f * %f = %f", xf, yf, rf);
    else         sprintf(calc, "%f + %f = %f", xf, zf, rf);

    // omit denorms, which aren't required for this project
    smallest.v = 0x0400;
    float16_t resultmag = result;
    resultmag.v &= 0x7FFF; // take absolute value
    if (f16_lt(resultmag, smallest) && (resultmag.v != 0x0000)) fprintf (fptr, "// skip denorm: ");
    // if ((softfloat_exceptionFlags) >> 1 % 2) fprintf(fptr, "// skip underflow: ");

    // skip special cases if requested
    if (resultmag.v == 0x0000 && !zeroAllowed) fprintf(fptr, "// skip zero: ");
    if ((resultmag.v == 0x7C00 || resultmag.v == 0x7BFF) && !infAllowed)  fprintf(fptr, "// Skip inf: ");
    if (resultmag.v >  0x7C00 && !nanAllowed)  fprintf(fptr, "// Skip NaN: ");

    // print the test case
    fprintf(fptr, "%04x_%04x_%04x_%02x_%04x_%01x // %s %s\n", x.v, y.v, z.v, op, result.v, flagVals, calc, flags);
}

void prepTests(uint16_t *e, uint16_t *f, char *testName, char *desc, float16_t *cases, 
               FILE *fptr, int *numCases) {
    int i, j;

    // Loop over all of the exponents and fractions, generating and counting all cases
    fprintf(fptr, "%s", desc); fprintf(fptr, "\n");
    *numCases=0;
    for (i=0; e[i] != 0x8000; i++)
        for (j=0; f[j] != 0x8000; j++) {
            cases[*numCases].v = f[j] | e[i]<<10;
            *numCases = *numCases + 1;
        }
}

void genMulTests(uint16_t *e, uint16_t *f, int sgn, char *testName, char *desc, int roundingMode, int zeroAllowed, int infAllowed, int nanAllowed) {
    int i, j, k, numCases;
    float16_t x, y, z;
    float16_t cases[100000];
    FILE *fptr;
    char fn[80];
 
    sprintf(fn, "work/%s.tv", testName);
    if ((fptr = fopen(fn, "w")) == 0) {
        printf("Error opening to write file %s.  Does directory exist?\n", fn);
        exit(1);
    }
    prepTests(e, f, testName, desc, cases, fptr, &numCases);
    z.v = 0x0000;
    for (i=0; i < numCases; i++) { 
        x.v = cases[i].v;
        for (j=0; j<numCases; j++) {
            y.v = cases[j].v;
            for (k=0; k<=sgn; k++) {
                y.v ^= (k<<15);
                genCase(fptr, x, y, z, 1, 0, 0, 0, roundingMode, zeroAllowed, infAllowed, nanAllowed);
            }
        }
    }
    fclose(fptr);
}

void genAddTests(uint16_t *e, uint16_t *f, int sgn, char *testName, char *desc, int roundingMode, int zeroAllowed, int infAllowed, int nanAllowed) {
    int i, j, k, numCases;
    float16_t x, y, z;
    float16_t cases[100000];
    FILE *fptr;
    char fn[80];
 
    sprintf(fn, "work/%s.tv", testName);
    if ((fptr = fopen(fn, "w")) == 0) {
        printf("Error opening to write file %s.  Does directory exist?\n", fn);
        exit(1);
    }
    prepTests(e, f, testName, desc, cases, fptr, &numCases);
    y.v = 0x3c00;
    for (i=0; i < numCases; i++) { 
        x.v = cases[i].v;
        for (j=0; j<numCases; j++) {
            z.v = cases[j].v;
            for (k=0; k<=sgn; k++) {
                z.v ^= (k<<15);
                genCase(fptr, x, y, z, 0, 1, 0, 0, roundingMode, zeroAllowed, infAllowed, nanAllowed);
            }
        }
    }
    fclose(fptr);
}

void genMulAddTests(uint16_t *e, uint16_t *f, int sgn, char *testName, char *desc, int roundingMode, int zeroAllowed, int infAllowed, int nanAllowed) {
    int i, j, k, l, m, n, numCases;
    float16_t x, y, z;
    float16_t cases[100000];
    FILE *fptr;
    char fn[80];
 
    sprintf(fn, "work/%s.tv", testName);
    if ((fptr = fopen(fn, "w")) == 0) {
        printf("Error opening to write file %s.  Does directory exist?\n", fn);
        exit(1);
    }
    prepTests(e, f, testName, desc, cases, fptr, &numCases);
    y.v = 0x3c00;
    for (i=0; i < numCases; i++) { 
        x.v = cases[i].v;
        for (j=0; j<numCases; j++) {
            y.v = cases[j].v;
            for (k=0; k<=numCases; k++) {
                z.v = cases[k].v;
                for (l=0; l<=sgn; l++){
                    x.v ^= (l<<15);
                    for (m=0; m<=sgn; m++){
                        y.v ^= (l<<15);
                        for (n=0; n<=sgn; n++){
                            z.v ^= (n<<15);
                            genCase(fptr, x, y, z, 1, 1, 0, 0, roundingMode, zeroAllowed, infAllowed, nanAllowed);
                        }
                    }
                }
            }
        }
    }
    fclose(fptr);
}

void genCustomTests(float16_t *x, float16_t *y, float16_t *z, int numCases, char *testName, char *desc, int roundingMode) {
    float16_t cases[100000];
    FILE *fptr;
    char fn[80];
 
    sprintf(fn, "work/%s.tv", testName);
    if ((fptr = fopen(fn, "w")) == 0) {
        printf("Error opening to write file %s.  Does directory exist?\n", fn);
        exit(1);
    }
    fprintf(fptr, "%s", desc); fprintf(fptr, "\n");

    int i;
    for (i = 0; i < numCases; i++) { 
        genCase(fptr, x[i], y[i], z[i], 1, 1, 0, 0, roundingMode, 1, 1, 1);
    }
    fclose(fptr);
}

int main()
{
    if (system("mkdir -p work") != 0) exit(1); // create work directory if it doesn't exist
    softfloatInit(); // configure softfloat modes
 
    // Test cases: multiplication
    // Easy
    genMulTests(easyExponents, easyFracts, 0, "fmul_0", "// Multiply with exponent of 0, significand of 1.0 and 1.1, RZ", 0, 0, 0, 0);
    // Medium
    genMulTests(medExponents, medFracts, 0, "fmul_1", "// Multiply with variety of exponents and fractions, no zero, infinity, NaN, or subnorms, RZ", 0, 0, 0, 0);
    // Medium Negative
    genMulTests(medExponents, medFracts, 1, "fmul_2", "// Multiply same as fmul_1 but positive and negative, RZ", 0, 0, 0, 0);

    // Test cases: addition
    // Easy
    genAddTests(easyExponents, easyFracts, 0, "fadd_0", "// Add with exponent of 0, significand of 1.0 and 1.1, RZ", 0, 0, 0, 0);
    // Medium
    genAddTests(medExponents, medFracts, 0, "fadd_1", "// Add with variety of exponents and fractions, no zero, infinity, NaN, or subnorms, RZ", 0, 0, 0, 0);
    // Medium Negative
    genAddTests(medExponents, medFracts, 1, "fadd_2", "// Add same as fmul_1 but positive and negative, RZ", 0, 0, 0, 0);

    // Test cases: multiply-addition
    // Easy
    genMulAddTests(easyExponents, easyFracts, 0, "fma_0", "// Multiply-Add with exponent of 0, significand of 1.0 and 1.1, RZ", 0, 0, 0, 0);
    // Medium
    genMulAddTests(smlExponents, smlFracts, 0, "fma_1", "// Multiply-Add with variety of exponents and fractions, no zero, infinity, NaN, or subnorms, RZ", 0, 0, 0, 0);
    // Medium Negative
    genMulAddTests(smlExponents, smlFracts, 1, "fma_2", "// Multiply-Add same as fma_1 but positive and negative, RZ", 0, 0, 0, 0);

    // Test cases: special multiply-addition
    softfloat_roundingMode = softfloat_round_minMag;
    genMulAddTests(specialExponents, specialFracts, 1, "fma_special_rz", "// Multiply-Add with zero, NaN, and infinity, RZ", 0b00, 1, 1, 1);
    softfloat_roundingMode = softfloat_round_near_even;
    genMulAddTests(specialExponents, specialFracts, 1, "fma_special_rne", "// Multiply-Add with zero, NaN, and infinity, RNE", 0b01, 1, 1, 1);
    softfloat_roundingMode = softfloat_round_max;
    genMulAddTests(specialExponents, specialFracts, 1, "fma_special_rp", "// Multiply-Add with zero, NaN, and infinity, RP", 0b10, 1, 1, 1);
    softfloat_roundingMode = softfloat_round_min;
    genMulAddTests(specialExponents, specialFracts, 1, "fma_special_rn", "// Multiply-Add with zero, NaN, and infinity, RN", 0b11, 1, 1, 1);

    // Test cases: custom special tests
    softfloat_roundingMode = softfloat_round_minMag;
    genCustomTests(custom_x, custom_y, custom_z, sizeof(custom_x)/sizeof(custom_x[0]), "custom_0", "// Manually specified test cases", 0b00);

    // Test cases: random tests
    srand(time(NULL));
    int i, r;
    for (i = 0; i < NUM_RAND_TESTS; i++) {
        r = rand();
        memcpy(&random_x[i], (int16_t*) &r, 2);
        memcpy(&random_y[i], ((int16_t*) &r) + 1, 2);
        r = rand();
        memcpy(&random_z[i], (int16_t*) &r, 2);
    }
    genCustomTests(random_x, random_y, random_z, NUM_RAND_TESTS, "random_0", "// Randomy generated test cases", 0b00);

    return 0;
}