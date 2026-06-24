#ifndef UART_H
#define UART_H

// 根据机器类型包含对应的UART硬件抽象层
// 机器类型由Makefile定义

#if defined(__x86_64__)
    #include "x86_64/uart.h"
#elif defined(__riscv)
    #include "riscv64/uart.h"
#elif defined(__aarch64__)
    #include "aarch64/uart.h"
#else
    #error "未定义机器类型，请定义 __x86_64__, __riscv 或 __aarch64__"
#endif

#endif