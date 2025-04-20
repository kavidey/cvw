AES_ENCRYPT_ROUND:
    aes32esmi t0, t0, a0, 0
    aes32esmi t0, t0, a1, 1
    aes32esmi t0, t0, a2, 2
    aes32esmi t0, t0, a3, 3
    aes32esmi t1, t1, a1, 0
    aes32esmi t1, t1, a2, 1
    aes32esmi t1, t1, a3, 2
    aes32esmi t1, t1, a0, 3
    aes32esmi t2, t2, a2, 0
    aes32esmi t2, t2, a3, 1
    aes32esmi t2, t2, a0, 2
    aes32esmi t2, t2, a1, 3
    aes32esmi t3, t3, a3, 0
    aes32esmi t3, t3, a0, 1
    aes32esmi t3, t3, a1, 2
    aes32esmi t3, t3, a2, 3

AES_ENCRYPT_FINAL_ROUND:
    aes32esi t0, t0, a0, 0
    aes32esi t0, t0, a1, 1
    aes32esi t0, t0, a2, 2
    aes32esi t0, t0, a3, 3
    aes32esi t1, t1, a1, 0
    aes32esi t1, t1, a2, 1
    aes32esi t1, t1, a3, 2
    aes32esi t1, t1, a0, 3
    aes32esi t2, t2, a2, 0
    aes32esi t2, t2, a3, 1
    aes32esi t2, t2, a0, 2
    aes32esi t2, t2, a1, 3
    aes32esi t3, t3, a3, 0
    aes32esi t3, t3, a0, 1
    aes32esi t3, t3, a1, 2
    aes32esi t3, t3, a2, 3

// https://github.com/riscv/riscv-crypto/blob/main/benchmarks/aes/zscrypto_rv32/aes_128_ks.S
// https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.197-upd1.pdf