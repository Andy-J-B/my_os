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

;
; Prings a string to the screen.
; Params : 
;   - ds:si points to string
puts:
    ; save registers we will modify
    push si
    push ax

.loop:
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
    jz .done

    mov ah, 0x0e
    int 0x10


    jmp .loop

.done:
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

    ; Call the function
    call puts


    ; For now, we only want to know if bios loads correctly
    ; HLT stops cpu from executing
    hlt
    
.halt:
    jmp .halt

; text to print
msg_hello: db "Hello World!", ENDL, 0

times 510-($-$$) db 0
; critical in bootloader development. It's NASM syntax used to pad your boot sector to the required 512 bytes.
; $-$$ gives the size of our program so far in bytes

dw 0AA55h
; define word
; Because the BIOS (or VM BIOS) expects the last two bytes of the first sector (512 bytes) on a bootable disk to be the boot signature:
