[BITS 16]
[ORG 0x7C00]

jmp short boot_start
nop

oem_name db "BYTWOLF!"

; --- BPB fields ---
bytes_per_sector    dw 512
sectors_per_cluster db 1
reserved_sectors    dw 4
num_fats            db 2
max_root_entries    dw 224
total_sectors_small dw 2880
media_descriptor    db 0xF0
sectors_per_fat     dw 9
sectors_per_track   dw 18
num_heads           dw 2
hidden_sectors      dd 0
total_sectors_large dd 0

boot_start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov ah, 0x00
    int 0x13


    mov bx, 0x8000      ; ES:BX = destination
    mov ah, 0x02        ; BIOS read
    mov al, 3           ; number of sectors
    mov ch, 0           ; cylinder 0
    mov cl, 2           ; sector 2 (first stage1 sector!)
    mov dh, 0           ; head 0

    int 0x13

    jc disk_error       ; carry flag = error

    jmp 0x0000:0x8000

disk_error:
    mov si, errmsg
    .print_loop:
        lodsb
        cmp al, 0
        je .done
        mov ah, 0x0E
        mov bh, 0x00
        mov bl, 0x02
        int 0x10
        jmp .print_loop

    .done:
        hlt
        jmp .done

errmsg db "READ FAIL", 0

times 510-($-$$) db 0
dw 0xAA55
