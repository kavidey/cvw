TARGET = trap

$(TARGET).objdump: $(TARGET)
	riscv64-unknown-elf-objdump -D $(TARGET) > $(TARGET).objdump
    
$(TARGET): $(TARGET).S Makefile
	riscv64-unknown-elf-gcc -g -o $(TARGET) -march=rv32im_zicsr -mabi=ilp32 -mcmodel=medany \
	    -nostartfiles -T../../link/link.ld $(TARGET).S

sim:
	spike --isa=rv32i +signature=$(TARGET).signature.output +signature-granularity=4 $(TARGET)
	diff --ignore-case $(TARGET).signature.output $(TARGET).reference_output || exit
	echo "Signature matches! Success!"

clean:
	rm -f $(TARGET) $(TARGET).objdump $(TARGET).signature.output



