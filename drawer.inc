GLOBAL Drawer_bg:PROC,\
    disable_video:PROC,\
    enable_video:PROC,\
    Drawer_draw:PROC,\
    Drawer_update:PROC,\
    Drawer_draw_txt:PROC,\
    Draw_number:PROC

STRUC Drawable
    x        dw 0
    y        dw 0
    width    dw 0
    height   dw 0
    data_ptr dd 0
ENDS

DRAWABLE_BYTES equ 12

; vim: set ft=asm :
