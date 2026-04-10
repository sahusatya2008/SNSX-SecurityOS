%define COM1_PORT 0x3F8

section .text

serial_init:
    mov edi, COM1_PORT + 1
    xor esi, esi
    call outb

    mov edi, COM1_PORT + 3
    mov esi, 0x80
    call outb

    mov edi, COM1_PORT + 0
    mov esi, 0x03
    call outb

    mov edi, COM1_PORT + 1
    xor esi, esi
    call outb

    mov edi, COM1_PORT + 3
    mov esi, 0x03
    call outb

    mov edi, COM1_PORT + 2
    mov esi, 0xC7
    call outb

    mov edi, COM1_PORT + 4
    mov esi, 0x0B
    call outb
    ret

serial_write_char:
    push rax
    push rbx
    push rdx
    mov bl, al
.wait:
    mov edi, COM1_PORT + 5
    call inb
    test al, 0x20
    jz .wait
    mov edi, COM1_PORT
    mov esi, ebx
    call outb
    pop rdx
    pop rbx
    pop rax
    ret

serial_write_string:
.loop:
    mov al, [rdi]
    test al, al
    jz .done
    call serial_write_char
    inc rdi
    jmp .loop
.done:
    ret
