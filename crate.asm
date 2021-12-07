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
    ;; load sprites

    call Utils_read_file, OFFSET crate_filename, OFFSET crateSprite, CRATE_WIDTH*CRATE_HEIGHT

    ret
ENDP

PROC Crate_constructor
    ARG @@x:dword, @@y:dword, @@width:dword, @@height:dword, @@sprite_ptr:dword
    USES eax, ebx, edi
    
     ;; make new crate
    xor eax, eax
    call Utils_get_next_active_index, OFFSET crates_active, CRATES_MAX_COUNT
    cmp eax, -1
    je @@return ;; check if not full and fail silently
    ;; set active
    call Utils_set_active, OFFSET crates_active, eax, 1

    ;; get new (active) crate offset 
    mov ebx, DRAWABLE_BYTES ;drawable is 12 bytes
    mul ebx ; DRAWABLE_BYTES*eax(=index)
    mov edi, OFFSET crates_objects
    add edi, eax
    
    ;; spawning new crate
    xor ebx, ebx
    mov ebx, [@@x]
    mov [(Drawable PTR edi).x], bx
    mov ebx, [@@y]
    mov [(Drawable PTR edi).y], bx
    mov ebx, [@@width]
    mov [(Drawable PTR edi).width], bx
    mov ebx, [@@height]
    mov [(Drawable PTR edi).height], bx
    mov ebx, [@@sprite_ptr]
    mov [(Drawable PTR edi).data_ptr], ebx
    ;; add new crate to physics
    call Physics_add_dynamic, edi

@@return:
    ret
ENDP

;; create a new falling crate, and when it falls returns in 
;; eax the x position otherwise 0
PROC Crate_spawn_new_crate
    ARG @@player_ptr:dword
    USES esi

    ;; check timer --> create new one or not
    movzx eax, [spawn_crate_timer]
    cmp eax, 120     ;; indicator for time, after how many Game_updates
    jl @@update_timer

    ;; make new crate
    mov esi, [@@player_ptr]
    movzx eax, [(Drawable PTR esi).x] ;; store x in eax
    call Crate_constructor, eax, CRATE_Y_START, CRATE_WIDTH, CRATE_HEIGHT, OFFSET crateSprite

    ;;reset timer
    mov [spawn_crate_timer], 0
    jmp @@return
    
@@update_timer:
    ;;update timer
    xor eax, eax
    mov al, [spawn_crate_timer]
    inc al
    mov [spawn_crate_timer], al

    xor eax, eax ; no new crate added

@@return:
    ret
ENDP

PROC Crate_update
   USES esi, ecx, eax, ebx, edx

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
    mul ebx ; edx:eax
    add esi, eax

    call Drawer_draw, esi
    call Physics_apply_gravity_with_collision, esi, 1

@@end_crates:
    pop ecx
    loop @@loop_crates
   
    ret
ENDP

PROC Crate_reset
    USES eax, ecx, edi

    mov [spawn_crate_timer], 0
    mov ecx, CRATES_MAX_COUNT/8
    mov edi, OFFSET crates_active
    xor eax, eax
    rep stosb

    ret
ENDP

DATASEG
spawn_crate_timer db 0
;crate1 Drawable <120,10,CRATE_WIDTH,CRATE_HEIGHT,offset crateSprite>
crates_active  db CRATES_MAX_COUNT/8 DUP(0)

crate_filename db "sprites\rock.b", 0

UDATASEG

crates_objects Drawable CRATES_MAX_COUNT DUP(?)
crateSprite db 400 DUP(?)

end
