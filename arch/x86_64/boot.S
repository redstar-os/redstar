# x86_64 启动代码
# Multiboot2协议

# Multiboot2 魔数和标志
.set MB2_MAGIC, 0xE85250D6
.set MB2_ARCH, 0               # i386架构 (0)
.set MB2_HEADER_LEN, (mb2_header_end - mb2_header_start)
.set MB2_CHECKSUM, -(MB2_MAGIC + MB2_ARCH + MB2_HEADER_LEN)

.section .multiboot
.align 8
mb2_header_start:
    # Multiboot2 头部
    .long MB2_MAGIC            # magic
    .long MB2_ARCH            # architecture (i386)
    .long MB2_HEADER_LEN      # header length
    .long MB2_CHECKSUM        # checksum

    # 结束标签 (必需)
    .align 8
    .short 0                   # type = 0 (结束)
    .short 0                   # flags
    .long 8                    # size = 8
mb2_header_end:

.section .text
.global _start
.type _start, @function

.code32
_start:
    # 关闭中断
    cli

    # 设置32位栈指针 (128MB处)
    movl $0x8000000, %esp

    # 跳转到C语言内核主函数
    call kernel_main

# 死循环（不应到达这里）
halt:
    hlt
    jmp halt

.size _start, . - _start