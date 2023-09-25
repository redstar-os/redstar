```shell
make ARCH=<ARCH> kernel # 编译内核。<ARCH>可以是：i386, aarch64, riscv64
make ARCH=<ARCH> qemu   # 在qemu上运行内核
make clean              # 清空编译生成的文件
```