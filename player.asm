ideal
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "player.inc"

include "drawer.inc"
include "physics.inc"

CODESEG

PROC Player_draw
    USES eax, esi
    mov esi, offset player
    call Drawer_draw, esi

    call Physics_apply_gravity, esi, 1

    ret
ENDP

DATASEG
player Drawable <50,0,10,20,offset playerData>
playerData db 100 DUP(0Ch)

end
