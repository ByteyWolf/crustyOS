OUTPUT(OSINIT)
ENTRY(kmain)   /* your main entry function */

SECTIONS
{
    . = 0x10000;          /* load address */

    .text : {
        *(.text)
    }

    .rodata : {
        *(.rodata)
    }

    .data : {
        *(.data)
    }

    .bss : {
        *(.bss)
        *(COMMON)
    }
}
