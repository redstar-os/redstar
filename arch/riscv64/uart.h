#ifndef ARCH_RISCV64_UART_H
#define ARCH_RISCV64_UART_H

// RISC-V 64架构 UART驱动
// 使用NS16550A芯片，通过内存映射I/O访问
#if defined(MACHINE_VIRT)
#define NS16550A
#define NS16550A_MMIO_BASE 0x10000000  // QEMU virt平台

// 寄存器偏移
#define NS16550A_RBR 0   // 接收缓冲寄存器
#define NS16550A_THR 0   // 发送保持寄存器
#define NS16550A_IER 1   // 中断使能寄存器
#define NS16550A_FCR 2   // FIFO控制寄存器
#define NS16550A_LCR 3   // 线路控制寄存器
#define NS16550A_MCR 4   // MODEM控制寄存器
#define NS16550A_LSR 5   // 线路状态寄存器

// LSR位定义
#define NS16550A_LSR_DR   0x01  // 数据就绪
#define NS16550A_LSR_OE   0x02  // 溢出错误
#define NS16550A_LSR_PE   0x04  // 奇偶校验错误
#define NS16550A_LSR_FE   0x08  // 帧错误
#define NS16550A_LSR_BI   0x10  // 中止
#define NS16550A_LSR_THRE 0x20  // 发送保持寄存器空
#define NS16550A_LSR_TEMT 0x40 // 发送器空
#define NS16550A_LSR_ERR  0x80  // 错误

// 寄存器访问宏
#define NS16550A_REG(reg) (*(volatile unsigned char *)(NS16550A_MMIO_BASE + (reg)))

// 写寄存器
static inline void arch_uart_write(unsigned int reg, unsigned char val) {
    NS16550A_REG(reg) = val;
}

// 读寄存器
static inline unsigned char arch_uart_read(unsigned int reg) {
    return NS16550A_REG(reg);
}

#endif  // MACHINE_VIRT
#endif  // ARCH_RISCV64_UART_H
