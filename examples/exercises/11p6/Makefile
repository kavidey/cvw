TARGET = 11p6

$(TARGET).objdump: $(TARGET)
	riscv64-unknown-elf-objdump -D $(TARGET).elf > $(TARGET).objdump
    
$(TARGET): $(TARGET).S Makefile
	riscv64-unknown-elf-gcc -g -o $(TARGET).elf -march=rv32gc -mabi=ilp32 -mcmodel=medany \
	    -nostartfiles -T../../link/link.ld $(TARGET).S

sim:
	riscv_sim_rv32d --pmp-count=16 11p6.elf > log

clean:
	rm -f $(TARGET).elf $(TARGET).objdump $(TARGET).signature.output