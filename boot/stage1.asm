[BITS 16]
[ORG 0x8000]

mov si, 0x7CC0
call 0x7CA0

load_fat12:
    mov [driveid], dl

    ; we need to find out fat data first
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
    mov bx, 32
    mul bx
    mov bx, 512
    cwd
    div bx
    mov [rootsectors], ax

load_fat:
    mov ax, [numreserved]
    ;inc ax
    call lba2chs

    xor ax, ax
    mov es, ax
    mov bx, fat_buffer
    mov ah, 2
    mov al, [numsectorsperfat]
    mov dl, [driveid]
    int 0x13
    jc disk_error

find_osinit:
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
    mov bx, scratchspace
    mov ah, 2
    mov al, 1


    int 0x13

    jc disk_error

    mov si, scratchspace

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

    mov al, [numfats]
    cbw
    mul word [numsectorsperfat]
    add ax, [numreserved]
    add ax, [rootsectors]
    mov [data_lba], ax

    mov bx, osinit_buffer & 0xFFFF
    mov ax, osinit_buffer >> 4
    mov es, ax
    mov [crt_reading], bx

.load_cluster:
    cmp cx, 0xFF8
    jae .done

    mov ax, [data_lba] ;0x0024


    push cx
    mov ax, cx
    sub ax, 2
    add ax, [data_lba]
    call lba2chs
    
    mov bx, [crt_reading]
    mov ah, 2
    mov al, 1
    mov dl, [driveid]
    int 0x13
    jc disk_error
    pop cx

    add bx, 512
    mov [crt_reading], bx
    jnc .no_wrap
    mov ax, es
    add ax, 0x20
    mov es, ax
.no_wrap:
    call fat12_next_cluster
    mov cx, ax
    jmp .load_cluster
.done:
    ; so at this point we have a loaded osinit
    ; so let's start doing memory map and then
    ; we gotta switch to protected mode
    ; and jump to it
memorymap:
    xor bx, bx         
    mov ds, bx
    mov ax, fat_buffer >> 4
    mov es, ax
    xor si, si

.nextentry:
    mov ax, 0xE820
    mov dx, 0x534D
    mov cx, 20
    int 0x15
    jc memdone
    cmp eax, 0x534D4150
    jne memdone
    add si, 20
    test bx, bx
    jnz .nextentry


memdone:
    ; it's time to go into 32-bit mode and enter osinit
    xor ax, ax
    mov ds, ax
    mov es, ax

    lgdt [gdt_descriptor]
    cli
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    
    jmp 0x08:pm_entry

[BITS 32]
pm_entry:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov esp, 0x8000 ; use our stage 0 bootloader code area as stack

    mov eax, osinit_buffer
    jmp eax


[BITS 16]
fat12_next_cluster:
    mov ax, cx
    mov bx, 3
    mul bx
    shr ax, 1           ; compute offset = cluster * 3 / 2

    mov si, fat_buffer
    add si, ax          ; SI = pointer to FAT entry

    mov ax, [si]        ; read 16 bits from FAT

    test cx, 1
    jz .even
    shr ax, 4           ; odd cluster uses high 12 bits
    jmp .out
.even:
    and ax, 0x0FFF      ; even cluster uses low 12 bits
.out:
    ret


lba2chs:
    xor dx, dx
    mov bx, [numsectorspertrack]          ; sectors per track
    div bx              ; AX = temp, DX = remainder

    inc dx              ; sector = remainder + 1
    mov cl, dl          ; CL = sector

    xor dx, dx
    mov bx, [numheads]           ; heads
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

data_lba dw 0

rootsectors dw 0
fat_buffer equ 0x9000
osinit_buffer equ 0x10000

crt_reading dw 0

gdt:
    ; null descriptor
    dd 0
    dd 0

    ; code segment: base=0, limit=4GB, 0x9A, 0xCF
    dw 0xFFFF          ; limit low
    dw 0x0000          ; base low
    db 0x00            ; base mid
    db 0x9A            ; access
    db 0xCF            ; granularity + limit high
    db 0x00            ; base high

    ; data segment: base=0, limit=4GB, 0x92, 0xCF
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x92
    db 0xCF
    db 0x00

gdt_descriptor:
    dw gdt_end - gdt - 1
    dd gdt
gdt_end:


scratchspace equ $

times (512*3) - ($-$$) db 0