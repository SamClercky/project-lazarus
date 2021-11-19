ideal
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "drawer.inc"
include "utils.inc"

WINDOW_BUFFER equ 0A0000h
WINDOW_WIDTH equ 320
WINDOW_HEIGHT equ 200

CODESEG
PROC enable_video
    USES eax

    mov ax, 0013h ; video mode -> 13h
    int 10h ; send to BIOS

    call Drawer_load_colorpalette

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
    
    mov edi, offset back_buffer
    mov ecx, WINDOW_WIDTH*WINDOW_HEIGHT
    mov al, 0Fh ; color
    rep stosb
    
    ret
ENDP

PROC Drawer_load_colorpalette
    USES eax, ebx, ecx, edx, esi, edi

    mov esi, OFFSET color_palette

    call Utils_read_file, OFFSET color_filename, esi, 256*4

    ;; start writing to graphics card
    mov dx, 03C8h
    mov al, 0h
    out dx, al
    mov dx, 03C9h

    mov ecx, 256
@@loop:
    mov ebx, 256
    sub ebx, ecx

    ;; red
    mov al, [esi + 4*ebx + 2]
    out dx, al
    ;; green
    mov al, [esi + 4*ebx + 1]
    out dx, al
    ;; blue
    mov al, [esi + 4*ebx + 3]
    out dx, al

    loop @@loop

    ret
ENDP

;; Draws a drawable on screen at the given coords
PROC Drawer_draw
    ARG @@drawable_ptr:dword
    USES eax, ebx, ecx, edx, edi, esi

    mov ebx, [@@drawable_ptr]
    xor ecx, ecx
    mov cx, [(Drawable PTR ebx).height]
@@loop_height:
    push ecx
    dec ecx

    ;; absolute
    mov edi, OFFSET back_buffer

    xor eax, eax ; clean eax
    mov ax, [(Drawable PTR ebx).y]
    add ax, cx

    ;; check if in range
    cmp eax, WINDOW_HEIGHT
    jge @@end_height_loop ; row out of scope

    mov edx, WINDOW_WIDTH
    mul edx

    add edi, eax
    xor eax, eax
    mov ax, [(Drawable PTR ebx).x]
    add edi, eax
    
    ;; relative
    mov esi, [(Drawable PTR ebx).data_ptr]
    xor eax, eax
    mov ax, cx

    xor edx, edx
    mov dx, [(Drawable PTR ebx).width]
    mul edx
    add esi, eax

    ;; preferable width
    xor ecx, ecx
    mov cx, [(Drawable PTR ebx).width]
    ;; calc available width
    xor edx, edx
    mov dx, WINDOW_WIDTH
    sub dx, [(Drawable PTR ebx).x]
    ;; actual width
    call Min, ecx, edx
    mov ecx, eax
    ;; write
    REP movsb

@@end_height_loop:
    pop ecx
    loop @@loop_height

@@return:
    ret
ENDP

;; return the min of x1 and x2
PROC Min
    ARG @@x1:dword, @@x2:dword
    USES ebx

    mov eax, [@@x1]
    mov ebx, [@@x2]
    cmp eax, ebx
    jge @@greater
    jmp @@return ; eax is smaller
@@greater:
    mov eax, ebx ; ebx is smaller

@@return:
    ret
ENDP

;; updates screen
PROC Drawer_update
    USES esi, edi, ecx

    mov esi, offset back_buffer
    mov edi, WINDOW_BUFFER
    mov ecx, WINDOW_WIDTH*WINDOW_HEIGHT/4

    rep movsd

    ret
ENDP

DATASEG
color_filename db "sprites\palette.b", 0

UDATASEG
;; Writing to back buffer for less flicker
back_buffer db WINDOW_WIDTH*WINDOW_HEIGHT DUP(?)
color_palette db 256*4 DUP(?)

end
