ideal
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "player.inc"

include "drawer.inc"

CODESEG

PROC Player_draw
    USES eax, esi
    mov esi, offset player
    call Drawer_draw, offset player

    mov ax, [(Drawable PTR esi).x]
    inc ax
    mov [(Drawable PTR esi).x], ax

    ret
ENDP

DATASEG
player Drawable <0,0,10,20,offset playerData>
playerData db 100 DUP(0Ch)

end
