[bits 16]
[org 0x8000]

%define KERNEL_LOAD_OFFSET 0x0000
%define KERNEL_LOAD_SEGMENT 0x1000
%define KERNEL_LOAD_ADDR 0x10000
%define KERNEL_SECTORS 64
%define KERNEL_LBA 33

CODE64_SEL equ 0x08
DATA64_SEL equ 0x10

stage2_start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7A00
    sti

    mov [boot_drive], dl

    mov si, stage2_msg
    call bios_print

    call enable_a20

    mov si, kernel_dap
    mov ah, 0x42
    mov dl, [boot_drive]
    int 0x13
    jc kernel_load_error

    cli
    lgdt [gdt64_descriptor]

    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    mov eax, pml4_table
    mov cr3, eax

    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    mov eax, cr0
    or eax, 0x80000001
    mov cr0, eax

    jmp CODE64_SEL:long_mode_start

kernel_load_error:
    mov si, kernel_error_msg
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

enable_a20:
    in al, 0x92
    or al, 0x02
    out 0x92, al
    ret

[bits 64]
long_mode_start:
    mov ax, DATA64_SEL
    mov ds, ax
    mov es, ax
    mov ss, ax
    xor ax, ax
    mov fs, ax
    mov gs, ax

    mov rsp, 0x90000
    mov rbp, rsp

    mov rax, KERNEL_LOAD_ADDR
    jmp rax

[bits 16]
align 8
gdt64:
    dq 0x0000000000000000
    dq 0x00209A0000000000
    dq 0x0000920000000000
gdt64_end:

gdt64_descriptor:
    dw gdt64_end - gdt64 - 1
    dd gdt64

boot_drive db 0
stage2_msg db 'Stage2', 13, 10, 0
kernel_error_msg db 'Kernel load error', 13, 10, 0

kernel_dap:
    db 0x10
    db 0x00
    dw KERNEL_SECTORS
    dw KERNEL_LOAD_OFFSET
    dw KERNEL_LOAD_SEGMENT
    dq KERNEL_LBA

align 4096
pml4_table:
    dq pdpt_table + 0x03
    times 511 dq 0

align 4096
pdpt_table:
    dq pd_table + 0x03
    times 511 dq 0

align 4096
pd_table:
    dq 0x0000000000000083
    times 511 dq 0
