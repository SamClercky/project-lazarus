GLOBAL Drawer_bg:PROC,\
    disable_video:PROC,\
    enable_video:PROC,\
    Drawer_draw:PROC,\
    Drawer_update:PROC

STRUC Drawable
    x        dw 0
    y        dw 0
    width    dw 0
    height   dw 0
    data_ptr dd 0
ENDS
; vim: set ft=asm :
