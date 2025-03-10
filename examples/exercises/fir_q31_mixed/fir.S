// fir.s
// kdey@hmc.edu 31 January 2025
// Calculates result of applying FIR filter to input

# a0 x[], a1 c[], a2 y[], a3 n, a4 m

.global fir
fir:
    ### outer for loop ###
    # a3 stores threshold for outer for loop
    sub a3, a3, a4 # a3 = n - m
    # multiply indices by 4 to help with array indexing
    slli a3, a3, 2
    slli a4, a4, 2
    # addi a3, a3, 1 # a3 += 1; don't add 1 because we are doing a greater than or equal comparison
    # initialize j = 0
    add t5, a2, zero
    # x_index = j - i + (m-1) => x_index = j + (m-1) and subtract 1 each loop iteration
    addi t4, a4, -4 # x_index = m-1
    sub t4, t4, a2 # subtract &y from x_index in preparation for adding it later when we add j to x_index
    # add array index base addresses to loop comparison
    # m = m + &c
    add a4, a4, a1
    # a3 = a3 + &y
    add a3, a3, a2
outer_for:
    bgt t5, a3, done # if j > (n-m) done
    andi t0, zero, 0 # y[j] = 0
    add t1, t4, t5 # t1 = t4 + a4 => t4 = j + (m-1)
    ### inner for loop ###
    # i = 0
    add t6, a1, zero
inner_for:
    bge t6, a4, outer_for_end # if i >= m done
    # load c[i] into t2
    lw t2, 0(t6) # t2 = c[i]
    # load x[x_index] into t3
    add t3, t1, a0 # t3 = &x[x_index]
    lw t3, 0(t3) # t3 = x[x_index]
    # mul_q31 t2 t3
    mul t2, t2, t3 # t2 = c[i] * x[x_index]
    srli t2, t2, 31 # t2 >> 31 (not 32 because we're not shifting left by 1)
    # add_q31 t0 t2
    add t0, t0, t2 # y[i] = y[i] + t2
    # finish loop
    addi t1, t1, -4 # x_index =- 1
    addi t6, t6, 4 # i++
    j inner_for
    ### inner for loop done ###
outer_for_end:
    # save t1 in y[i]
    sw t0, 0(t5)
    # reset i index
    # finish loop
    addi t5, t5, 4 # j++
    j outer_for # go back to top of loop
    ### outer for loop done ###
done:
    ret                 # return from function
