ARCH ?= x86_64	# x86_64, aarch64, riscv64

QEMU := qemu-system-$(ARCH)
QEMUOPTS :=  -d in_asm -display none

ifeq ($(ARCH), x86_64)
ARCH_DIR := x86
endif
ifeq ($(ARCH), riscv64)
ARCH_DIR := riscv
endif
ifeq ($(ARCH), aarch64)
ARCH_DIR := arm64
QEMUOPTS += -M raspi3b
endif

CC := clang
LD := ld.lld
OBJCOPY := objcopy
OBJDUMP := objdump
CFLAGS := -target $(ARCH) -c
LDFLAGS := -T arch/kernel.ld

kernel: arch/$(ARCH_DIR)/boot.S
	mkdir -p build
	$(CC) $(CFLAGS) arch/$(ARCH_DIR)/boot.S -o build/boot.o
	$(LD) $(LDFLAGS) build/boot.o -o build/kernel

clean:
	rm -rf build/

qemu: kernel
	$(QEMU) $(QEMUOPTS) -kernel build/kernel