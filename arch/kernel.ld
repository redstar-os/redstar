ENTRY(_start)

SECTIONS{
    . = 0xffffffff80000000;
    .text : {
        *(.text)
    }
}