USE64

[EXTERN main]
[EXTERN irq_handler]
[EXTERN isr_handler]
[EXTERN console_clear_screen]
[EXTERN console_print_string]
[EXTERN console_put_hex]
[EXTERN console_put_hex64]
[EXTERN task_poll_for_work]
[EXTERN panic]

[GLOBAL start]
[GLOBAL create_gate]
[GLOBAL create_isr_handler]
[GLOBAL main_loop]
[GLOBAL halt]
[GLOBAL install_gdt]


start:
    mov rsp, 0x18000
    call console_clear_screen
    mov rdi, hello_message
    call console_print_string
    call main
    sti
    mov [lastStack], esp
main_loop:
    mov eax, [lastStack]
    cmp eax, esp
    jne stack_slam
    call task_poll_for_work
    hlt
    jmp main_loop

stack_slam:
    mov rdi, stack_differs
    call console_print_string
    mov esp, [lastStack]
    jmp main_loop

; rdi - data to be copied
; esi - size of data in bytes
install_gdt:
    mov ecx, esi
    dec esi
    mov word [gdtr64], si
	mov rsi, rdi
	mov rdi, 0x00001000		; GDT address
    mov [gdtr64+2], rdi     ; stor in GDTR
	rep movsb			    ; copy to here
	lgdt [gdtr64]
    ret

create_gate:
    mov rax, rsi
; IDT entry
;   2 bytes : low bits of fun
;   2 byte : cs selector
;   1 byte : 0
;   1 byte : flags
;   2 bytes : middle 16 bits
;   4 bytes : high 32 bits
;   4 bytes : 0

	shl rdi, 4			; quickly multiply isr# by 16
	stosw				; store the low word (15..0)
	shr rax, 16
	add rdi, 4			; skip the gate marker
	stosw				; store the high word (31..16)
	shr rax, 16
	stosd				; store the high dword (63..32)
ret

%macro PUSH_ALL 0
    push rbp
    push r15
    push r14
    push r13
    push r12
    push r11
    push r10
    push r9
    push r8
    push rdx
    push rcx
    push rbx
    push rax
    push rsi
    push rdi

    mov ecx, gs
    push rcx
    mov ecx, fs
    push rcx
    mov ecx, es
    push rcx
    mov ecx, ds
    push rcx

    mov rsi, rsp
%endmacro

%macro POP_ALL 0
    pop rcx
    mov ds, ecx
    pop rcx
    mov es, ecx
    pop rcx
    mov fs, ecx
    pop rcx
    mov gs, ecx

    pop rdi
    pop rsi
    pop rax
    pop rbx
    pop rcx
    pop rdx
    pop r8
    pop r9
    pop r10
    pop r11
    pop r12
    pop r13
    pop r14
    pop r15
    pop rbp
    add rsp, 8
%endmacro

%macro ISR_ERR 1
    [GLOBAL isr%1]
    isr%1:
        cli
        PUSH_ALL
        mov edi, dword %1
        jmp isr_common
%endmacro

%macro ISR 1
    [GLOBAL isr%1]
    isr%1:
        cli
        push 0
        PUSH_ALL
        mov edi, dword %1
        jmp isr_common
%endmacro

isr_common:
   call isr_handler
   POP_ALL
   sti
   iretq

%macro IRQ 2
    [GLOBAL irq%1]
    irq%1:
        cli
        push 0
        PUSH_ALL
        mov edi, dword %2
        jmp irq_common
%endmacro

irq_common:
   mov al, 0x20
   cmp edi, 39
   jle reset_master
   out 0xa0, al ; reset slave
reset_master:
   out 0x20, al ; reset master
   call irq_handler
   POP_ALL
   sti
   iretq

IRQ 0, 32
IRQ 1, 33
IRQ 2, 34
IRQ 3, 35
IRQ 4, 36
IRQ 5, 37
IRQ 6, 38
IRQ 7, 39
IRQ 8, 40
IRQ 9, 41
IRQ 10, 42
IRQ 11, 43
IRQ 12, 44
IRQ 13, 45
IRQ 14, 46
IRQ 15, 47

ISR 0
ISR 1
ISR 2
ISR 3
ISR 4
ISR 5
ISR 6
ISR 7
ISR_ERR 8
ISR 9
ISR_ERR 10
ISR_ERR 11
ISR_ERR 12
ISR_ERR 13
ISR_ERR 14
ISR 15
ISR 16
ISR_ERR 17
ISR 18
ISR 19
ISR 20
ISR 21
ISR 22
ISR 23
ISR 24
ISR 25
ISR 26
ISR 27
ISR 28
ISR 29
ISR 30
ISR 31

lastStack     dq 0
stack_differs db `Stack pointer has changed\n`, 0
hello_message db `Hello, World\n`, 0
gdtr64        dw 0
              dq 0x0000000000001000
