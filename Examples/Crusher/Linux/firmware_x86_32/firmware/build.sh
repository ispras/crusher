gcc -m32 -c -no-pie -fno-pic test.c && \
ld -m elf_i386 -T test.ld test.o -o test.elf && \
objcopy -O binary test.elf test.bin && \
echo "OK"
