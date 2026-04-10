section .text

outb:
    mov dx, di
    mov al, sil
    out dx, al
    ret

inb:
    mov dx, di
    xor eax, eax
    in al, dx
    ret

io_wait:
    mov dx, 0x80
    xor al, al
    out dx, al
    ret
