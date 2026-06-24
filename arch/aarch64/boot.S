/* aarch64启动汇编代码 */
/* QEMU virt机器，从EL1模式启动 */
/* 负责初始化并跳转到 kernel_main */

.section .text
.global _start
.type _start, %function

_start:
    /* 关闭中断 */
    msr daifset, #0xf
    
    /* 设置栈指针 (使用固定地址) */
    mov sp, #0x8000000
    
    /* 跳转到C语言内核主函数 */
    bl kernel_main

/* 死循环（不应到达这里） */
halt:
    wfe
    b halt

.size _start, . - _start