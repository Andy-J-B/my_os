; org is a Directive
; gives a clue to assembler that will affect how program gets compiled.
; Not translated to machine compiled
; assembler specific (different assemblers = different directives)
org 0x7c00

; When an x86-compatible CPU powers on (even modern 64-bit ones), it starts in Real Mode, which is 16-bit, legacy-compatible with the original 8086 processor.
bits 16

; To print new line you need both line feed and the char to return chars
%define ENDL 0x0D, 0x0A

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
