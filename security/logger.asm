%define LOG_ENTRY_COUNT 64
%define LOG_DETAIL_LEN  72
%define LOG_ENTRY_SIZE  96

section .text

logger_init:
    mov qword [log_head], 0
    mov qword [log_count], 0
    lea rdi, [log_entries]
    mov rcx, LOG_ENTRY_COUNT * LOG_ENTRY_SIZE
    call mem_zero
    ret

log_event:
    push rax
    push rbx
    push rcx
    push rdi
    push rsi
    push rdx

    mov rax, [log_head]
    mov rbx, LOG_ENTRY_SIZE
    mul rbx
    lea rcx, [log_entries + rax]

    mov rax, [system_ticks]
    mov [rcx], rax
    mov [rcx + 8], rdi
    mov [rcx + 16], rsi

    lea rdi, [rcx + 24]
    mov rsi, rdx
    mov rcx, LOG_DETAIL_LEN
    call copy_bounded_string

    mov rax, [log_head]
    inc rax
    and rax, LOG_ENTRY_COUNT - 1
    mov [log_head], rax

    mov rax, [log_count]
    cmp rax, LOG_ENTRY_COUNT
    jae .done
    inc qword [log_count]

.done:
    pop rdx
    pop rsi
    pop rdi
    pop rcx
    pop rbx
    pop rax
    ret

log_event_fault:
    push rdi
    push rsi
    push rbx
    push rdx
    push rcx
    push r8
    lea rbx, [log_scratch]
    mov rdi, rbx
    lea rsi, [detail_cr2]
    call append_string
    mov rdi, rax
    mov r9, rdx
    call append_hex64
    mov rdi, rax
    mov al, ' '
    call append_char
    mov rdi, rax
    lea rsi, [detail_err]
    call append_string
    mov rdi, rax
    mov r9, rcx
    call append_hex64
    mov rdi, rax
    mov al, ' '
    call append_char
    mov rdi, rax
    lea rsi, [detail_rip]
    call append_string
    mov rdi, rax
    mov r9, r8
    call append_hex64
    mov byte [rax], 0
    pop r8
    pop rcx
    pop rdx
    pop rbx
    pop rsi
    pop rdi
    lea rdx, [log_scratch]
    call log_event
    ret

log_dump_recent:
    push rax
    push rbx
    push rcx
    push rdx
    mov rcx, [log_count]
    test rcx, rcx
    jz .done
    cmp rcx, LOG_ENTRY_COUNT
    jne .partial
    mov rbx, [log_head]
    jmp .loop
.partial:
    xor rbx, rbx
.loop:
    mov rax, rbx
    mov rdx, LOG_ENTRY_SIZE
    mul rdx
    lea rdx, [log_entries + rax]
    mov al, '['
    call console_putc
    mov rdi, [rdx]
    call console_write_dec64
    mov al, ']'
    call console_putc
    mov al, ' '
    call console_putc
    mov al, '['
    call console_putc
    mov rdi, [rdx + 8]
    call console_write
    mov al, ']'
    call console_putc
    mov al, ' '
    call console_putc
    mov al, '['
    call console_putc
    mov rdi, [rdx + 16]
    call console_write
    mov al, ']'
    call console_putc
    mov al, ' '
    call console_putc
    mov al, '['
    call console_putc
    lea rdi, [rdx + 24]
    call console_write
    mov al, ']'
    call console_putc
    mov al, 10
    call console_putc
    inc rbx
    and rbx, LOG_ENTRY_COUNT - 1
    dec rcx
    jnz .loop
.done:
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

section .rodata
detail_cr2 db 'cr2=', 0
detail_err db 'err=', 0
detail_rip db 'rip=', 0

section .data
log_head dq 0
log_count dq 0
log_scratch times LOG_DETAIL_LEN db 0
log_entries times (LOG_ENTRY_COUNT * LOG_ENTRY_SIZE) db 0
