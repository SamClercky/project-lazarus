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

;; Draws a drawable on screen at the given coords
PROC Drawer_draw
    ARG @@drawable_ptr:dword
    USES ecx, eax, ebx, edx, edi, esi
    
    mov ebx, [@@drawable_ptr] ; deref in ebx

    mov cx, [(Drawable PTR ebx).height]
@@loop_height:
    ;; check if still on screen
    mov ax, [(Drawable PTR ebx).y]
    add ax, [(Drawable PTR ebx).height]
    sub ax, cx
    cmp ax, WINDOW_HEIGHT
    jge @@return ; if no longer on screen, end drawing

    ;; calc source in relative data (height)
    mov edx, WINDOW_WIDTH
    mul edx ; mul line number (eax) with width
    mov esi, eax ; result of mul in edx:eax

    push cx ; remember for next time
    
    mov cx, [(Drawable PTR ebx).width]
    mov ax, WINDOW_WIDTH
    sub ax, [(Drawable PTR ebx).x]
    call Min, ecx, eax
    mov ecx, eax ; take the smallest and put it in ecx
    
    ;; calc source based on width
    add si, [(Drawable PTR ebx).x]

    ;; copy rel to dest
    mov edi, esi

    ;; make absolute
    add esi, [(Drawable PTR ebx).data_ptr]
    add edi, WINDOW_BUFFER

    ;; draw 1 line
    rep movsb
    
    pop cx ; restore ecx (height)
    loop @@loop_height ; next line

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

end

