ideal
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "drawer.inc"

WINDOW_BUFFER equ 0A0000h
WINDOW_WIDTH equ 320
WINDOW_HEIGHT equ 200

CODESEG
PROC enable_video
    USES eax

    mov ax, 0013h ; video mode -> 13h
    int 10h ; send to BIOS

    ret
ENDP

PROC disable_video
    USES eax

    mov ax, 0003h ; video mode -> 03h
    int 10h ; send to BIOS

    ret
ENDP

;; Draws background
PROC Drawer_bg
    USES eax, ecx, edi

    ;; basic temp impl for testing
    ;; draw white pixels to screen (1 at a time)
    
    mov edi, WINDOW_BUFFER
    mov ecx, WINDOW_WIDTH*WINDOW_HEIGHT
    mov al, 0Fh ; color
    rep stosb
    
    ret
ENDP

end

