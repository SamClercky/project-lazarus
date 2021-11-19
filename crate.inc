GLOBAL Crate_update:PROC,\
    Crate_constructor:PROC,\
    Crate_init:PROC,\
    Crate_spawn_new_crate:PROC

;; needs to be multiple of 8, because the maps are in groups of 1 byte (8 bits)
CRATES_MAX_COUNT  equ 16

; vim: set ft=asm :
