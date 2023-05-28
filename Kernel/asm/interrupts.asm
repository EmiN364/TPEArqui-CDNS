
GLOBAL _cli
GLOBAL _sti
GLOBAL picMasterMask
GLOBAL picSlaveMask
GLOBAL haltcpu
GLOBAL _hlt

GLOBAL _irq00Handler
GLOBAL _irq01Handler
GLOBAL _irq02Handler
GLOBAL _irq03Handler
GLOBAL _irq04Handler
GLOBAL _irq05Handler
GLOBAL _int80Handler

GLOBAL _exception0Handler
GLOBAL _exception6Handler

GLOBAL registers
GLOBAL excepRegs

EXTERN irqDispatcher
EXTERN exceptionDispatcher
EXTERN syscallHandler

SECTION .text

%macro pushState 0
	push rax
	push rbx
	push rcx
	push rdx
	push rbp
	push rdi
	push rsi
	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	push r14
	push r15
%endmacro

%macro popState 0
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rsi
	pop rdi
	pop rbp
	pop rdx
	pop rcx
	pop rbx
	pop rax
%endmacro

%macro irqHandlerMaster 1
	pushState

	mov rdi, %1 ; pasaje de parametro
	call irqDispatcher

	; signal pic EOI (End of Interrupt)
	mov al, 20h
	out 20h, al

	popState
	iretq
%endmacro



%macro exceptionHandler 1
; When exception occurs we bring RIP value getting the return address of the interrpution
    mov [excepRegs + (1*8)], rax    ;rax
    mov rax, [rsp]
    mov [excepRegs], rax            ;rip
    pushState

    mov [excepRegs + (2*8)], rbx
    mov [excepRegs + (3*8)], rcx
    mov [excepRegs + (4*8)], rdx
    mov [excepRegs + (5*8)], rsi
    mov [excepRegs + (6*8)], rdi
    mov [excepRegs + (7*8)], rbp
    mov rax, rsp 
    add rax, 0x28 ; Add bytes to compensate for the values pushed since the exception occurred and called the exception dispatcher
    mov [excepRegs + (8*8)], rax    ;rsp
    mov [excepRegs + (9*8)], r8
    mov [excepRegs + (10*8)], r9
    mov [excepRegs + (11*8)], r10 
    mov [excepRegs + (12*8)], r11 
    mov [excepRegs + (13*8)], r12 
    mov [excepRegs + (14*8)], r13 
    mov [excepRegs + (15*8)], r14 
    mov [excepRegs + (16*8)], r15 
    mov rax, [rsp+8] ; Value of RFLAGS (it is pushed when an interrupt occurs).
    mov [excepRegs + (17*8)], rax    ;rflags

    mov rdi, %1 ; pasaje de parametro
    mov rsi, excepRegs
    call exceptionDispatcher

    popState
    iretq
%endmacro


_hlt:
	sti
	hlt
	ret

_cli:
	cli
	ret


_sti:
	sti
	ret

picMasterMask:
	push rbp
    mov rbp, rsp
    mov ax, di
    out	21h,al
    pop rbp
    retn

picSlaveMask:
	push    rbp
    mov     rbp, rsp
    mov     ax, di  ; ax = mascara de 16 bits
    out	0A1h,al
    pop     rbp
    retn

saveRegisters:
	;mov[registers], rax done below
	mov[registers + (1*8)], rbx
	mov[registers + (2*8)], rcx
	mov[registers + (3*8)], rdx
	mov[registers + (4*8)], rsi
	mov[registers + (5*8)], rdi
	mov[registers + (6*8)], rbp
	;mov[registers+ (7*8)], rsp done below
	mov[registers + (8*8)], r8
	mov[registers + (9*8)], r9
	mov[registers + (10*8)], r10
	mov[registers + (11*8)], r11
	mov[registers + (12*8)], r12
	mov[registers + (13*8)], r13
	mov[registers + (14*8)], r14
	mov[registers + (15*8)], r15
	;mov[registers+ (16*8)], rip done below

	mov rax, rsp
	add rax, 160
	mov[registers + (7*8)], rax ;RSP

	mov rax, [rsp + 15*8]
	mov[registers + (16*8)], rax ; RIP

	mov rax, [rsp + 14*8]	; RAX
	mov[registers], rax
	
	; signal pic EOI (End of Interrupt)
	mov al, 20h
	out 20h, al

	popState
	iretq


;8254 Timer (Timer Tick)
_irq00Handler:
	irqHandlerMaster 0

;Keyboard
_irq01Handler:
	pushState

	in al, 0x60
	cmp al, 0x1D; Left Control key
	je saveRegisters

	mov rdi, 1 ; pasaje de parametro
	call irqDispatcher

	; signal pic EOI (End of Interrupt)
	mov al, 20h
	out 20h, al

	popState
	iretq

;Cascade pic never called
_irq02Handler:
	irqHandlerMaster 2

;Serial Port 2 and 4
_irq03Handler:
	irqHandlerMaster 3

;Serial Port 1 and 3
_irq04Handler:
	irqHandlerMaster 4

;USB
_irq05Handler:
	irqHandlerMaster 5

;Syscalls
_int80Handler:
	pushState
	call syscallHandler
	popState
	iretq


;Zero Division Exception
_exception0Handler:
	exceptionHandler 0

;Invalid Opcde Exception
_exception6Handler:
	exceptionHandler 6

haltcpu:
	cli
	hlt
	ret



SECTION .bss
	aux resq 1
	registers resq 17 ; registers for screenshot
	excepRegs resq 18 ; registers for exceptions