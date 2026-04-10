section .text

sandbox_vuln_demo:
    lea rdi, [sandbox_title]
    call console_write_line
    lea rdi, [sandbox_intro]
    call console_write_line

    call sandbox_prepare_frame
    call sandbox_capture_registers

    lea rdi, [sandbox_before]
    call console_write_line
    lea rdi, [sandbox_frame]
    mov rsi, 32
    call console_dump_bytes

    xor rcx, rcx
.loop_activity:
    inc rcx
    cmp rcx, 200000
    jb .loop_activity
    call security_record_demo_loop_alert

    lea rdi, [sandbox_frame]
    lea rsi, [sandbox_payload]
    mov rcx, 32
    call mem_copy

    lea rdi, [sandbox_after]
    call console_write_line
    lea rdi, [sandbox_frame]
    mov rsi, 32
    call console_dump_bytes

    lea rdi, [sandbox_regs_title]
    call console_write_line
    lea rdi, [reg_rax_label]
    mov rsi, [sandbox_reg_rax]
    call sandbox_print_reg_line
    lea rdi, [reg_rbx_label]
    mov rsi, [sandbox_reg_rbx]
    call sandbox_print_reg_line
    lea rdi, [reg_rcx_label]
    mov rsi, [sandbox_reg_rcx]
    call sandbox_print_reg_line
    lea rdi, [reg_rdx_label]
    mov rsi, [sandbox_reg_rdx]
    call sandbox_print_reg_line
    lea rdi, [reg_rsp_label]
    mov rsi, [sandbox_reg_rsp]
    call sandbox_print_reg_line
    lea rdi, [reg_rbp_label]
    mov rsi, [sandbox_reg_rbp]
    call sandbox_print_reg_line

    mov rax, [sandbox_fake_rip]
    cmp rax, kernel_text_start
    jb .corrupted
    cmp rax, kernel_text_end
    jae .corrupted
    lea rdi, [sandbox_safe]
    call console_write_line
    ret

.corrupted:
    call security_record_demo_corruption
    lea rdi, [sandbox_detected]
    call console_write_line
    lea rdi, [sandbox_explain]
    call console_write_line
    ret

sandbox_prepare_frame:
    lea rdi, [sandbox_frame]
    mov rcx, 32
    call mem_zero
    mov rax, 0x1111222233334444
    mov [sandbox_frame + 16], rax
    mov rax, kernel_entry
    mov [sandbox_frame + 24], rax
    ret

sandbox_capture_registers:
    mov [sandbox_reg_rax], rax
    mov [sandbox_reg_rbx], rbx
    mov [sandbox_reg_rcx], rcx
    mov [sandbox_reg_rdx], rdx
    mov [sandbox_reg_rsp], rsp
    mov [sandbox_reg_rbp], rbp
    ret

sandbox_print_reg_line:
    call console_write
    mov rdi, rsi
    call console_write_hex64
    mov al, 10
    call console_putc
    ret

section .rodata
sandbox_title db '== Safe Vulnerability Lab ==', 0
sandbox_intro db 'Demonstrating synthetic stack corruption inside an isolated buffer.', 0
sandbox_before db 'Before mutation:', 0
sandbox_after db 'After mutation:', 0
sandbox_regs_title db 'Register snapshot:', 0
sandbox_safe db 'No return-address anomaly detected.', 0
sandbox_detected db 'Security engine detected a corrupted synthetic return address.', 0
sandbox_explain db 'The fake RIP was altered inside lab memory only. Control flow was not hijacked.', 0
reg_rax_label db 'RAX: ', 0
reg_rbx_label db 'RBX: ', 0
reg_rcx_label db 'RCX: ', 0
reg_rdx_label db 'RDX: ', 0
reg_rsp_label db 'RSP: ', 0
reg_rbp_label db 'RBP: ', 0

sandbox_payload:
    db 'A','A','A','A','A','A','A','A'
    db 'B','B','B','B','B','B','B','B'
    db 'C','C','C','C','C','C','C','C'
    dq 0x4142434445464748

section .data
sandbox_frame:
    times 32 db 0

sandbox_fake_rip equ sandbox_frame + 24

sandbox_reg_rax dq 0
sandbox_reg_rbx dq 0
sandbox_reg_rcx dq 0
sandbox_reg_rdx dq 0
sandbox_reg_rsp dq 0
sandbox_reg_rbp dq 0
