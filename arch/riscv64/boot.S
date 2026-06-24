# RISC-V 64 启动代码
# 负责初始化并跳转到 kernel_main

.section .text
.global _start
.type _start, @function

_start:
    # 设置栈指针 (使用链接器脚本定义的栈顶)
    la sp, _stack_top
    
    # 跳转到C语言内核主函数
    call kernel_main

# 死循环（不应到达这里）
halt:
    wfi
    j halt

.size _start, . - _start