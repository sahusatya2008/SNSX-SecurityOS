[bits 64]
[org 0x10000]
[default rel]

%define KERNEL_STACK_TOP 0x90000
%define KERNEL_STACK_LOW 0x86000

section .text
kernel_text_start:

section .data align=4096
kernel_data_start:

section .bss align=4096
kernel_bss_start:

section .text

kernel_entry:
    cli
    cld
    mov rsp, KERNEL_STACK_TOP
    mov rbp, rsp
    call kernel_main
    call kernel_halt_forever

kernel_main:
    call serial_init
    call console_init
    lea rdi, [kernel_banner]
    call console_write_line

    call interrupts_init
    call pic_init
    call pit_init
    call keyboard_init
    call memory_init_secure_paging
    call logger_init
    call security_init

    lea rdi, [kernel_ready]
    call console_write_line
    sti
    call shell_main
    ret

panic_with_message:
    cli
    call console_write_line
    call kernel_halt_forever

kernel_halt_forever:
    cli
.halt:
    hlt
    jmp .halt

%include "kernel/lib.asm"
%include "drivers/ports.asm"
%include "drivers/serial.asm"
%include "drivers/console.asm"
%include "drivers/pic.asm"
%include "drivers/pit.asm"
%include "drivers/keyboard.asm"
%include "kernel/interrupts.asm"
%include "memory/paging.asm"
%include "security/logger.asm"
%include "security/engine.asm"
%include "sandbox/vuln_demo.asm"
%include "shell/shell.asm"

section .text
kernel_text_end:

section .rodata
kernel_banner db 'SecurityOS x86_64 booted', 0
kernel_ready db 'Kernel services initialized', 0

section .data
kernel_data_end:

section .bss
kernel_bss_end:
