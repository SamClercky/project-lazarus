ideal
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "player.inc"

include "drawer.inc"

CODESEG

PROC Player_draw
    mov esi, offset player
    call Drawer_draw, offset player

    inc [(Drawable PTR esi).x]
    ret
ENDP

DATASEG
player Drawable <20,100,10,10,offset playerData>
label playerData Byte
rept 100
    db 0Fh
endm

end
