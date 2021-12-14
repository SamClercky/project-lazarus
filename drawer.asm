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
    ARG @@drawer_sprite_ptr:dword
    USES eax, ecx, edi

    ;; basic temp impl for testing
    ;; draw white pixels to screen (1 at a time)
    
    mov edi, offset back_buffer
    mov ecx, WINDOW_WIDTH*WINDOW_HEIGHT/4
    mov esi, [@@drawer_sprite_ptr]
    rep movsd
    
    ret
ENDP

PROC Drawer_draw_txt
    ARG @@x:dword, @@y:dword, @@str_ptr:dword
    USES eax, ebx, ecx, edx, esi

    mov esi, [@@str_ptr]

    mov ax, 1003h
    mov bx, 0000h
    int 10h ; disable blinking

    ;; start pos
    mov eax, [@@x]
    mov dl, al
    mov eax, [@@y]
    mov dh, al

    mov ecx, 1

@@next_print_char:

    ;; set cursor
    mov ah, 02h
    mov bh, 00h
    int 10h

    inc dl ; move cursor

    mov al, [esi] ; next char
    cmp al, '$' ; check if end is near
    je @@return

    inc esi ; inc pointer

    mov ah, 09h
    mov bx, 0007h
    int 10h
    jmp @@next_print_char

@@return:
    ret 
ENDP

;; Draws a 2 digit number to the screen
PROC Draw_number
    ARG @@x:dword, @@y:dword, @@number:dword
    USES eax, ebx, ecx, edx, esi

    xor edx, edx
    mov eax, [@@number]
    mov ebx, 10

    div ebx

    add eax, '0'
    add edx, '0'

    ;; Create string in memory
    mov [BYTE OFFSET number_string_buffer    ], al
    mov [BYTE OFFSET number_string_buffer + 1], dl
    mov [BYTE OFFSET number_string_buffer + 2], '$'

    ;; draw string
    call Drawer_draw_txt, [@@x], [@@y], OFFSET number_string_buffer

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
    mov al, [esi + 4*ebx]
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
    ;rep movsb
@@width_write:
    mov al, [esi]
    cmp al, 1 ; transparancy color
    je @@end_width_write ; conditionally move byte if not transparant
    mov [edi], al
@@end_width_write:
    inc edi ; setup for next round
    inc esi
    loop @@width_write

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
color_filename db "sprites\palet.b", 0

UDATASEG
;; Writing to back buffer for less flicker
back_buffer db WINDOW_WIDTH*WINDOW_HEIGHT DUP(?)
color_palette db 256*4 DUP(?)

number_string_buffer db 3 DUP(?)

end
