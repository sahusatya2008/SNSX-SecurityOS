%define IDT_TYPE_INTERRUPT 0x8E
%define KERNEL_CODE_SELECTOR 0x08

%define FRAME_VECTOR 120
%define FRAME_ERROR  128
%define FRAME_RIP    136

section .text

interrupts_init:
    push rbx
    lea rdi, [idt_table]
    mov rcx, 256 * 16
    call mem_zero

    xor ebx, ebx
.fill_defaults:
    mov rdi, rbx
    lea rsi, [isr_spurious]
    call idt_set_gate
    inc rbx
    cmp rbx, 256
    jb .fill_defaults

    mov rdi, 0
    lea rsi, [isr_divide_error]
    call idt_set_gate
    mov rdi, 6
    lea rsi, [isr_invalid_opcode]
    call idt_set_gate
    mov rdi, 8
    lea rsi, [isr_double_fault]
    call idt_set_gate
    mov rdi, 13
    lea rsi, [isr_general_protection]
    call idt_set_gate
    mov rdi, 14
    lea rsi, [isr_page_fault]
    call idt_set_gate
    mov rdi, 32
    lea rsi, [irq0_timer]
    call idt_set_gate
    mov rdi, 33
    lea rsi, [irq1_keyboard]
    call idt_set_gate

    lea rax, [idt_table]
    mov [idtr + 2], rax
    lidt [idtr]
    pop rbx
    ret

idt_set_gate:
    mov rax, rdi
    shl rax, 4
    lea rdx, [idt_table + rax]
    mov rax, rsi
    mov word [rdx], ax
    mov word [rdx + 2], KERNEL_CODE_SELECTOR
    mov byte [rdx + 4], 0
    mov byte [rdx + 5], IDT_TYPE_INTERRUPT
    shr rax, 16
    mov word [rdx + 6], ax
    shr rax, 16
    mov dword [rdx + 8], eax
    mov dword [rdx + 12], 0
    ret

interrupt_dispatch:
    mov rax, [rdi + FRAME_VECTOR]
    cmp rax, 32
    je .timer
    cmp rax, 33
    je .keyboard
    cmp rax, 14
    je .page_fault
    cmp rax, 0
    je .panic
    cmp rax, 6
    je .panic
    cmp rax, 8
    je .panic
    cmp rax, 13
    je .panic
    cmp rax, 255
    je .return
    cmp rax, 32
    jb .panic
    cmp rax, 48
    jae .return
    mov edi, eax
    call pic_send_eoi
    ret

.timer:
    call pit_on_tick
    mov edi, 32
    call pic_send_eoi
    ret

.keyboard:
    call keyboard_on_irq
    mov edi, 33
    call pic_send_eoi
    ret

.page_fault:
    mov rax, cr2
    mov rsi, [rdi + FRAME_ERROR]
    mov rdx, [rdi + FRAME_RIP]
    mov rdi, rax
    call security_on_page_fault
    lea rdi, [panic_page_fault]
    call panic_with_message

.panic:
    mov rsi, [rdi + FRAME_VECTOR]
    mov rdx, [rdi + FRAME_ERROR]
    mov rcx, [rdi + FRAME_RIP]
    call interrupt_panic

.return:
    ret

interrupt_panic:
    cli
    lea rdi, [panic_interrupt]
    call console_write_line
    lea rdi, [panic_vector_label]
    call console_write
    mov rdi, rsi
    call console_write_dec64
    mov al, 10
    call console_putc
    lea rdi, [panic_error_label]
    call console_write
    mov rdi, rdx
    call console_write_hex64
    mov al, 10
    call console_putc
    lea rdi, [panic_rip_label]
    call console_write
    mov rdi, rcx
    call console_write_hex64
    mov al, 10
    call console_putc
    call kernel_halt_forever

%macro ISR_NOERR 2
%1:
    push 0
    push %2
    jmp isr_common
%endmacro

%macro ISR_ERR 2
%1:
    push %2
    jmp isr_common
%endmacro

ISR_NOERR isr_divide_error, 0
ISR_NOERR isr_invalid_opcode, 6
ISR_ERR   isr_double_fault, 8
ISR_ERR   isr_general_protection, 13
ISR_ERR   isr_page_fault, 14
ISR_NOERR irq0_timer, 32
ISR_NOERR irq1_keyboard, 33
ISR_NOERR isr_spurious, 255

isr_common:
    cld
    push r15
    push r14
    push r13
    push r12
    push r11
    push r10
    push r9
    push r8
    push rbp
    push rdi
    push rsi
    push rdx
    push rcx
    push rbx
    push rax
    mov rdi, rsp
    call interrupt_dispatch
    pop rax
    pop rbx
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    pop rbp
    pop r8
    pop r9
    pop r10
    pop r11
    pop r12
    pop r13
    pop r14
    pop r15
    add rsp, 16
    iretq

section .rodata
panic_interrupt db 'KERNEL PANIC: unhandled interrupt', 0
panic_page_fault db 'KERNEL PANIC: page fault', 0
panic_vector_label db 'vector: ', 0
panic_error_label db 'error : ', 0
panic_rip_label db 'rip   : ', 0

section .data
idtr:
    dw (256 * 16) - 1
    dq 0
idt_table times (256 * 16) db 0
