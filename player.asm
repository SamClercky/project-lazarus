ideal
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "player.inc"

include "drawer.inc"
include "physics.inc"

PLAYER_WIDTH equ 10
PLAYER_HEIGHT equ 10

CODESEG

;; inits player and adds it to the physics engine
PROC Player_init
    call Physics_add_dynamic, OFFSET player

    ret
ENDP

PROC Player_draw
    USES eax, esi
    mov esi, offset player
    call Drawer_draw, esi

    call Physics_apply_gravity_with_collision, esi, 1

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
    call Physics_check_colliding, esi, DIR_LEFT
    test eax, eax
    jnz @@return
    sub [(Drawable PTR esi).x], 10
    jmp @@return

@@right:
    call Physics_check_colliding, esi, DIR_RIGHT
    test eax, eax
    jnz @@return
    add [(Drawable PTR esi).x], 10

@@return:
    ret
ENDP

DATASEG
player Drawable <50,20,PLAYER_WIDTH,PLAYER_HEIGHT,offset playerData>
playerData db PLAYER_WIDTH*PLAYER_HEIGHT DUP(0Ch)

end
