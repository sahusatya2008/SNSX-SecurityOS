%define PIT_COMMAND 0x43
%define PIT_CHANNEL0 0x40
%define PIT_DIVISOR 11931

section .text

pit_init:
    mov edi, PIT_COMMAND
    mov esi, 0x36
    call outb

    mov edi, PIT_CHANNEL0
    mov esi, PIT_DIVISOR & 0xFF
    call outb

    mov edi, PIT_CHANNEL0
    mov esi, PIT_DIVISOR >> 8
    call outb
    ret

pit_on_tick:
    inc qword [system_ticks]
    call security_on_tick
    ret

section .data
system_ticks dq 0
