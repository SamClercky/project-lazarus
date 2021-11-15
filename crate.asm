ideal
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "crate.inc"
include "drawer.inc"
include "physics.inc"
include "utils.inc"

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
    call Utils_get_next_active_index, OFFSET crates_active, CRATES_MAX_COUNT
    cmp eax, -1
    je @@return ;; check if not full and fail silently
    ;; set active
    call Utils_set_active, OFFSET crates_active, eax, 1
    ;; get new active crate
    call Utils_get_if_active, OFFSET crates_active, OFFSET crates_objects, eax

 ;   mov edi, OFFSET crates_objects
 ;   mov edi, [edi + 4*eax]
   
    ;; making crate spawn on same x-coordinate as player
    mov edi, eax ; destination pointer with active crate in eax
    xor eax, eax
    mov esi, [@@player_ptr]
    mov ax, [(Drawable PTR esi).x]
    mov [(Drawable PTR edi).x], ax
    ;add new crate to physics
    call Physics_add_dynamic, edi

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
    USES esi, ecx, eax

;; call Crate_spawn_new_crate --> called from Player_update

;; updating active crates
    mov ecx, CRATES_MAX_COUNT
@@loop_crates:
    push ecx
    dec ecx ; ecx in [0-len)

    call Utils_get_if_active, OFFSET crates_active, OFFSET crates_objects, ecx
    test eax, eax ; test if active
    jz @@end_crates ; if NULL -> not active
    
    ;; update current crate
    mov esi, eax ; PTR currently in eax
    call Drawer_draw, esi
    call Physics_apply_gravity_with_collision, esi, 1

@@end_crates:
    pop ecx
    loop @@loop_crates
   

    ret
ENDP

DATASEG
spawn_crate_timer dd 0
;crate1 Drawable <120,10,CRATE_WIDTH,CRATE_HEIGHT,offset crateSprite>
;crate2 Drawable <120,10,CRATE_WIDTH,CRATE_HEIGHT,offset crateSprite>
crateSprite db 3000 DUP(3Fh)
crates_active  db CRATES_MAX_COUNT/8  DUP(0)

UDATASEG

crates_objects  Drawable CRATES_MAX_COUNT  DUP(<120,10,CRATE_WIDTH,CRATE_HEIGHT,offset crateSprite>)

end
