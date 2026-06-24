#ifndef ARCH_AARCH64_UART_H
#define ARCH_AARCH64_UART_H

// ARM64架构 UART驱动
// 使用PL011芯片，通过内存映射I/O访问
#if defined(MACHINE_VIRT)
#define PL011
#define PL011_BASE 0x9000000  // QEMU virt平台

// PL011寄存器偏移
#define PL011_DR      0x00  // 数据寄存器
#define PL011_FR      0x18  // 标志寄存器
#define PL011_IBRD    0x24  // 整数波特率分频
#define PL011_FBRD    0x28  // 小数波特率分频
#define PL011_LCRH    0x2C  // 线路控制寄存器
#define PL011_CR      0x30  // 控制寄存器
#define PL011_IMSC    0x38  // 中断屏蔽/状态寄存器

// FR位定义
#define PL011_FR_RXFE 0x10  // 接收FIFO空
#define PL011_FR_TXFF 0x20  // 发送FIFO满
#define PL011_FR_RXFF 0x40  // 接收FIFO满
#define PL011_FR_TXFE 0x80  // 发送FIFO空

// 寄存器访问宏
#define PL011_REG(reg) (*(volatile unsigned int *)(PL011_BASE + (reg)))

// 写寄存器
static inline void arch_uart_write(unsigned int reg, unsigned int val) {
    PL011_REG(reg) = val;
}

// 读寄存器
static inline unsigned int arch_uart_read(unsigned int reg) {
    return PL011_REG(reg);
}

#endif  // MACHINE_VIRT
#endif  // ARCH_AARCH64_UART_H
