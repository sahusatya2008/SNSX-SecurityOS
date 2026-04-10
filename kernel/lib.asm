section .text

mem_zero:
    xor eax, eax
    rep stosb
    ret

mem_copy:
    rep movsb
    ret

str_len:
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret

str_eq:
    xor rax, rax
.loop:
    mov dl, [rdi]
    mov cl, [rsi]
    cmp dl, cl
    jne .done
    test dl, dl
    je .equal
    inc rdi
    inc rsi
    jmp .loop
.equal:
    mov rax, 1
.done:
    ret

copy_bounded_string:
    test rcx, rcx
    jz .done
    dec rcx
.loop:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    je .done
    inc rdi
    inc rsi
    test rcx, rcx
    jz .terminate
    dec rcx
    jmp .loop
.terminate:
    mov byte [rdi], 0
.done:
    ret

append_char:
    mov [rdi], al
    inc rdi
    mov rax, rdi
    ret

append_string:
.loop:
    mov al, [rsi]
    test al, al
    jz .done
    mov [rdi], al
    inc rdi
    inc rsi
    jmp .loop
.done:
    mov rax, rdi
    ret

append_hex64:
    push rcx
    push r8
    push r9
    mov al, '0'
    call append_char
    mov rdi, rax
    mov al, 'x'
    call append_char
    mov rdi, rax
    mov r8, r9
    mov r9d, 60
.hex_loop:
    mov rax, r8
    mov ecx, r9d
    shr rax, cl
    and eax, 0x0F
    mov al, [hex_digits + rax]
    call append_char
    mov rdi, rax
    sub r9d, 4
    jns .hex_loop
    pop r9
    pop r8
    pop rcx
    ret

u64_to_hex:
    push rcx
    push r8
    push r9
    mov byte [rdi], '0'
    mov byte [rdi + 1], 'x'
    lea rdi, [rdi + 2]
    mov r8, rax
    mov r9d, 60
.loop:
    mov rax, r8
    mov ecx, r9d
    shr rax, cl
    and eax, 0x0F
    mov al, [hex_digits + rax]
    mov [rdi], al
    inc rdi
    sub r9d, 4
    jns .loop
    mov byte [rdi], 0
    pop r9
    pop r8
    pop rcx
    ret

u64_to_dec:
    push rbx
    push rcx
    push rdx
    push rsi
    mov rsi, rdi
    add rsi, 31
    mov byte [rsi], 0
    dec rsi
    mov rbx, 10
    test rax, rax
    jnz .convert
    mov byte [rsi], '0'
    jmp .copy_out
.convert:
    xor rdx, rdx
.loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rsi], dl
    dec rsi
    test rax, rax
    jnz .loop
    inc rsi
.copy_out:
    mov rdi, rdi
.copy_loop:
    mov al, [rsi]
    mov [rdi], al
    inc rdi
    inc rsi
    test al, al
    jnz .copy_loop
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

parse_line_is_empty:
    xor rax, rax
.loop:
    mov dl, [rdi]
    test dl, dl
    je .empty
    cmp dl, ' '
    jne .done
    inc rdi
    jmp .loop
.empty:
    mov rax, 1
.done:
    ret

section .rodata
hex_digits db '0123456789ABCDEF', 0
