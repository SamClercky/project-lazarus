GLOBAL Physics_apply_gravity:PROC,\
    Physics_apply_gravity_with_collision:PROC,\
    Physics_check_colliding_loop:PROC,\
    Physics_check_colliding:PROC,\
    Physics_is_colliding:PROC,\
    Physics_point_in_obj:PROC,\
    Physics_add_static:PROC,\
    Physics_del_static:PROC,\
    Physics_add_dynamic:PROC,\
    Physics_del_dynamic:PROC,\
    Physics_add_moving:PROC,\
    Physics_del_moving:PROC,\
    Physics_reset:PROC

;; needs to be multiple of 8, because the maps are in groups of 1 byte (8 bits)
MOVING_OBJECT_MAX_COUNT  equ 8
STATIC_OBJECT_MAX_COUNT  equ 8
DYNAMIC_OBJECT_MAX_COUNT equ 64

;; directions that can be tested
DIR_UP     equ 0
DIR_LEFT   equ 1
DIR_BOTTOM equ 2
DIR_RIGHT  equ 4
DIR_MIDDLE equ 8

MOVING_OBJECT  equ 1 ; objects that move (playing + falling crates)
STATIC_OBJECT  equ 2 ; objects that do not move
DYNAMIC_OBJECT equ 4 ; objects that move but can change (fallen crates)
; vim: set ft=asm :
