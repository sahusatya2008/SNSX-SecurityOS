%define VGA_MEMORY 0xB8000
%define VGA_COLS 80
%define VGA_ROWS 25

section .text

console_init:
    mov byte [console_color], 0x0F
    mov qword [console_row], 0
    mov qword [console_col], 0
    call console_clear
    ret

console_clear:
    push rax
    push rcx
    push rdi
    mov rdi, VGA_MEMORY
    mov ax, 0x0F20
    mov rcx, VGA_COLS * VGA_ROWS
    rep stosw
    mov qword [console_row], 0
    mov qword [console_col], 0
    pop rdi
    pop rcx
    pop rax
    ret

console_write:
.loop:
    mov al, [rdi]
    test al, al
    jz .done
    call console_putc
    inc rdi
    jmp .loop
.done:
    ret

console_write_line:
    call console_write
    mov al, 10
    call console_putc
    ret

console_putc:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi

    mov dl, al
    mov al, dl
    call serial_write_char
    mov al, dl

    cmp al, 13
    je .carriage
    cmp al, 10
    je .newline
    cmp al, 8
    je .backspace

    mov rax, [console_row]
    mov rbx, VGA_COLS
    mul rbx
    add rax, [console_col]
    shl rax, 1
    mov rdi, VGA_MEMORY
    add rdi, rax
    mov ah, [console_color]
    mov [rdi], ax

    inc qword [console_col]
    cmp qword [console_col], VGA_COLS
    jb .done
    mov qword [console_col], 0
    inc qword [console_row]
    jmp .check_scroll

.carriage:
    mov qword [console_col], 0
    jmp .done

.newline:
    mov qword [console_col], 0
    inc qword [console_row]
    jmp .check_scroll

.backspace:
    cmp qword [console_col], 0
    je .done
    dec qword [console_col]
    mov rax, [console_row]
    mov rbx, VGA_COLS
    mul rbx
    add rax, [console_col]
    shl rax, 1
    mov rdi, VGA_MEMORY
    add rdi, rax
    mov ax, 0x0F20
    mov [rdi], ax
    jmp .done

.check_scroll:
    cmp qword [console_row], VGA_ROWS
    jb .done
    call console_scroll
    mov qword [console_row], VGA_ROWS - 1

.done:
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

console_scroll:
    push rax
    push rcx
    push rsi
    push rdi
    mov rsi, VGA_MEMORY + (VGA_COLS * 2)
    mov rdi, VGA_MEMORY
    mov rcx, VGA_COLS * (VGA_ROWS - 1)
    rep movsw
    mov rdi, VGA_MEMORY + (VGA_COLS * 2 * (VGA_ROWS - 1))
    mov ax, 0x0F20
    mov rcx, VGA_COLS
    rep stosw
    pop rdi
    pop rsi
    pop rcx
    pop rax
    ret

console_write_hex64:
    push rdi
    push rax
    mov rax, rdi
    lea rdi, [tmp_number_buffer]
    call u64_to_hex
    lea rdi, [tmp_number_buffer]
    call console_write
    pop rax
    pop rdi
    ret

console_write_dec64:
    push rdi
    push rax
    mov rax, rdi
    lea rdi, [tmp_number_buffer]
    call u64_to_dec
    lea rdi, [tmp_number_buffer]
    call console_write
    pop rax
    pop rdi
    ret

console_dump_bytes:
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    mov rbx, rdi
    mov r8, rsi
    xor r9, r9
.line_loop:
    cmp r9, r8
    jae .done
    mov rdi, rbx
    add rdi, r9
    call console_write_hex64
    mov al, ':'
    call console_putc
    mov al, ' '
    call console_putc
    xor rcx, rcx
.byte_loop:
    cmp rcx, 16
    je .newline
    mov rdx, r9
    add rdx, rcx
    cmp rdx, r8
    jae .newline
    movzx rdi, byte [rbx + rdx]
    call console_write_hex64_byte
    mov al, ' '
    call console_putc
    inc rcx
    jmp .byte_loop
.newline:
    mov al, 10
    call console_putc
    add r9, 16
    jmp .line_loop
.done:
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    ret

console_write_hex64_byte:
    push rax
    push rbx
    movzx eax, dil
    mov ebx, eax
    shr eax, 4
    and eax, 0x0F
    mov al, [hex_digits + rax]
    call console_putc
    mov eax, ebx
    and eax, 0x0F
    mov al, [hex_digits + rax]
    call console_putc
    pop rbx
    pop rax
    ret

section .data
console_row dq 0
console_col dq 0
console_color db 0x0F
tmp_number_buffer times 32 db 0
