# Step 1: 打印字符 - 三种架构启动流程分析

## 概述

本文档详细分析 x86_64、RISC-V 64、ARM64 (aarch64) 三种架构从上电开始到打印"Hello Kernel"的完整软硬件执行过程。

当前实现采用分层架构设计：
- **boot.S**：架构特定的启动代码，负责初始化并跳转到C语言主函数
- **kernel/main.c**：通用内核主函数，调用UART驱动
- **drivers/uart.c**：按芯片类型条件编译的UART驱动
- **arch/<arch>/uart.h**：架构特定的硬件抽象层

---

## 一、x86_64 架构启动流程

### 1.1 硬件上电阶段

| 阶段 | 操作 | 说明 |
|------|------|------|
| 复位 | CPU从物理地址 `0xFFFFFFF0` 开始执行 | x86复位向量，指向BIOS/UEFI入口 |
| BIOS初始化 | 执行POST（加电自检） | 检测内存、PCI设备等硬件 |
| 引导设备检测 | BIOS查找可引导设备 | 优先从CD/DVD（GRUB ISO镜像）启动 |

### 1.2 GRUB Bootloader阶段

```
BIOS → 读取MBR → 加载GRUB第一阶段 → 加载GRUB第二阶段 → 解析grub.cfg
```

**关键操作**：
1. GRUB读取ISO镜像中的 `kernel.elf`
2. 检查Multiboot2协议头：
    - 魔数：`0xE85250D6`
    - 架构：`0`（i386）
    - 头部长度：动态计算
    - 校验和：`-(magic + arch + header_length)`
3. 加载内核到物理地址 `0x100000`（1MB处）
4. 设置32位保护模式环境
5. 跳转到 `_start` 入口

### 1.3 内核启动阶段（boot.S）

```asm
_start:
    cli                     # 关闭中断
    mov esp, 0x8000000      # 设置32位栈指针
    call kernel_main        # 跳转到C语言主函数

halt:
    hlt
    jmp halt
```

**执行流程**：

| 步骤 | 指令 | 作用 |
|------|------|------|
| 1 | `cli` | 关闭可屏蔽中断 |
| 2 | `mov esp, 0x8000000` | 设置32位栈指针（128MB处） |
| 3 | `call kernel_main` | 跳转到C语言内核主函数 |

### 1.4 C语言内核主函数（kernel/main.c）

```c
void kernel_main(void) {
    uart_init();              // 初始化UART
    uart_puts("Hello Kernel\n");  // 输出欢迎信息
    while (1);                // 死循环
}
```

### 1.5 UART硬件访问（NS16550A）

**COM1串口（NS16550A兼容）**：
- 基地址：`0x3F8`
- 访问方式：I/O端口（`in`/`out`指令）
- 初始化流程：
  1. 禁用中断（IER = 0x00）
  2. 启用FIFO（FCR = 0x07）
  3. 设置8位数据（LCR = 0x03）
  4. 启用DTR和RTS（MCR = 0x03）

---

## 二、RISC-V 64 架构启动流程

### 2.1 硬件上电阶段

| 阶段 | 操作 | 说明 |
|------|------|------|
| 复位 | CPU从地址 `0x1000` 开始执行 | QEMU virt平台默认复位向量 |
| SBI初始化 | OpenSBI固件执行 | 设置PMP、初始化串口等 |
| 环境准备 | SBI设置hart状态 | 禁用分页，设置栈指针 |
| 跳转内核 | SBI跳转到内核入口 | 默认地址 `0x80200000` |

### 2.2 内核启动阶段（boot.S）

```asm
_start:
    la sp, _stack_top        # 设置栈指针
    call kernel_main         # 跳转到C语言主函数

halt:
    wfi
    j halt
```

**执行流程**：

| 步骤 | 指令 | 作用 |
|------|------|------|
| 1 | `la sp, _stack_top` | 加载栈顶地址到sp |
| 2 | `call kernel_main` | 跳转到C语言内核主函数 |

### 2.3 C语言内核主函数

与x86_64相同，调用 `uart_init()` 和 `uart_puts()`。

### 2.4 UART硬件访问（NS16550A）

**NS16550A UART**：
- 基地址：`0x10000000`（QEMU virt平台）
- 访问方式：内存映射I/O
- 初始化流程与x86_64相同（NS16550A芯片）

---

## 三、ARM64 (aarch64) 架构启动流程

### 3.1 硬件上电阶段

| 阶段 | 操作 | 说明 |
|------|------|------|
| 复位 | CPU从地址 `0x0` 开始执行 | ARM标准复位向量 |
| 固件初始化 | 执行BL31/UEFI固件 | 设置EL1模式环境 |
| 安全状态设置 | 配置异常级别 | 从EL3切换到EL1 |
| 跳转内核 | 跳转到内核入口 | 默认地址 `0x80000000` |

### 3.2 内核启动阶段（boot.S）

```asm
_start:
    msr daifset, #0xf       # 关闭中断
    mov sp, #0x8000000      # 设置栈指针
    bl kernel_main          # 跳转到C语言主函数

halt:
    wfe
    b halt
```

**执行流程**：

| 步骤 | 指令 | 作用 |
|------|------|------|
| 1 | `msr daifset, #0xf` | 禁用IRQ、FIQ、SError、Debug异常 |
| 2 | `mov sp, #0x8000000` | 设置EL1栈指针（128MB处） |
| 3 | `bl kernel_main` | 跳转到C语言内核主函数 |

### 3.3 C语言内核主函数

与其他架构相同，调用 `uart_init()` 和 `uart_puts()`。

### 3.4 UART硬件访问（PL011）

**PL011 UART**：
- 基地址：`0x9000000`（QEMU virt平台）
- 访问方式：内存映射I/O
- 初始化流程：
  1. 禁用UART（CR = 0x0）
  2. 设置波特率115200（IBRD=26, FBRD=3）
  3. 设置8位数据（LCRH = 0x60）
  4. 启用UART（CR = 0x301）

---

## 四、代码架构设计

### 4.1 目录结构

```
arch/
├── uart.h              # 统一接口，根据架构包含对应的头文件
├── x86_64/
│   ├── boot.S          # x86_64启动代码（Multiboot2）
│   ├── kernel.ld       # 链接脚本
│   └── uart.h         # NS16550A (I/O端口)
├── riscv64/
│   ├── boot.S         # RISC-V 64启动代码
│   ├── kernel.ld      # 链接脚本
│   └── uart.h         # NS16550A (内存映射)
└── aarch64/
    ├── boot.S          # ARM64启动代码
    ├── kernel.ld       # 链接脚本
    └── uart.h         # PL011 (内存映射)

drivers/
├── uart.h             # 通用UART接口（函数声明）
└── uart.c             # 通用UART实现（按芯片类型条件编译）

kernel/
└── main.c             # 内核主函数
```

### 4.2 层次设计

| 层次 | 文件 | 职责 |
|------|------|------|
| **架构抽象层** | arch/uart.h | 根据架构宏包含对应的硬件定义 |
| **硬件抽象层** | arch/\<arch\>/uart.h | 定义芯片寄存器、I/O操作函数 |
| **芯片驱动层** | drivers/uart.c | 实现uart_init/putc/getc，按芯片类型条件编译 |
| **通用接口层** | drivers/uart.h | 声明通用函数接口 |
| **应用层** | kernel/main.c | 调用通用UART接口 |

### 4.3 UART驱动实现

**NS16550A驱动（x86_64 + riscv64）**：
```c
void uart_init(void) {
    arch_uart_write(NS16550A_IER, 0x00);   // 禁用中断
    arch_uart_write(NS16550A_FCR, 0x07);  // 启用FIFO
    arch_uart_write(NS16550A_LCR, 0x03);  // 8位数据
    arch_uart_write(NS16550A_MCR, 0x03);  // 启用DTR和RTS
}

void uart_putc(char c) {
    while ((arch_uart_read(NS16550A_LSR) & NS16550A_LSR_THRE) == 0);
    arch_uart_write(NS16550A_THR, c);
}
```

**PL011驱动（aarch64）**：
```c
void uart_init(void) {
    arch_uart_write(PL011_CR, 0x0);       // 禁用UART
    arch_uart_write(PL011_IBRD, 26);      // 波特率115200
    arch_uart_write(PL011_FBRD, 3);
    arch_uart_write(PL011_LCRH, 0x60);    // 8位数据
    arch_uart_write(PL011_CR, 0x301);     // 启用UART
}

void uart_putc(char c) {
    while ((arch_uart_read(PL011_FR) & PL011_FR_TXFF) != 0);
    arch_uart_write(PL011_DR, c);
}
```

---

## 五、三种架构对比总结

| 对比维度 | x86_64 | RISC-V 64 | ARM64 |
|----------|--------|-----------|-------|
| **复位地址** | `0xFFFFFFF0` | `0x1000` | `0x0` |
| **启动固件** | BIOS/UEFI + GRUB | OpenSBI | BL31/UEFI |
| **启动协议** | Multiboot2 | SBI | SMC |
| **UART芯片** | NS16550A | NS16550A | PL011 |
| **UART地址** | `0x3F8` | `0x10000000` | `0x9000000` |
| **UART访问** | I/O端口 | 内存映射 | 内存映射 |
| **中断控制** | `cli` | SBI已禁用 | `msr daifset` |
| **待机指令** | `hlt` | `wfi` | `wfe` |
| **汇编语法** | Intel | AT&T | AT&T |
| **编译目标** | x86_64-unknown-none-elf (-m32) | riscv64-unknown-none-elf | aarch64-unknown-none-elf |

### 5.1 共同点

1. **启动流程一致**：boot.S → kernel_main → uart_init → uart_puts
2. **代码复用**：C语言内核主函数和UART驱动逻辑共享
3. **架构抽象**：通过条件编译和头文件包含实现架构无关性

### 5.2 差异点

1. **启动协议**：x86_64使用Multiboot2，其他使用SBI/SMC
2. **UART芯片**：x86_64和RISC-V使用NS16550A，ARM64使用PL011
3. **访问方式**：x86_64使用I/O端口，其他使用内存映射
4. **汇编语法**：x86_64使用Intel语法，其他使用AT&T语法

---

## 六、QEMU配置与验证

### 6.1 编译命令

```bash
# x86_64（需要GRUB镜像）
make ARCH=x86_64 kernel
make ARCH=x86_64 qemu

# RISC-V 64
make ARCH=riscv64 kernel
make ARCH=riscv64 qemu

# ARM64
make ARCH=aarch64 kernel
make ARCH=aarch64 qemu

# 一次性编译所有架构
make all-arch
```

### 6.2 QEMU参数说明

| 架构 | QEMU命令 | 关键参数 |
|------|----------|----------|
| x86_64 | `qemu-system-x86_64` | `-M q35`, `-drive format=raw,file=disk.img`, `-serial mon:stdio` |
| RISC-V | `qemu-system-riscv64` | `-M virt`, `-kernel kernel`, `-nographic` |
| ARM64 | `qemu-system-aarch64` | `-M virt`, `-cpu cortex-a53`, `-kernel kernel`, `-nographic` |

### 6.3 GRUB配置（x86_64）

```bash
menuentry "Redstar OS" {
    multiboot2 /boot/kernel.elf
    boot
}
```

### 6.4 预期输出

三种架构运行后均应输出：
```
Hello Kernel
```

---

## 七、关键技术点

### 7.1 Multiboot2协议

**优势**：
- 标签式头部结构，易于扩展
- 支持多架构（i386、ARM、MIPS等）
- 支持UEFI启动环境
- 提供更详细的内存布局信息

**头部结构**：
```asm
.set MB2_MAGIC, 0xE85250D6
.set MB2_ARCH, 0               # i386架构
.set MB2_HEADER_LEN, (mb2_header_end - mb2_header_start)
.set MB2_CHECKSUM, -(MB2_MAGIC + MB2_ARCH + MB2_HEADER_LEN)
```

### 7.2 架构抽象设计

**编译宏定义**：
```makefile
CFLAGS := -target $(TARGET) -DARCH_x86_64 -Iarch
```

**条件编译**：
```c
#if defined(ARCH_x86_64) || defined(ARCH_riscv64)
    // NS16550A驱动
#elif defined(ARCH_aarch64)
    // PL011驱动
#endif
```

### 7.3 UART驱动优化

**按芯片类型分离**：
- NS16550A：x86_64和RISC-V共享驱动代码
- PL011：ARM64专用驱动代码
- 减少代码重复，提高可维护性

**硬件抽象层**：
- `arch_uart_write()` / `arch_uart_read()`：架构特定的寄存器访问
- 封装I/O端口和内存映射的差异