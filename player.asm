ideal
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "player.inc"

include "drawer.inc"
include "physics.inc"

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

DATASEG
player Drawable <50,0,10,20,offset playerData>
playerData db 100 DUP(0Ch)

end
