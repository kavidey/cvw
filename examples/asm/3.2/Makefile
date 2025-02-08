sol.objdump: sol
	riscv64-unknown-elf-objdump -D sol > sol.objdump
    
sol: sol.S Makefile
	riscv64-unknown-elf-gcc -o sol -march=rv32i -mabi=ilp32 -mcmodel=medany \
	    -nostartfiles -T../../link/link.ld  sol.S

clean:
	rm -f sol sol.objdump
