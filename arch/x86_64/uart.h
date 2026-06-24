#ifndef ARCH_X86_64_UART_H
#define ARCH_X86_64_UART_H

// x86_64 + q35机器使用NS16550A (I/O端口方式)
// 基地址: 0x3F8 (COM1)
#if defined(MACHINE_Q35)
#define NS16550A
#define NS16550A_IO_BASE 0x3F8

// 寄存器偏移
#define NS16550A_RBR 0   // 接收缓冲寄存器
#define NS16550A_THR 0   // 发送保持寄存器
#define NS16550A_IER 1   // 中断使能寄存器
#define NS16550A_FCR 2   // FIFO控制寄存器
#define NS16550A_LCR 3   // 线路控制寄存器
#define NS16550A_MCR 4   // MODEM控制寄存器
#define NS16550A_LSR 5   // 线路状态寄存器

// LSR位定义
#define NS16550A_LSR_THRE 0x20  // 发送保持寄存器空
#define NS16550A_LSR_DR 0x01    // 数据就绪

// I/O端口访问
static inline void arch_uart_write(unsigned int reg, unsigned char val) {
    unsigned short port = NS16550A_IO_BASE + reg;
    __asm__ volatile (
        "outb %0, %%dx\n"
        : : "a"(val), "d"(port)
    );
}

static inline unsigned char arch_uart_read(unsigned int reg) {
    unsigned short port = NS16550A_IO_BASE + reg;
    unsigned char val;
    __asm__ volatile (
        "inb %%dx, %0\n"
        : "=a"(val) : "d"(port)
    );
    return val;
}

#endif  // MACHINE_Q35
#endif  // ARCH_X86_64_UART_H