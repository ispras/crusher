arm-none-eabi-as -mcpu=cortex-r4 -g startup.s -o startup.o && \
arm-none-eabi-gcc -c -mcpu=cortex-r4 -g test.c -o test.o && \
arm-none-eabi-gcc -c -mcpu=cortex-r4 -g misc.c -o misc.o && \
arm-none-eabi-ld -T test.ld startup.o test.o misc.o -o test.elf && \
echo "OK"
