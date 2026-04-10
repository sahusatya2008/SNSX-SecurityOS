%define PIC1_COMMAND 0x20
%define PIC1_DATA    0x21
%define PIC2_COMMAND 0xA0
%define PIC2_DATA    0xA1

section .text

pic_init:
    mov edi, PIC1_DATA
    call inb
    mov [pic1_saved_mask], al
    mov edi, PIC2_DATA
    call inb
    mov [pic2_saved_mask], al

    mov edi, PIC1_COMMAND
    mov esi, 0x11
    call outb
    call io_wait

    mov edi, PIC2_COMMAND
    mov esi, 0x11
    call outb
    call io_wait

    mov edi, PIC1_DATA
    mov esi, 0x20
    call outb
    call io_wait

    mov edi, PIC2_DATA
    mov esi, 0x28
    call outb
    call io_wait

    mov edi, PIC1_DATA
    mov esi, 0x04
    call outb
    call io_wait

    mov edi, PIC2_DATA
    mov esi, 0x02
    call outb
    call io_wait

    mov edi, PIC1_DATA
    mov esi, 0x01
    call outb
    call io_wait

    mov edi, PIC2_DATA
    mov esi, 0x01
    call outb
    call io_wait

    mov edi, PIC1_DATA
    mov esi, 0xFC
    call outb

    mov edi, PIC2_DATA
    mov esi, 0xFF
    call outb
    ret

pic_send_eoi:
    cmp edi, 40
    jb .master_only
    mov edi, PIC2_COMMAND
    mov esi, 0x20
    call outb
.master_only:
    mov edi, PIC1_COMMAND
    mov esi, 0x20
    call outb
    ret

section .data
pic1_saved_mask db 0
pic2_saved_mask db 0
