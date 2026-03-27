.intel_syntax noprefix
.global _start

.section .text
_start:
    mov rbx, [rsp + 16]        # rbx = pointer to argv[1]
    movzx rdi, byte ptr [rbx]  # rdi = first byte

    mov rax, 60                # sys_exit
    syscall
