%define PAGE_PRESENT 0x001
%define PAGE_WRITE   0x002
%define PAGE_GLOBAL  0x100
%define PAGE_NX      0x8000000000000000

section .text

memory_init_secure_paging:
    push rax
    push rbx
    push rcx
    push rdi

    lea rdi, [secure_pml4]
    mov rcx, 4096 * 4
    call mem_zero

    lea rax, [secure_pdpt]
    or rax, PAGE_PRESENT | PAGE_WRITE
    mov [secure_pml4], rax

    lea rax, [secure_pd]
    or rax, PAGE_PRESENT | PAGE_WRITE
    mov [secure_pdpt], rax

    lea rax, [secure_pt]
    or rax, PAGE_PRESENT | PAGE_WRITE
    mov [secure_pd], rax

    xor rcx, rcx
.map_loop:
    mov rax, rcx
    shl rax, 12
    mov rbx, PAGE_PRESENT | PAGE_WRITE | PAGE_GLOBAL | PAGE_NX
    mov r8, kernel_text_start
    and r8, -4096
    mov r9, kernel_text_end
    add r9, 4095
    and r9, -4096
    mov r10, kernel_data_start
    and r10, -4096
    mov r11, kernel_bss_end
    add r11, 4095
    and r11, -4096

    cmp rax, r10
    jb .check_code
    cmp rax, r11
    jb .store

.check_code:
    cmp rax, r8
    jb .store
    cmp rax, r9
    jb .code_page
    jmp .store

.code_page:
    mov rbx, PAGE_PRESENT | PAGE_GLOBAL

.store:
    or rax, rbx
    mov [secure_pt + rcx * 8], rax
    inc rcx
    cmp rcx, 512
    jb .map_loop

    mov ecx, 0xC0000080
    rdmsr
    bts eax, 11
    wrmsr

    mov rax, cr0
    or rax, 0x00010000
    mov cr0, rax

    lea rax, [secure_pml4]
    mov cr3, rax

    pop rdi
    pop rcx
    pop rbx
    pop rax
    ret

section .bss align=4096
secure_pml4 resq 512
align 4096
secure_pdpt resq 512
align 4096
secure_pd resq 512
align 4096
secure_pt resq 512
