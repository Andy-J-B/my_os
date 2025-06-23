; org is a Directive
; gives a clue to assembler that will affect how program gets compiled.
; Not translated to machine compiled
; assembler specific (different assemblers = different directives)
org 0x7c00

; When an x86-compatible CPU powers on (even modern 64-bit ones), it starts in Real Mode, which is 16-bit, legacy-compatible with the original 8086 processor.
bits 16

; To print new line you need both line feed and the char to return chars
%define ENDL 0x0D, 0x0A

;
; FAT12 header
; 
jmp short start
nop

bdb_oem:                    db 'MSWIN4.1'           ; 8 bytes
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880                 ; 2880 * 512 = 1.44MB
bdb_media_descriptor_type:  db 0F0h                 ; F0 = 3.5" floppy disk
bdb_sectors_per_fat:        dw 9                    ; 9 sectors/fat
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0

; extended boot record
ebr_drive_number:           db 0                    ; 0x00 floppy, 0x80 hdd, useless
                            db 0                    ; reserved
ebr_signature:              db 29h
ebr_volume_id:              db 12h, 34h, 56h, 78h   ; serial number, value doesn't matter
ebr_volume_label:           db 'NANOBYTE OS'        ; 11 bytes, padded with spaces
ebr_system_id:              db 'FAT12   '           ; 8 bytes

;
; Code goes here
;

start:
    jmp main

; getchar
; Gets input from keyboard
; Params :
;   - ds:di points to where to store input
getchar:
    ; save registers we will modify
    push ax
    push ds
    pop es

.getchar_loop:
    ; Call get input from keyboard
    mov ah, 0x00 
    int 0x16

    ; Check if enter
    cmp al, 0x0d
    je .getchar_done

    ; Add to buffer
    stosb

    jmp .getchar_loop

.getchar_done:
    ; Put end of string null terminator
    mov byte [di], 0
    push es
    pop ds
    pop ax
    ret

    
; puts
; Prints a string to the screen.
; Params : 
;   - ds:si points to string
puts:
    ; save registers we will modify
    push si
    push ax

.puts_loop:
    ; LODSB, LODSW, LODSD
    ; instructions that load a Byte/Word/Double-word from DS:SI into AL/AX/EAX, then increments SI by number of bytes loaded
    lodsb 

    ; OR source, dest
    ; performs bitwise OR btwn source and dest, stores result in dest
    ; ORing itself won't modify value but the flags in the flags register, such as Zero Flag if result is zero
    or al, al
    ; if the char is zero, zero flag is set

    ; JZ dest
    ; Jumps to dest if zero flag is set
    jz .puts_done

    mov ah, 0x0e
    int 0x10


    jmp .puts_loop

.puts_done:
    pop ax
    pop si
    ret

main: 
    ; setup data segments
    ; Since we can't make a const directly to a segment register we need to write to a intermediary register
    mov ax, 0
    mov dx, ax
    mov es, ax

    ; setup stack
    mov ss, ax
    mov sp, 0x7C00

    ; print message
    mov si, msg_hello

    mov ds, ax

    ; Call the function
    call puts

    ; print intro
    mov si, msg_intro
    mov ds, ax
    call puts

    ; set di
    mov di, buffer

    ; Call getchar
    call getchar

    ; print what we got as input
    mov si, buffer
    call puts

    ; For now, we only want to know if bios loads correctly
    ; HLT stops cpu from executing
    hlt
    
.halt:
    jmp .halt

;
; Disk routines
;

;
; Converts LBA address to CHS address
; Params
;   - ax : LBA address
; Returns :
;   - cx (bits 0-5) : sector number
;   - cx (bits 6-15) : cylinder
;   - dh : head
;

lbs_to_chs_start:
    push ax
    push dx ; We can't push 8 bit registers to stack

lbs_to_chs:
    ; Start by dividing the LBA in ax by num_of_sectors_per_track
    ; Reset dx
    xor dx, dx
    div word [bdb_sectors_per_track] ; ax = LBA / SectorsPerTrack
                                     ; dx = LBA % SectorsPerTrack

    ; 
    inc dx                           ; dx = (LBA % SectorsPerTrack + 1) = sector
    mov cx, dx                       ; cx = sector

    ; Next find heads per cylinder
    ; ax = cylinder
    ; dx = head
    xor dx, dx                       ; dx = 0
    div word [bdb_heads]             ; ax = (LBA / SectorsPerTrack) / Heads = cylinder
                                     ; dx = (LBA / SectorsPerTrack) % Heads = head
    
    ; Shuffle registers to fix return conditions
    ; Remainder → DX = Head
        ; Which means DL = Head (since DX is 16 bits, DL is low 8 bits)

    mov dh, dl                       ; dh = head
    mov ch, al                       ; ch = cylinder (lower 8 bits)
    shl ah, 6
    or cl, ah                        ; put upper 2 bits of cylinder

lbs_to_chs_end:
    pop ax
    mov dl, al
    pop ax ; only restore dl
    ret
    

;

; text to print
msg_hello: db "Hello World. Welcome to Andy's Operating System!", ENDL, 0

msg_intro: db "AndyOS v0.1 - A Simple Operating System by Andy", 0x0D, 0x0A
           db "----------------------------------------------", 0x0D, 0x0A
           db "Boot successful. Initializing kernel services...", 0x0D, 0x0A
           db "Type 'help' to get started.", 0x0D, 0x0A, 0


; Make a buffer
buffer: times 16 db 0
times 510-($-$$) db 0
; critical in bootloader development. It's NASM syntax used to pad your boot sector to the required 512 bytes.
; $-$$ gives the size of our program so far in bytes

dw 0AA55h
; define word
; Because the BIOS (or VM BIOS) expects the last two bytes of the first sector (512 bytes) on a bootable disk to be the boot signature:
