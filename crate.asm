ideal
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "crate.inc"
include "drawer.inc"
include "physics.inc"

CRATE_WIDTH equ 10
CRATE_HEIGHT equ 10


CODESEG

PROC Crate_init

   ; call Physics_add_dynamic, OFFSET crate3

    ret
ENDP

PROC Crate_spawn_new_crate
    ARG @@player_ptr:dword
    USES eax, esi, edi

    xor eax, eax
    ;; check timer --> create new one or not
    mov eax, [spawn_crate_timer]
    cmp eax, 200     ;; 200 indicator for time, after how many Game_updates
    jl @@update_timer

    ;; make new crate
    xor eax, eax
    mov esi, [@@player_ptr]
    mov edi, OFFSET crate3
    mov ax, [(Drawable PTR esi).x]
    mov [(Drawable PTR edi).x], ax

    call Physics_add_dynamic, OFFSET crate3
    ;;reset timer
    mov [spawn_crate_timer], 0
    jmp @@return
    
@@update_timer:
    ;;update timer
    xor eax, eax
    mov eax, [spawn_crate_timer]
    inc eax
    mov [spawn_crate_timer], eax

@@return:
    ret
ENDP

PROC Crate_update
    USES esi

;; call Crate_spawn_new_crate --> called from Player_update

    mov esi, OFFSET crate3
    call Drawer_draw, esi

    call Physics_apply_gravity_with_collision, esi, 1
   

    ret
ENDP

DATASEG
;;crate1 Drawable <20,150,100,10,offset crateSprite>
;;crate2 Drawable <60,140,10,10,offset crateSprite>
spawn_crate_timer dd 0
crate3 Drawable <120,10,10,10,offset crateSprite>
crateSprite db 3000 DUP(3Fh)


end
