[BITS 16]
[ORG 0x8000]

mov ah, 0x00      ; BIOS function: set video mode
mov al, 0x03      ; 80x25 text mode
int 0x10
mov si, msg

.print_loop:
    lodsb
    cmp al, 0
    je done
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x02
    int 0x10
    jmp .print_loop

done:
    hlt
    jmp done

msg db "ByteyBoot, v1.0", 0
times (512*3) - ($-$$) db 0
