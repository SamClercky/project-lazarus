GLOBAL Crate_update:PROC,\
    Crate_reset:PROC,\
    Crate_constructor:PROC,\
    Crate_init:PROC,\
    Crate_spawn_new_crate:PROC,\
    Crate_check_squished:PROC,\
    Crate_remove:PROC

;; needs to be multiple of 8, because the maps are in groups of 1 byte (8 bits)
CRATES_MAX_COUNT  equ 64

; vim: set ft=asm :
