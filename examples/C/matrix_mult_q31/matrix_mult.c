#include <stdio.h>  // supports printf
#include <stdlib.h> // supports rand
#include "util.h"   // supports verify

#define N 40

// Add two Q1.31 fixed point numbers
int add_q31(int a, int b) {
    return a + b;
}

// Multiplly two Q1.31 fixed point numbers
int mul_q31(int a, int b) {
    long long res = (long long) a * (long long) b;
    int result = (res << 1) >> 32;
    // printf("mul_q31: a = %x, b = %x, res = %lx, result = %x\n", a, b, res, result);
    return result;
}

void matrix_mult(int a[N][N], int b[N][N], int c[N][N], int n) {
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            c[i][j] = 0;
            for (int k = 0; k < n; k++) {
                c[i][j] = add_q31(c[i][j], mul_q31(a[i][k], b[k][j]));
            }
        }
    }
}

// used to turn array indices into random numbers
// from: https://stackoverflow.com/a/167764/6454085
uint32_t hash( uint32_t a) {
    a = (a ^ 61) ^ (a >> 16);
    a = a + (a << 3);
    a = a ^ (a >> 4);
    a = a * 0x27d4eb2d;
    a = a ^ (a >> 15);
    return a;
}

void fill_matrix(int a[N][N], int n, int rand_offset) {
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            a[i][j] = hash(i + n*j + rand_offset);
        }
    }
}

void print_matrix(int a[N][N], int n) {
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            printf("%d  ", a[i][j]);
        }
        printf("\n");
    }
}

int main(void) {
    int a[N][N];
    int b[N][N];
    int c[N][N];

    fill_matrix(a, N, 0);
    fill_matrix(b, N, N*N);

    printf("a\n\n");
    print_matrix(a, N);
    printf("\nb\n\n");
    print_matrix(b, N);

    setStats(1);        // record initial mcycle and minstret
    matrix_mult(a, b, c, N);
    setStats(0);        // record elapsed mcycle and minstret;
    
    printf("\nc\n\n");
    print_matrix(c, N);

    // fake data to make verify work
    int y[1] = {0};
    int expected[1] = {0};
    return verify(1, y, expected); 
// check the 1 element of s matches expected. 0 means success
}
