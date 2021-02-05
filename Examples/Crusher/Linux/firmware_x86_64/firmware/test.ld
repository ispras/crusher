

SECTIONS
{
   
         . = 0x08000000;
         .text : { *(.text) }
         .data : { *(.data) }
         .bss  : { *(.bss) }

}
