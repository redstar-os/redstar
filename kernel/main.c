#include "../drivers/uart.h"

// 通用内核主函数
void kernel_main(void) {
    // 初始化UART
    uart_init();
    
    // 输出欢迎信息
    uart_puts("Hello Kernel\n");
    
    // 死循环
    while (1) {
        // 等待
    }
}