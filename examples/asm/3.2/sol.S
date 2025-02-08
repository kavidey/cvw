.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
    la a0, numbers
    addi s0, a0, 12

    lw t0, 0(a0)
    addi a0, a0, 4
for:
    bgt a0, s0, self_loop
    lw t1, 0(a0)
    blt t1, t0, end_for
    mv t0, t1
end_for:
    addi a0, a0, 4
    j for
self_loop:
    j self_loop

.data
numbers:
	.word 0x42
    .word 0x37
    .word 0xFD
    .word 0x83
    .word 0x11