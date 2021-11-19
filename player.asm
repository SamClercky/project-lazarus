ideal
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "player.inc"

include "crate.inc"
include "drawer.inc"
include "physics.inc"

PLAYER_WIDTH equ 20
PLAYER_HEIGHT equ 20
PLAYER_X_START equ 20
PLAYER_Y_START equ 120

PLAYER_STEP equ 20

CODESEG

;; inits player and adds it to the physics engine
PROC Player_init
    call Physics_add_dynamic, OFFSET player

    ret
ENDP

PROC Player_update
    USES eax, esi

    mov esi, offset player
    call Drawer_draw, esi

    call Physics_apply_gravity_with_collision, esi, 1
    
    call Crate_spawn_new_crate, OFFSET player  ;; crates need to spawn on player x-coordinate (depending on time/amount of updates)

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

    mov esi, OFFSET player
    mov eax, [@@input_ascii]

    cmp eax, 4B00h
    je @@left

    cmp eax, 4D00h
    je @@right

    jmp @@return
    
@@left:
    call Player_collision_movement, DIR_LEFT
    jmp @@return

@@right:
    call Player_collision_movement, DIR_RIGHT

@@return:
    ret
ENDP

DATASEG
player Drawable <PLAYER_X_START,PLAYER_Y_START,PLAYER_WIDTH,PLAYER_HEIGHT,offset playerData>
playerData db PLAYER_WIDTH*PLAYER_HEIGHT DUP(0Ch)

end
