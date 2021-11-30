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

WALL_SIZE equ 20

PROC Game_init
    ;; init players and crates
    call Player_init
    call Crate_init

    ;; load walls
    call Utils_read_file, OFFSET wallFileName, OFFSET wallSprite, 400

    ;; fill buffer with non random data -> less glitch at the start
    call Drawer_bg
    call Drawer_update

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
    ;call Drawer_draw, OFFSET wallL
    ;call Drawer_draw, OFFSET wallR
    ;call Drawer_draw, OFFSET wallB
    call Game_draw_walls, 0, 1, 0, 10
    call Game_draw_walls, 20, 15, 180, 10
    call Game_draw_walls, 300, 1, 0, 10

    ;; entities
    call Player_update
    call Crate_update
    ;;; make new crates --> in Player_update


    ;; update screen
    call Drawer_update
    
    ;; handle game input and return eax to see if the game loop needs to end
    call Game_handle_input
    cmp eax, 1 ; if Esc is pressed the program ends
    je @@return

    call Player_check_dead

@@return:
    ret
ENDP

;; Draws the walls by using wallSprite and placing it
;; on the place where we want it to be placed
PROC Game_draw_walls
    ARG @@start_x:dword, @@times_x:dword, @@start_y:dword, @@times_y:dword
    USES eax, ecx, esi

    mov esi, OFFSET wallDrawable
    mov eax, [@@start_y]
    mov [(Drawable PTR esi).y], ax

    mov ecx, [@@times_y]
@@loop_y:

    ;; (re)set x coord
    mov eax, [@@start_x]
    mov [(Drawable PTR esi).x], ax

    push ecx
    mov ecx, [@@times_x]
@@loop_x:
    
    ;; draw on screen
    call Drawer_draw, esi

    ;; update x
    add [(Drawable PTR esi).x], WALL_SIZE

    loop @@loop_x
    
    ;; update y
    add [(Drawable PTR esi).y], WALL_SIZE

    pop ecx
    loop @@loop_y

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

;; are there only for the physics
wallL Drawable <0,0,20,200,?>
wallB Drawable <10,180,300,20,?>
wallR Drawable <300,0,20,200,?>

;; sprites for the wall that is loaded on startup
wallFileName db "sprites\wall.b", 0
wallDrawable Drawable <0,0,20,20,OFFSET wallSprite>

UDATASEG
wallSprite db 400 DUP(?)

end
