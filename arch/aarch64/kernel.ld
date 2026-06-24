OUTPUT_ARCH(aarch64)
ENTRY(_start)

SECTIONS {
    . = 0x80000;  # 512KB处加载
    
    .text : {
        *(.vectors)
        *(.text .text.*)
    }
    
    .rodata : {
        *(.rodata .rodata.*)
    }
    
    .data : {
        *(.data .data.*)
    }
    
    .bss : {
        _bss_start = .;
        *(.bss .bss.*)
        *(COMMON)
        _bss_end = .;
    }
    
    . = ALIGN(16);
    . = . + 0x1000;
    _stack_top = .;
    
    /DISCARD/ : {
        *(.eh_frame)
        *(.comment)
    }
}