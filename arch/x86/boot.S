.section .multiboot
  .long 0x1BADB002, 0x11, -(0x1BADB002 + 0x11)

.section .text
.global _start
_start:
  hlt
  jmp _start