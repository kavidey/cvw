.section .text.init
.globl rvtest_entry_point

rvtest_entry_point:
    li a0, 0x41700000
    li a1, 0x41500000

fcmp:
    ; {s, e, m} = a0
    ; {s, e, m} = a1
    ; before comparing these numbers as unsigned integers, we need to flip the sign bit
    xori a0, a0, 0x80000000
    xori a1, a1, 0x80000000

    bltu a0, a1, less_than
    bgeu a0, a1, greater_than
    li t0, 0
return:
    mv a0, t0
less_than:
    li t0, -1
    j return
greater_than
    li t0, 1
    j return

self_loop:
    j self_loop
