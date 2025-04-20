// aes.S
// kdey@hmc.edu 20 April 2025

.global rvtest_entry_point
rvtest_entry_point:
    la sp, topofstack   # Initialize stack pointer
    

write_tohost:
    la t1, tohost
    li t0, 1            # 1 for success, 3 for failure
    sw t0, 0(t1)        # send success code

self_loop:
    j self_loop         # wait
    
.section .tohost 
tohost:                 # write to HTIF
    .dword 0
fromhost:
    .dword 0

.data
INPUT:
    .fill 1,16,0x3243f6a8885a308d313198a2e0370734
KEY:
    .fill 1,16,0x2b7e151628aed2a6abf7158809cf4f3c

.EQU XLEN,32
begin_signature:
    .fill 4,4,0xdeadbeef    # 
end_signature:

# Initialize stack with room for 512 bytes
.bss
    .space 512
topofstack:
