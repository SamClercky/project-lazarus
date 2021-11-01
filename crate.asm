ideal
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "crate.inc"
include "drawer.inc"
include "physics.inc"

CODESEG

PROC Crate_init
    call Physics_add_static, OFFSET crate1

    ret
ENDP

PROC Crate_draw
    USES esi

    mov esi, offset crate1
    call Drawer_draw, esi

    ret
ENDP

DATASEG
crate1 Drawable <20,150,100,10,offset crateSprite>
crateSprite db 3000 DUP(3Fh)

end
