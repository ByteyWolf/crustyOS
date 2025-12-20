[BITS 16]
[ORG 0x8000]

mov si, 0x7CC0
call 0x7CA0

load_fat12:
    mov [driveid], dl


    mov ax, [0x7C18]
    mov [numsectorspertrack], ax
    mov ax, [0x7C1A]
    mov [numheads], ax

    mov ax, [0x7C16]  ; sectors per FAT
    mov bl, [0x7C10]  ; num FATs
    xor bh, bh
    mov cx, [0x7C0E]  ; reserved sectors

    ; preserve
    push cx
    push bx
    push ax

    mov si, 0x7CE9
    call 0x7CA0

    push bp
    mov bp, sp

    ; print sectors per fat
    mov ax, [bp+2]
    call print_hex16
    mov ah, 0x0E
    mov al, 0x20
    int 0x10

    mov ax, [bp+4]
    call print_hex16
    mov ah, 0x0E
    mov al, 0x20
    int 0x10

    mov ax, [bp+6]
    call print_hex16

    call newline

    pop bp
    pop ax
    pop bx
    pop cx


    mul bx
    add ax, cx

    ; convert into chs!!
    xor dx, dx
    mov bx, 18          ; sectors per track
    div bx              ; AX = temp, DX = remainder

    inc dx              ; sector = remainder + 1
    mov cl, dl          ; CL = sector

    xor dx, dx
    mov bx, 2           ; heads
    div bx              ; AX = cylinder, DX = head

    mov ch, al          ; cylinder
    mov dh, dl          ; head



    .readextra:
    mov [fileid], 0

    push cx
    push dx

    xor ax, ax
    mov es, ax
    mov dl, [driveid]
    mov bx, 0x9000
    mov ah, 2
    mov al, 1


    int 0x13

    jc disk_error

    mov si, 0x9000

    ; at this point we have 16 files loaded
    .nextfile:
    mov ax, [fileid]

    cmp [si], 0
    je .notfound
    cmp [si], 0xE5
    je .deleted
    mov al, [si+11]
    cmp al, 0x0F
    je .deleted

    push si
    ; string ptr in si
    mov cx, 11
    mov di, 0x7D3D
    repe cmpsb
    pop si
    je .found


    add si, 32

    .nextfile__inc:
    mov al, [fileid]
    inc al
    mov [fileid], al
    cmp al, 16
    jge .nextcyl
    jmp .nextfile

    .deleted:
    add si, 32
    jmp .nextfile__inc

    .notfound:
    call newline
    call newline
    mov si, 0x7D05
    call 0x7CA0

    hlt
    jmp $

    .nextcyl:
    pop dx
    pop cx
    inc cl
    mov ax, [numsectorspertrack]
    inc ax
    cmp cl, al
    jb .readextra
    mov cl, 1
    inc dh
    cmp dh, [numheads]
    jb .readextra
    mov dh, 0
    inc ch
    jmp .readextra

    .found:
    push si
    mov si, 0x7D24
    call 0x7CA0
    pop si
    mov ax, [si+26]
    call print_hex16

    hlt
    jmp $




driveid db 0
fileid db 0
numheads dw 0
numsectorspertrack dw 0

newline:
    mov ah, 0x0E
    mov al, 10
    int 0x10
    mov ah, 0x0E
    mov al, 13
    int 0x10
    ret

print_hex16:
    push ax
    mov al, ah
    call print_hex8
    pop ax
    call print_hex8
    ret

print_hex8:
    push ax
    push bx

    mov bl, al

    shr al, 4
    call print_hex_nibble

    mov al, bl
    and al, 0x0F
    call print_hex_nibble

    pop bx
    pop ax
    ret

print_hex_nibble:
    cmp al, 9
    jbe .digit
    add al, 'A' - 10
    jmp .out
.digit:
    add al, '0'
.out:
    mov ah, 0x0E
    int 0x10
    ret


disk_error:
    mov si, 0x7CD7
    call 0x7CA0
    .done:
    hlt
    jmp .done

printtimes:

    cmp dx, 0
    je .done
    dec dx
    lodsb
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x02
    int 0x10
    jmp printtimes
    .done:
        ret

times (512*3) - ($-$$) db 0
