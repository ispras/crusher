gcc -c -no-pie -fno-pic test.c && \
ld -T test.ld test.o -o test.elf && \
objcopy -O binary test.elf test.bin && \
echo "OK"
