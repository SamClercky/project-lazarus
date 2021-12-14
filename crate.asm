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

CRATE_SPITES_LEN equ 5
CRATE_SPAWN_DELAY equ 120

CODESEG

PROC Crate_init
    ;; load sprites

    call Utils_read_file, OFFSET crate_rock_filename, OFFSET crateRockSprite, CRATE_WIDTH*CRATE_HEIGHT
    call Utils_read_file, OFFSET crate_stone_filename, OFFSET crateStoneSprite, CRATE_WIDTH*CRATE_HEIGHT
    call Utils_read_file, OFFSET crate_wood_filename, OFFSET crateWoodSprite, CRATE_WIDTH*CRATE_HEIGHT
    call Utils_read_file, OFFSET crate_metal_filename, OFFSET crateMetalSprite, CRATE_WIDTH*CRATE_HEIGHT
    call Utils_read_file, OFFSET crate_card_filename, OFFSET crateCardSprite, CRATE_WIDTH*CRATE_HEIGHT

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
    USES esi, ebx, edi

    ;; check timer --> create new one or not
    movzx eax, [spawn_crate_timer]
    cmp eax, CRATE_SPAWN_DELAY     ;; indicator for time, after how many Game_updates
    jl @@update_timer

    ;; make new crate
    mov esi, [@@player_ptr]
    movzx ebx, [(Drawable PTR esi).x] ;; retrieve x
    ;; get new crate type
    mov edi, OFFSET nextCrateDrawable
    mov eax, [(Drawable PTR edi).data_ptr]
    call Crate_constructor, ebx, CRATE_Y_START, CRATE_WIDTH, CRATE_HEIGHT, eax
    ;; set next crate type
    call Utils_rand_max, CRATE_SPITES_LEN
    mov eax, [crate_sprites + 4*eax]
    mov [(Drawable PTR edi).data_ptr], eax
    mov eax, ebx ; store x in eax

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

;; eax=0 when not getting squished by heavier crate
;; eax=1 crate is getting squished
PROC Crate_check_squished
    ARG @@crate_drawable_ptr:dword
    USES ebx, edi, esi

    xor eax, eax
    mov esi, [@@crate_drawable_ptr]
    ;;check for a object on top of current crate
    call Physics_check_colliding, esi, DIR_UP
    test eax, eax
    jz @@not_squished
    
    mov edi, eax ;eax points to current object on top of the crate
    ;; check if object is another crate (and not the player)
    xor eax, eax
    mov eax, [(Drawable PTR edi).data_ptr]
    cmp eax, OFFSET crateCardSprite
    jl @@not_squished
    cmp eax, OFFSET crateRockSprite
    jg @@not_squished
    
    ;;object is a crate, check if crate is heavier
    mov ebx, [(Drawable PTR esi).data_ptr]
    cmp eax, ebx
    jle @@not_squished
    jmp @@squished

@@not_squished:
    xor eax, eax
    jmp @@return

@@squished:
    mov eax, 1

@@return:
    ret
ENDP

PROC Crate_remove
    ARG @@active_crates_index:dword
    USES eax

    xor eax, eax
    mov eax , [@@active_crates_index]
    call Utils_set_active, OFFSET crates_active, eax, 0
    ;; remove current crate in physics
    call Physics_del_dynamic, eax ; index for dynamic_active container in physics is consistent with crates_active container (because it only contains the crates)

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
    call Crate_check_squished, esi
    test eax, eax
    jz @@end_crates ; crate is not getting squished by heavier crate
    call Crate_remove, ecx

@@end_crates:
    pop ecx
    loop @@loop_crates

    ;; draw next crate type
    call Drawer_draw, OFFSET nextCrateDrawable
   
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
crates_active  db CRATES_MAX_COUNT/8 DUP(0)

crate_rock_filename db "sprites\rock.b", 0
crate_stone_filename db "sprites\stone.b", 0
crate_wood_filename db "sprites\wood.b", 0
crate_metal_filename db "sprites\metal.b", 0
crate_card_filename db "sprites\card.b", 0

;; contains next drawable to be drawn in the corner
nextCrateDrawable Drawable <0,180,20,20,OFFSET crateRockSprite>

crate_sprites dd OFFSET crateCardSprite,\
                OFFSET crateWoodSprite,\
                OFFSET crateStoneSprite,\
                OFFSET crateMetalSprite,\
                OFFSET crateRockSprite

UDATASEG

crates_objects Drawable CRATES_MAX_COUNT DUP(?)

;; sprites
crateCardSprite db 400 DUP(?)
crateWoodSprite db 400 DUP(?)
crateStoneSprite db 400 DUP(?)
crateMetalSprite db 400 DUP(?)
crateRockSprite db 400 DUP(?)

end
