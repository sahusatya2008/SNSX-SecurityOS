%define KBD_DATA_PORT 0x60

section .text

keyboard_init:
    mov qword [keyboard_head], 0
    mov qword [keyboard_tail], 0
    mov qword [keyboard_event_count], 0
    ret

keyboard_on_irq:
    push rax
    push rbx
    push rdi
    inc qword [keyboard_event_count]
    mov edi, KBD_DATA_PORT
    call inb
    mov bl, al

    cmp bl, 0xE0
    je .done
    test bl, 0x80
    jnz .done

    movzx eax, bl
    mov al, [keyboard_map + rax]
    test al, al
    jz .done

    mov rdi, [keyboard_head]
    mov rbx, [keyboard_tail]
    mov rcx, rdi
    inc rcx
    and rcx, 127
    cmp rcx, rbx
    je .done
    mov [keyboard_buffer + rdi], al
    mov [keyboard_head], rcx

.done:
    pop rdi
    pop rbx
    pop rax
    ret

keyboard_get_char:
    mov rax, [keyboard_head]
    cmp rax, [keyboard_tail]
    je .empty
    mov rcx, [keyboard_tail]
    mov al, [keyboard_buffer + rcx]
    inc rcx
    and rcx, 127
    mov [keyboard_tail], rcx
    ret
.empty:
    xor eax, eax
    ret

section .data
keyboard_head dq 0
keyboard_tail dq 0
keyboard_event_count dq 0
keyboard_buffer times 128 db 0

keyboard_map:
    db 0
    db 27
    db '1','2','3','4','5','6','7','8','9','0','-','='
    db 8
    db 9
    db 'q','w','e','r','t','y','u','i','o','p','[',']'
    db 10
    db 0
    db 'a','s','d','f','g','h','j','k','l',';',39,'`'
    db 0
    db 92
    db 'z','x','c','v','b','n','m',',','.','/'
    db 0
    db '*'
    db 0
    db ' '
    times 70 db 0
