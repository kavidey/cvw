// trap.S
// David_Harris@hmc.edu 11 May 2022
//
// Demonstrates setting up traps and invoking a trap handler.
// The trap handler accepts timer interrupts and ecalls.
// Saves cause and mtval into the signature
// Ecall takes one argument in a0
//   0: change privilege mode to user
//   1: change privilege mode to supervisor
//   3: change privilege mode to machine
//   4: exit program with write tohost

.EQU MTIME,    0x200bff8
.EQU MTIMECMP, 0x2004000

.global rvtest_entry_point

rvtest_entry_point:
    la sp, topofstack   # Initialize stack pointer (not used)
    la s6, begin_signature  # s6 points to signature

    # Set up interrupts
    la t0, trap_handler
    csrw mtvec, t0      # Initialize MTVEC to trap_handler
    csrw mideleg, zero  # Don't delegate interrupts
    csrw medeleg, zero  # Don't delegate exceptions
    la t0, topoftrapstack 
    csrw mscratch, t0   # MSCRATCH holds trap stack pointer
    csrsi mstatus, 0x8  # Turn on mstatus.MIE global interrupt enable

main:
    # Change to user mode
    li a0, 0            # a0 = 0: argument to enter user mode
    ecall               # System call to enter user mode

    li t0, 7
    li t1, 9
    mul t2, t0, t1

done:
    li a0, 4            # argument to finish program    
    ecall               # system call to finish program
    j self_loop         # wait forever (not taken)

.align 4                # trap handlers must be aligned to multiple of 4
trap_handler:
    # Load trap handler stack pointer tp
    csrrw tp, mscratch, tp  # swap MSCRATCH and tp
    sw t0, 0(tp)        # Save t0 and t1 on the stack
    sw t1, -4(tp)
    csrr t0, mcause     # Check the cause
    csrr t1, mtval      # And the trap value
    sw t0, 0(s6)        # Save MCAUSE and MTVAL in the signature
    sw t1, 4(s6)            
    addi s6, s6, 8     
    bgez t0, exception  # if msb is clear, it is an exception

exception:
    csrr t1, mepc   # add 4 to MEPC to determine return Address
    addi t1, t1, 4
    csrw mepc, t1
    li t1, 2
    beq t0, t1, illegal_instruction
    li t1, 8            # is it an ecall trap?
    andi t0, t0, 0xFC # if CAUSE = 8, 9, or 11
    bne t0, t1, trap_return # ignore other exceptions

ecall:
    li t0, 4
    beq a0, t0, write_tohost    # call 4: terminate program
    bltu a0, t0, changeprivilege    # calls 0-3: change privilege level
    j trap_return       # ignore other ecalls

changeprivilege:
    li t0, 0x00001800   # mask off mstatus.MPP in bits 11-12
    csrc mstatus, t0
    andi a0, a0, 0x003  # only keep bottom two bits of argument
    slli a0, a0, 11     # move into mstatus.MPP position
    csrs mstatus, a0    # set mstatus.MPP with desired privilege

trap_return:            # return from trap handler
    lw t1, -4(tp)       # restore t1 and t0
    lw t0, 0(tp)
    csrrw tp, mscratch, tp  # restore tp
    mret                # return from trap

illegal_instruction:
    csrr t0, mtval
    # sw t0, 0(s6)
    j trap_return
    

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

.EQU XLEN,64
begin_signature:
    .fill 6*(XLEN/32),4,0xdeadbeef    # 
end_signature:

# Initialize stack with room for 512 bytes
.bss
    .space 512
topofstack:
# And another stack for the trap handler
.bss   
    .space 512
topoftrapstack:

