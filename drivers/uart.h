#ifndef _UART_H_
#define _UART_H_

// UART初始化
void uart_init(void);

// 发送一个字符
void uart_putc(char c);

// 发送字符串
void uart_puts(const char *str);

// 接收一个字符
char uart_getc(void);

#endif // _UART_H_