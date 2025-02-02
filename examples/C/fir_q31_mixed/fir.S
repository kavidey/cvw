// fir.s
// kdey@hmc.edu 31 January 2025
// Calculates result of applying FIR filter to input

# a0 x[], a1 c[], a2 y[], a3 n, a4 m

.global fir
fir:
    ### setup ###
    addi sp, sp, -8 # room on stack
    sw s0, 0(sp) # save s0
    sw s1, 4(sp) # save s1

    ### outer for loop ###
    # a3 stores threshold for outer for loop
    sub a3, a3, a4 # a3 = n - m
    # multiply indices by 4 to help with array indexing
    slli a3, a3, 2
    slli a4, a4, 2
    # addi a3, a3, 1 # a3 += 1; don't add 1 because we are doing a greater than or equal comparison
    # initialize j = 0
    add s0, a2, zero
    # x_index = j - i + (m-1) => x_index = j + (m-1) and subtract 1 each loop iteration
    andi t5, zero, 0
    addi t5, a4, -4 # x_index = m-1
    sub t5, t5, a2 # subtract &y from x_index in preparation for adding it later when we add j to x_index
    # add array index base addresses to loop comparison
    # m = m + &c
    add a4, a4, a1
    # a3 = a3 + &y
    add a3, a3, a2
outer_for:
    bgt s0, a3, done # if j > (n-m) done
    andi t0, zero, 0 # y[j] = 0
    add t1, t5, s0 # t1 = t5 + a4 => t5 = j + (m-1)
    ### inner for loop ###
    # i = 0
    add s1, a1, zero
inner_for:
    bge s1, a4, outer_for_end # if i >= m done
    # load c[i] into t2
    lw t2, 0(s1) # t2 = c[i]
    # load x[x_index] into t3
    add t3, t1, a0 # t3 = &x[x_index]
    lw t3, 0(t3) # t3 = x[x_index]
    # mul_q31 t2 t3
    mul t4, t2, t3 # t4 = c[i] * x[x_index]
    srli t4, t4, 31 # t4 >> 31 (not 32 because we're not shifting left by 1)
    # add_q31 t0 t4
    add t0, t0, t4 # y[i] = y[i] + t4
    # finish loop
    addi t1, t1, -4 # x_index =- 1
    addi s1, s1, 4 # i++
    j inner_for
    ### inner for loop done ###
outer_for_end:
    # save t1 in y[i]
    sw t0, 0(s0)
    # reset i index
    # finish loop
    addi s0, s0, 4 # j++
    j outer_for # go back to top of loop
    ### outer for loop done ###
done:
    lw s1, 4(sp) # restore s1
    lw s0, 0(sp) # restore s0
    addi sp, sp, 8 # restore stack
    ret                 # return from function
