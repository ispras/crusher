ENTRY(entry)

SECTIONS
{
   
    . = 0x00000000;
    .text : { *(.text) }
    .data : { *(.data) }
    .bss : { *(.bss COMMON) }

    input     = 0x40000000;
    stack_top = 0x40001000;

}
