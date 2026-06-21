global _start

section .text

_start:
    mov rbx, [rsp + 16]     ; argv[1]
    movzx rdi, byte [rbx]   ; first character

    mov rax, 60             ; sys_exit
    syscall