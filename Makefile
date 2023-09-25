ARCH ?= i386	# i386, aarch64, riscv64

QEMU := qemu-system-$(ARCH)
QEMUOPTS :=  -d in_asm -display none

ifeq ($(ARCH), i386)
ARCH_DIR := x86
endif
ifeq ($(ARCH), riscv64)
ARCH_DIR := riscv
QEMUOPTS += -M virt
endif
ifeq ($(ARCH), aarch64)
ARCH_DIR := arm64
QEMUOPTS += -M raspi3b
endif

CC := clang
LD := ld.lld
OBJCOPY := objcopy
OBJDUMP := objdump
CFLAGS := -target $(ARCH)-unknown-none-elf -c
LDFLAGS := -T arch/$(ARCH_DIR)/kernel.ld

kernel: arch/$(ARCH_DIR)/boot.S
	mkdir -p build
	$(CC) $(CFLAGS) arch/$(ARCH_DIR)/boot.S -o build/boot.o
	$(LD) $(LDFLAGS) build/boot.o -o build/kernel

clean:
	rm -rf build/

qemu: kernel
	$(QEMU) $(QEMUOPTS) -kernel build/kernel