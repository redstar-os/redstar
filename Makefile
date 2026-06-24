# 多架构微内核操作系统 Makefile

# 默认架构
ARCH ?= riscv64

# QEMU配置
QEMU := qemu-system-$(ARCH)
QEMUOPTS := -nographic

# 设置架构目录
ARCH_DIR := $(ARCH)

# 工具链
CC := clang
LD := ld.lld
OBJCOPY := objcopy

# 根据架构设置选项
ifeq ($(ARCH),x86_64)
    TARGET := x86_64-unknown-none-elf
    QEMUOPTS += -M q35 -cpu qemu64
    CFLAGS := -target $(TARGET) -c -Wall -Wextra -O2 -ffreestanding -nostdlib -DMACHINE_Q35 -Iarch
    LDFLAGS := -T arch/$(ARCH_DIR)/kernel.ld -nostdlib -m elf_x86_64
    KERNEL := build/$(ARCH_DIR)/kernel
    OBJECTS := build/$(ARCH_DIR)/boot.o build/$(ARCH_DIR)/main.o build/$(ARCH_DIR)/uart.o
    USE_GRUB := true  # x86_64使用GRUB引导
endif

ifeq ($(ARCH),riscv64)
    TARGET := riscv64-unknown-none-elf
    QEMUOPTS += -M virt -cpu rv64
    CFLAGS := -target $(TARGET) -c -Wall -Wextra -O2 -ffreestanding -nostdlib -mcmodel=medany -DMACHINE_VIRT -Iarch
    LDFLAGS := -T arch/$(ARCH_DIR)/kernel.ld -nostdlib
    KERNEL := build/$(ARCH_DIR)/kernel
    OBJECTS := build/$(ARCH_DIR)/boot.o build/$(ARCH_DIR)/main.o build/$(ARCH_DIR)/uart.o
endif

ifeq ($(ARCH),aarch64)
    TARGET := aarch64-unknown-none-elf
    QEMUOPTS += -M virt -cpu cortex-a53
    CFLAGS := -target $(TARGET) -c -Wall -Wextra -O2 -ffreestanding -nostdlib -DMACHINE_VIRT -Iarch
    LDFLAGS := -T arch/$(ARCH_DIR)/kernel.ld -nostdlib
    KERNEL := build/$(ARCH_DIR)/kernel
    OBJECTS := build/$(ARCH_DIR)/boot.o build/$(ARCH_DIR)/main.o build/$(ARCH_DIR)/uart.o
endif

# 默认目标
all: kernel

# 创建构建目录
build/$(ARCH_DIR):
	mkdir -p build/$(ARCH_DIR)

# 编译汇编文件
build/$(ARCH_DIR)/boot.o: arch/$(ARCH_DIR)/boot.S
	@mkdir -p build/$(ARCH_DIR)
	$(CC) $(CFLAGS) $< -o $@

# 编译C文件
build/$(ARCH_DIR)/main.o: kernel/main.c
	@mkdir -p build/$(ARCH_DIR)
	$(CC) $(CFLAGS) $< -o $@

build/$(ARCH_DIR)/uart.o: drivers/uart.c
	@mkdir -p build/$(ARCH_DIR)
	$(CC) $(CFLAGS) $< -o $@

# 链接内核
kernel: $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o $(KERNEL)
ifdef USE_GRUB
	@echo "GRUB引导模式 - ELF文件已生成"
endif

# 清理
clean:
	rm -rf build/

# 清理特定架构
clean-$(ARCH):
	rm -rf build/$(ARCH_DIR)/

# 运行QEMU
qemu: kernel
ifdef USE_GRUB
	@echo "创建GRUB磁盘镜像..."
	@mkdir -p build/$(ARCH_DIR)/iso/boot/grub
	@cp $(KERNEL) build/$(ARCH_DIR)/iso/boot/kernel.elf
	@{ \
	    echo 'set timeout=0'; \
	    echo 'set default=0'; \
	    echo 'menuentry "Redstar OS" {'; \
	    echo '    multiboot2 /boot/kernel.elf'; \
	    echo '    boot'; \
	    echo '}'; \
	} > build/$(ARCH_DIR)/iso/boot/grub/grub.cfg
	@if command -v grub2-mkrescue >/dev/null 2>&1; then \
		grub2-mkrescue -o build/$(ARCH_DIR)/disk.img build/$(ARCH_DIR)/iso; \
	elif command -v grub-mkrescue >/dev/null 2>&1; then \
		grub-mkrescue -o build/$(ARCH_DIR)/disk.img build/$(ARCH_DIR)/iso; \
	else \
		echo "错误: 未找到grub2-mkrescue或grub-mkrescue"; \
		exit 1; \
	fi
	@$(QEMU) $(QEMUOPTS) -drive format=raw,file=build/$(ARCH_DIR)/disk.img -boot c -serial mon:stdio -display none
else
	$(QEMU) $(QEMUOPTS) -kernel $(KERNEL)
endif

# 调试模式
debug: kernel
	$(QEMU) $(QEMUOPTS) -kernel $(KERNEL) -s -S &
	gdb-multiarch $(KERNEL)

# 构建所有架构
all-arch:
	$(MAKE) ARCH=x86_64 kernel
	$(MAKE) ARCH=riscv64 kernel
	$(MAKE) ARCH=aarch64 kernel

.PHONY: all kernel clean clean-$(ARCH) qemu debug all-arch