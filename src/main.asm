; org is a Directive
; gives a clue to assembler that will affect how program gets compiled.
; Not translated to machine compiled
; assembler specific (different assemblers = different directives)
org 0x7c00

; When an x86-compatible CPU powers on (even modern 64-bit ones), it starts in Real Mode, which is 16-bit, legacy-compatible with the original 8086 processor.
bits 16

main: 
    ; For now, we only want to know if bios loads correctly
    ; HLT stops cpu from executing
    hlt
    
.halt:
    jmp .halt

times 510-($-$$) db 0
; critical in bootloader development. It's NASM syntax used to pad your boot sector to the required 512 bytes.
; $-$$ gives the size of our program so far in bytes

dw 0AA55h
; define word
; Because the BIOS (or VM BIOS) expects the last two bytes of the first sector (512 bytes) on a bootable disk to be the boot signature:
