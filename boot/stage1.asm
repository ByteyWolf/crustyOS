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
    mov dx, [0x7C11]  ; max root entries
    mov [numsectorsperfat], ax
    mov [numfats], bl
    mov [numreserved], cx
    mov [nummaxrootentries], dx

    mov ax, dx
    mov bx, 32              ; bytes per entry
    mul bx                  ; AX = total bytes for root
    mov bx, 512             ; bytes per sector
    cwd                     ; DX:AX for division
    div bx                  ; AX = number of root sectors
    mov [rootsectors], ax

    mov si, 0x7CE9
    call 0x7CA0

    ; print sectors per fat
    mov ax, [numsectorsperfat]
    call print_hex16
    mov ah, 0x0E
    mov al, 0x20
    int 0x10

    mov al, [numfats]
    call print_hex8
    mov ah, 0x0E
    mov al, 0x20
    int 0x10

    mov ax, [numreserved]
    call print_hex16

    call newline

    mov ax, [numsectorsperfat]
    mov bx, [numfats]
    mov cx, [numreserved]


    mul bx
    add ax, cx

    ; convert into chs!!
    call lba2chs



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
    mov cx, ax
    call print_hex16
    call newline
    call newline

    cmp cx, 0
    je .notfound

    mov ax, [si+28]
    push ax

    mov ax, [numfats]
    mul word [numsectorsperfat]
    add ax, [numreserved]
    add ax, [rootsectors]
    mov bx, ax

    mov ax, cx
    sub ax, 2
    add ax, bx

    call lba2chs


    xor ax, ax
    mov es, ax
    mov dl, [driveid]
    mov bx, 0x9000
    mov ah, 2
    mov al, 1


    int 0x13

    jc disk_error

    mov si, 0x9000
    pop dx
    call printtimes

    call newline

    hlt
    jmp $




driveid db 0
fileid db 0
numheads dw 0
numsectorspertrack dw 0

numsectorsperfat dw 0
numfats db 0
numreserved dw 0
nummaxrootentries dw 0

rootsectors dw 0

lba2chs:
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
    ret

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
