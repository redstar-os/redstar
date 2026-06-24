// UART驱动 - 按芯片类型选择外设
#include "uart.h"
#include "../arch/uart.h"

#if defined(NS16550A)
// ========== NS16550A 驱动 ==========

void uart_init(void) {
    arch_uart_write(NS16550A_IER, 0x00);   // 禁用中断
    arch_uart_write(NS16550A_FCR, 0x07);  // 启用FIFO，清空缓冲区
    arch_uart_write(NS16550A_LCR, 0x03);  // 8位数据，无校验，1位停止位
    arch_uart_write(NS16550A_MCR, 0x03);  // 启用DTR和RTS
}

void uart_putc(char c) {
    while ((arch_uart_read(NS16550A_LSR) & NS16550A_LSR_THRE) == 0);
    arch_uart_write(NS16550A_THR, c);
}

char uart_getc(void) {
    while ((arch_uart_read(NS16550A_LSR) & NS16550A_LSR_DR) == 0);
    return arch_uart_read(NS16550A_RBR);
}

#elif defined(PL011)
// ========== PL011 驱动 (aarch64) ==========

void uart_init(void) {
    // 禁用UART进行配置
    arch_uart_write(PL011_CR, 0x0);

    // 设置波特率 115200 @ 24MHz
    arch_uart_write(PL011_IBRD, 26);
    arch_uart_write(PL011_FBRD, 3);

    // 8位数据，无校验，1位停止位
    arch_uart_write(PL011_LCRH, 0x60);

    // 启用UART和发送/接收
    arch_uart_write(PL011_CR, 0x301);
}

void uart_putc(char c) {
    while ((arch_uart_read(PL011_FR) & PL011_FR_TXFF) != 0);
    arch_uart_write(PL011_DR, c);
}

char uart_getc(void) {
    while ((arch_uart_read(PL011_FR) & PL011_FR_RXFE) != 0);
    return arch_uart_read(PL011_DR);
}

#else
#error "未定义芯片类型，请定义 NS16550A 或 PL011"
#endif

// 发送字符串
void uart_puts(const char *str) {
    while (*str) {
        if (*str == '\n') {
            uart_putc('\r');
        }
        uart_putc(*str++);
    }
}