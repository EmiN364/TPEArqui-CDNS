section .text
GLOBAL syscall
syscall:
    push rbp
    mov rbp, rsp
    int 80h

    mov rsp, rbp
    pop rbp
    ret