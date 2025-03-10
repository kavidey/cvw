#include <stdio.h>
 
int main(void) {
    int a = 3;
    int b = 4;
    int c;
    // write inline assembly here to compute c = a + 2*b
    asm volatile("slli %0, %1, 1" : "=r"(c) : "r"(b));
    asm volatile("add %0, %1, %2" : "=r"(c) : "r"(c), "r"(a));
    printf ("expected: c = %d\n", a+2*b);
    printf ("c = %d\n", c);
}