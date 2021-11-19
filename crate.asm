ideal
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "crate.inc"
include "drawer.inc"
include "physics.inc"
include "utils.inc"

CRATE_WIDTH equ 20
CRATE_HEIGHT equ 20
CRATE_Y_START equ 0


CODESEG

PROC Crate_init


    ret
ENDP

PROC Crate_spawn_new_crate
    ARG @@player_ptr:dword
    USES eax, esi, edi, ebx

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

    ;; get new active crate offset 
    mov ebx, DRAWABLE_BYTES ;drawable is 12 bytes
    mul ebx ;DRAWABLE_BYTES*eax(=index)
    mov edi, OFFSET crates_objects
    add edi, eax
    
    ;; making new crate spawn on same x-coordinate as player
    xor eax, eax
    mov esi, [@@player_ptr]
    mov ax, [(Drawable PTR esi).x]
    mov [(Drawable PTR edi).x], ax
    mov [(Drawable PTR edi).y], CRATE_Y_START
    mov [(Drawable PTR edi).width], CRATE_WIDTH
    mov [(Drawable PTR edi).height], CRATE_HEIGHT
    mov [(Drawable PTR edi).data_ptr], OFFSET crateSprite
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
   USES esi, ecx, eax, ebx

;; call Crate_spawn_new_crate --> called from Player_update

;; updating active crates
    mov ecx, CRATES_MAX_COUNT
@@loop_crates:
    push ecx
    dec ecx ; ecx in [0-len)

    call Utils_is_active, OFFSET crates_active, ecx
    test eax, eax ; test if active
    jz @@end_crates ; if NULL -> not active
    
    ;; update current crate
    mov esi, OFFSET crates_objects
    mov ebx, DRAWABLE_BYTES ;drawable is 12 bytes
    mov eax, ecx
    mul ebx
    add esi, eax

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
crateSprite db 3000 DUP(3Fh)
crates_active  db CRATES_MAX_COUNT/8 DUP(0)

UDATASEG

crates_objects Drawable CRATES_MAX_COUNT DUP(?)

end
