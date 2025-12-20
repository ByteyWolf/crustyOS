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


    mov bx, 0x8000
    mov ah, 0x02
    mov al, 3
    mov ch, 0
    mov cl, 2
    mov dh, 0

    int 0x13

    jc disk_error

    mov ah, 0x00
    mov al, 0x03
    int 0x10

    ; fill background
    mov ax, 0xB800
    mov es, ax
    mov ax, 0x1F20
    mov cx, 2000

    xor di, di

    rep stosw

    ; let's enable a20
    in al, 0x64
    .wait1:
    test al, 2
    jnz .wait1
    mov al, 0xD1
    out 0x64, al
    .wait2:
    in al, 0x64
    test al, 2
    jnz .wait2
    mov al, 0xDF
    out 0x60, al

    jmp 0x0000:0x8000

disk_error:
    mov si, errmsg
    call print_loop
    .done:
    hlt
    jmp .done

times 0xA0-($-$$) db 0
print_loop:
    lodsb
    cmp al, 0
    je .done
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x02
    int 0x10
    jmp print_loop
    .done:
    ret

times 0xC0-($-$$) db 0
stage0msg db "CrustyOS Loader v1.0", 13, 10, 0
errmsg db "Disk read failure", 0
debugmsg db "FATsize/FATcount/Reserved: ", 0
failmsg db "OSINIT not found. Cannot boot!", 0
successmsg db "OSINIT found at cluster ", 0
osinitname db "OSINIT      "

times 510-($-$$) db 0
dw 0xAA55
