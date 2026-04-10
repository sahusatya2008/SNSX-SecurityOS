[bits 16]
[org 0x7C00]

%define STAGE2_LOAD_OFFSET 0x8000
%define STAGE2_LOAD_SEGMENT 0x0000
%define STAGE2_SECTORS 32
%define STAGE2_LBA 1

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov [boot_drive], dl

    mov si, stage2_dap
    mov ah, 0x42
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    jmp 0x0000:STAGE2_LOAD_OFFSET

disk_error:
    mov si, disk_error_msg
    call bios_print
.hang:
    hlt
    jmp .hang

bios_print:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    mov bx, 0x0007
    int 0x10
    jmp bios_print
.done:
    ret

boot_drive db 0
disk_error_msg db 'Disk read error', 0

stage2_dap:
    db 0x10
    db 0x00
    dw STAGE2_SECTORS
    dw STAGE2_LOAD_OFFSET
    dw STAGE2_LOAD_SEGMENT
    dq STAGE2_LBA

times 510 - ($ - $$) db 0
dw 0xAA55
