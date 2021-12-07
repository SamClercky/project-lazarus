ideal
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "player.inc"

include "crate.inc"
include "drawer.inc"
include "physics.inc"
include "utils.inc"

PLAYER_WIDTH equ 20
PLAYER_HEIGHT equ 20
PLAYER_X_START equ 20
PLAYER_Y_START equ 120

PLAYER_STEP equ 20
PLAYER_INPUT_DELAY equ 10 ; make sure that moves are at least INPUT_DELAY apart

CODESEG

;; inits player and adds it to the physics engine
PROC Player_init
    ;; load sprite data
    call Utils_read_file, OFFSET player_filename, OFFSET playerData, PLAYER_WIDTH*PLAYER_HEIGHT
    call Utils_read_file, OFFSET player_scared_filename, OFFSET playerScaredData, PLAYER_WIDTH*PLAYER_HEIGHT

    ;; setup player
    call Player_reset

    ret
ENDP

;; sets and resets the player
PROC Player_reset
    USES esi

    call Physics_add_dynamic, OFFSET player

    ;; reset player
    mov esi, OFFSET player
    mov [(Drawable PTR esi).x], PLAYER_X_START
    mov [(Drawable PTR esi).y], PLAYER_Y_START

    ;; reset falling crate position
    mov [player_scared_x], 0

    ret

ENDP

PROC Player_update
    USES eax, esi

    mov esi, offset player
    
    ;; update sprite if player scared
    movzx eax, [(Drawable PTR esi).x]
    cmp ax, [player_scared_x]
    jne @@player_not_scared
    mov [(Drawable PTR esi).data_ptr], offset playerScaredData
    jmp @@player_draw
@@player_not_scared:
    mov [(Drawable PTR esi).data_ptr], offset playerData
@@player_draw:
    call Drawer_draw, esi

    call Physics_apply_gravity_with_collision, esi, 1
    
    call Crate_spawn_new_crate, OFFSET player  ;; crates need to spawn on player x-coordinate (depending on time/amount of updates)
    test ax, ax
    jz @@no_player_scared_update

    mov [player_scared_x], ax ; store x of falling crate

@@no_player_scared_update:

    ;; update timer
    mov al, [player_delay_timer]
    test al, al 
    jz @@end_timer ;; if not 0 dec timer
    dec al
    mov [player_delay_timer], al
@@end_timer:

    ret
ENDP

;; Player moves with collision detection
;; If there is no collision left/right -> player moves
;; If there is collision left/right -> check up -> player jumps
PROC Player_collision_movement
    ARG @@direction:dword
    USES eax, ebx, esi, edi

    mov esi, OFFSET player
    mov eax, [@@direction]
    ;; test left/right
    call Physics_check_colliding, esi, eax
    test eax, eax
    
    mov edi, eax ;; save eax

    jz @@move_left_right

    ;; test one up
    sub [(Drawable PTR esi).y], PLAYER_STEP ;; move up

    call Physics_check_colliding, esi, [@@direction]
    test eax, eax
    jz @@move_left_right

    ;; undo jump
    add [(Drawable PTR esi).y], PLAYER_STEP ;; move down
    jmp @@return

@@move_left_right:
    cmp [@@direction], DIR_LEFT
    je @@left
    jmp @@right

@@left:
    sub [(Drawable PTR esi).x], PLAYER_STEP
    jmp @@return

@@right:
    add [(Drawable PTR esi).x], PLAYER_STEP
    jmp @@return

@@return:
    ret
ENDP

PROC Player_handle_input
    ARG @@input_ascii:dword
    USES eax, ebx, edx, esi

    ;; test if movement is allowed
    mov al, [player_delay_timer]
    test al, al
    jnz @@return ; may not move yet
    mov [player_delay_timer], PLAYER_INPUT_DELAY ; reset timer and continue

    mov esi, OFFSET player
    mov eax, [@@input_ascii]

    cmp eax, 4Bh
    je @@left

    cmp eax, 4Dh
    je @@right

    jmp @@return ; ignore invalid keys
    
@@left:
    call Player_collision_movement, DIR_LEFT
    jmp @@return

@@right:
    call Player_collision_movement, DIR_RIGHT

@@return:
    ret
ENDP

PROC Player_check_dead
    
    call Physics_check_colliding, OFFSET player, DIR_UP
    test eax, eax
    jz @@return
    
    ;; game need to end, because player got squished
    mov eax, 1 ;game loop stops when eax is 1 in main.asm after Game_update

@@return:
    ret
ENDP

DATASEG

player Drawable <PLAYER_X_START,PLAYER_Y_START,PLAYER_WIDTH,PLAYER_HEIGHT,offset playerData>
player_filename db "sprites\player.b", 0
player_scared_filename db "sprites\playsq.b", 0

player_delay_timer db 0
player_scared_x dw 0 ; x of falling crate and used to show scared anim

UDATASEG
playerData db PLAYER_WIDTH*PLAYER_HEIGHT DUP(?)
playerScaredData db PLAYER_WIDTH*PLAYER_HEIGHT DUP(?)

end
