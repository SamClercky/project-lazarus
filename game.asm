ideal
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "game.inc"
include "player.inc"
include "crate.inc"
include "physics.inc"
include "drawer.inc"
include "utils.inc"

CODESEG

PROC Game_init
    ;; fill buffer with non random data -> less glitch at the start
    call Drawer_bg
    call Drawer_update

    ;; init players and crates
    call Player_init
    call Crate_init

    ;; init physics
    call Physics_add_static, OFFSET wallL
    call Physics_add_static, OFFSET wallR
    call Physics_add_static, OFFSET wallB

    ret
ENDP

PROC Game_update
    ;; drawing
    ;;; background
    call Drawer_bg

    ;;; walls
    call Drawer_draw, OFFSET wallL
    call Drawer_draw, OFFSET wallR
    call Drawer_draw, OFFSET wallB

    ;;; entities
    call Crate_draw
    call Player_draw

    ;; update screen
    call Drawer_update
    
    ;; handle game input and return eax to see if the game loop needs to end
    call Game_handle_input

    ret
ENDP

;; eax = 0 -> everything ok, eax = 1 -> end game
;; scan codes: https://www.fountainware.com/EXPL/bios_key_codes.htm
PROC Game_handle_input
    mov ah, 01h
    int 16h
    jz @@no_key_press ; no new input -> do not process

    ;; read input
    mov ah, 00h
    int 16h

    ;; handle input ASCII al and BIOS in ah
    cmp al, 1Bh
    je @@stop_game

    ;; pass input to other functions
    and eax, 0FFFFh
    call Player_handle_input, eax

    jmp @@no_key_press ; keypress has been handled

@@stop_game:
    mov eax, 1
    jmp @@return

@@no_key_press:
    xor eax, eax

@@return:
    ret
ENDP

DATASEG
wallL Drawable <0,0,10,200,OFFSET wallLSprite>
wallLSprite db 2000 DUP(28h)
wallB Drawable <10,190,300,10,OFFSET wallBSprite>
wallBSprite db 3000 DUP(28h)
wallR Drawable <310,0,10,200,OFFSET wallRSprite>
wallRSprite db 2000 DUP(28h)

end
