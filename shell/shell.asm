%define SHELL_BUFFER_LEN 64

section .text

shell_main:
    lea rdi, [shell_banner]
    call console_write_line

.prompt:
    call security_periodic
    lea rdi, [shell_prompt]
    call console_write
    lea rdi, [shell_buffer]
    mov rcx, SHELL_BUFFER_LEN
    call shell_read_line
    lea rdi, [shell_buffer]
    call parse_line_is_empty
    test rax, rax
    jnz .prompt
    call security_note_activity
    lea rdi, [shell_buffer]
    call shell_execute
    jmp .prompt

shell_read_line:
    push rbx
    push rax
    push r8
    push r9
    mov rbx, rdi
    mov r8, rcx
    xor r9, r9
.wait:
    call keyboard_get_char
    test al, al
    jz .idle
    cmp al, 10
    je .enter
    cmp al, 13
    je .enter
    cmp al, 8
    je .backspace
    mov rax, r8
    dec rax
    cmp r9, rax
    jae .overflow
    mov [rbx + r9], al
    inc r9
    mov byte [rbx + r9], 0
    call console_putc
    jmp .wait
.idle:
    call security_note_idle
    hlt
    jmp .wait
.backspace:
    test r9, r9
    jz .wait
    dec r9
    mov byte [rbx + r9], 0
    mov al, 8
    call console_putc
    jmp .wait
.overflow:
    call security_record_input_limit
    jmp .wait
.enter:
    mov byte [rbx + r9], 0
    mov al, 10
    call console_putc
    pop r9
    pop r8
    pop rax
    pop rbx
    ret

.restore_and_ret:
    pop r9
    pop r8
    pop rax
    pop rbx
    ret

shell_execute:
    inc qword [shell_command_count]
    lea rdi, [shell_module]
    lea rsi, [shell_command_event]
    lea rdx, [shell_buffer]
    call log_event

    lea rdi, [shell_buffer]
    lea rsi, [cmd_memcheck]
    call str_eq
    test rax, rax
    jnz shell_cmd_memcheck

    lea rdi, [shell_buffer]
    lea rsi, [cmd_integrity]
    call str_eq
    test rax, rax
    jnz shell_cmd_integrity

    lea rdi, [shell_buffer]
    lea rsi, [cmd_procstat]
    call str_eq
    test rax, rax
    jnz shell_cmd_procstat

    lea rdi, [shell_buffer]
    lea rsi, [cmd_vuln_demo]
    call str_eq
    test rax, rax
    jnz shell_cmd_vuln_demo

    lea rdi, [shell_unknown]
    call console_write_line
    ret

shell_cmd_memcheck:
    lea rdi, [memcheck_title]
    call console_write_line
    lea rdi, [mem_text_label]
    mov rsi, kernel_text_start
    call shell_print_hex_line
    lea rdi, [mem_text_end_label]
    mov rsi, kernel_text_end
    call shell_print_hex_line
    lea rdi, [mem_stack_low_label]
    mov rsi, [security_stack_low]
    call shell_print_hex_line
    lea rdi, [mem_stack_high_label]
    mov rsi, [security_stack_high]
    call shell_print_hex_line
    lea rdi, [mem_fault_addr_label]
    mov rsi, [security_last_fault_addr]
    call shell_print_hex_line
    ret

shell_cmd_integrity:
    lea rdi, [integrity_title]
    call console_write_line
    call security_check_integrity
    test rax, rax
    jz .bad
    lea rdi, [integrity_ok]
    call console_write_line
    jmp .common
.bad:
    lea rdi, [integrity_bad]
    call console_write_line
.common:
    lea rdi, [integrity_baseline_label]
    mov rsi, [security_baseline_checksum]
    call shell_print_hex_line
    lea rdi, [integrity_current_label]
    mov rsi, [security_last_checksum]
    call shell_print_hex_line
    ret

shell_cmd_procstat:
    lea rdi, [procstat_title]
    call console_write_line
    lea rdi, [proc_ticks_label]
    mov rsi, [system_ticks]
    call shell_print_dec_line
    lea rdi, [proc_keys_label]
    mov rsi, [keyboard_event_count]
    call shell_print_dec_line
    lea rdi, [proc_cmds_label]
    mov rsi, [shell_command_count]
    call shell_print_dec_line
    lea rdi, [proc_anoms_label]
    mov rsi, [security_anomaly_count]
    call shell_print_dec_line
    lea rdi, [proc_behavior_label]
    mov rsi, [security_behavior_alerts]
    call shell_print_dec_line
    lea rdi, [proc_logs_label]
    mov rsi, [log_count]
    call shell_print_dec_line
    ret

shell_cmd_vuln_demo:
    call sandbox_vuln_demo
    lea rdi, [logs_title]
    call console_write_line
    call log_dump_recent
    ret

shell_print_hex_line:
    call console_write
    mov rdi, rsi
    call console_write_hex64
    mov al, 10
    call console_putc
    ret

shell_print_dec_line:
    call console_write
    mov rdi, rsi
    call console_write_dec64
    mov al, 10
    call console_putc
    ret

section .rodata
shell_banner db 'SecurityOS shell ready. Commands: memcheck integrity procstat vuln-demo', 0
shell_prompt db 'secos> ', 0
shell_unknown db 'Unknown command', 0
shell_module db 'SHELL', 0
shell_command_event db 'COMMAND', 0

cmd_memcheck db 'memcheck', 0
cmd_integrity db 'integrity', 0
cmd_procstat db 'procstat', 0
cmd_vuln_demo db 'vuln-demo', 0

memcheck_title db '== Memory Report ==', 0
mem_text_label db 'text-start : ', 0
mem_text_end_label db 'text-end   : ', 0
mem_stack_low_label db 'stack-low  : ', 0
mem_stack_high_label db 'stack-high : ', 0
mem_fault_addr_label db 'last-fault : ', 0

integrity_title db '== Integrity Report ==', 0
integrity_ok db 'kernel text checksum matches baseline', 0
integrity_bad db 'kernel text checksum mismatch detected', 0
integrity_baseline_label db 'baseline : ', 0
integrity_current_label db 'current  : ', 0

procstat_title db '== Process / Security Stats ==', 0
proc_ticks_label db 'ticks      : ', 0
proc_keys_label db 'key-events : ', 0
proc_cmds_label db 'commands   : ', 0
proc_anoms_label db 'anomalies  : ', 0
proc_behavior_label db 'behaviors  : ', 0
proc_logs_label db 'log-count  : ', 0
logs_title db '== Recent Logs ==', 0

section .data
shell_command_count dq 0
shell_buffer times SHELL_BUFFER_LEN db 0
