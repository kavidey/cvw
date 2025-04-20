TARGET = aestest

$(TARGET).objdump: $(TARGET)
	riscv64-unknown-elf-objdump -D $(TARGET) > $(TARGET).objdump
    
$(TARGET): $(TARGET).S aes.S Makefile
	riscv64-unknown-elf-gcc -g -o $(TARGET) -march=rv32gc_zkne -mabi=ilp32 -mcmodel=medany \
	    -nostartfiles -T../../link/link.ld $(TARGET).S aes.S

sim:
	spike --isa=RV32IMAFDC +signature=$(TARGET).signature.output +signature-granularity=16 $(TARGET)
	diff --ignore-case $(TARGET).signature.output $(TARGET).reference_output || exit
	echo "Signature matches! Success!"

clean:
	rm -f $(TARGET) $(TARGET).objdump $(TARGET).signature.output



