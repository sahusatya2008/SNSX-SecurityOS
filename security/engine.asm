section .text

security_init:
    mov qword [security_anomaly_count], 0
    mov qword [security_behavior_alerts], 0
    mov qword [security_idle_counter], 0
    mov qword [security_stack_low], KERNEL_STACK_LOW
    mov qword [security_stack_high], KERNEL_STACK_TOP
    mov qword [security_stack_warn], KERNEL_STACK_LOW + 0x0800
    mov qword [security_stack_warned], 0
    call security_compute_checksum
    mov [security_baseline_checksum], rax
    mov [security_last_checksum], rax
    lea rdi, [sec_module]
    lea rsi, [sec_init_event]
    lea rdx, [sec_init_detail]
    call log_event
    ret

security_compute_checksum:
    push rbx
    push rcx
    push rdx
    mov rax, 1469598103934665603
    mov rbx, 1099511628211
    mov rcx, kernel_text_end - kernel_text_start
    mov rsi, kernel_text_start
.loop:
    test rcx, rcx
    jz .done
    movzx rdx, byte [rsi]
    xor rax, rdx
    imul rax, rbx
    inc rsi
    dec rcx
    jmp .loop
.done:
    pop rdx
    pop rcx
    pop rbx
    ret

security_check_integrity:
    call security_compute_checksum
    mov [security_last_checksum], rax
    cmp rax, [security_baseline_checksum]
    jne .mismatch
    mov eax, 1
    ret
.mismatch:
    inc qword [security_anomaly_count]
    lea rdi, [sec_module]
    lea rsi, [sec_integrity_fail_event]
    lea rdx, [sec_integrity_fail_detail]
    call log_event
    xor eax, eax
    ret

security_periodic:
    mov rax, rsp
    cmp rax, [security_stack_low]
    jb .fatal
    cmp rax, [security_stack_warn]
    jb .warn
    mov qword [security_stack_warned], 0
    ret
.warn:
    cmp qword [security_stack_warned], 0
    jne .done
    mov qword [security_stack_warned], 1
    inc qword [security_anomaly_count]
    lea rdi, [sec_module]
    lea rsi, [sec_stack_warn_event]
    lea rdx, [sec_stack_warn_detail]
    call log_event
.done:
    ret
.fatal:
    inc qword [security_anomaly_count]
    lea rdi, [sec_stack_fatal_message]
    call panic_with_message

security_on_page_fault:
    mov [security_last_fault_addr], rdi
    mov [security_last_fault_err], rsi
    mov [security_last_fault_rip], rdx
    inc qword [security_anomaly_count]
    lea rdi, [mmu_module]
    lea rsi, [mmu_fault_event]
    mov rdx, [security_last_fault_addr]
    mov rcx, [security_last_fault_err]
    mov r8, [security_last_fault_rip]
    call log_event_fault
    ret

security_on_tick:
    ret

security_note_idle:
    inc qword [security_idle_counter]
    cmp qword [security_idle_counter], 50000
    jb .done
    cmp qword [security_idle_alerted], 0
    jne .done
    mov qword [security_idle_alerted], 1
    inc qword [security_behavior_alerts]
    lea rdi, [sec_module]
    lea rsi, [sec_loop_event]
    lea rdx, [sec_loop_detail]
    call log_event
.done:
    ret

security_note_activity:
    mov qword [security_idle_counter], 0
    mov qword [security_idle_alerted], 0
    ret

security_record_input_limit:
    inc qword [security_anomaly_count]
    lea rdi, [sec_module]
    lea rsi, [sec_input_event]
    lea rdx, [sec_input_detail]
    call log_event
    ret

security_record_demo_corruption:
    inc qword [security_anomaly_count]
    lea rdi, [sandbox_module]
    lea rsi, [sandbox_ret_event]
    lea rdx, [sandbox_ret_detail]
    call log_event
    ret

security_record_demo_loop_alert:
    inc qword [security_behavior_alerts]
    lea rdi, [sec_module]
    lea rsi, [sec_demo_loop_event]
    lea rdx, [sec_demo_loop_detail]
    call log_event
    ret

section .rodata
sec_module db 'SEC', 0
mmu_module db 'MMU', 0
sandbox_module db 'SBOX', 0

sec_init_event db 'ENGINE_INIT', 0
sec_integrity_fail_event db 'INTEGRITY_FAIL', 0
sec_stack_warn_event db 'STACK_WARN', 0
sec_loop_event db 'LOOP_ALERT', 0
sec_input_event db 'INPUT_BOUNDARY', 0
sec_demo_loop_event db 'DEMO_LOOP', 0
mmu_fault_event db 'PAGE_FAULT', 0
sandbox_ret_event db 'RETADDR_TAINT', 0

sec_init_detail db 'baseline checksum recorded', 0
sec_integrity_fail_detail db 'kernel text checksum mismatch', 0
sec_stack_warn_detail db 'rsp crossed low-water threshold', 0
sec_loop_detail db 'idle loop threshold exceeded', 0
sec_input_detail db 'shell input truncated at safe boundary', 0
sec_demo_loop_detail db 'demo loop counter crossed threshold', 0
sandbox_ret_detail db 'fake return address left kernel text range', 0
sec_stack_fatal_message db 'KERNEL PANIC: stack escaped security bounds', 0

section .data
security_baseline_checksum dq 0
security_last_checksum dq 0
security_anomaly_count dq 0
security_behavior_alerts dq 0
security_idle_counter dq 0
security_idle_alerted dq 0
security_stack_low dq 0
security_stack_high dq 0
security_stack_warn dq 0
security_stack_warned dq 0
security_last_fault_addr dq 0
security_last_fault_err dq 0
security_last_fault_rip dq 0
