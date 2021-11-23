ideal
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "physics.inc"
include "drawer.inc"
include "utils.inc"

CODESEG

PROC Physics_add_static
    ARG @@drawer_ptr:dword
    USES eax, esi, edi

    call Utils_get_next_active_index, OFFSET static_active, STATIC_OBJECT_MAX_COUNT
    cmp eax, -1
    je @@return ;; check if not full and fail silently

    ;; set active
    call Utils_set_active, OFFSET static_active, eax, 1
    ;; not full
    mov edi, OFFSET static_objects
    mov esi, [@@drawer_ptr]
    mov [edi + 4*eax], esi

@@return:
    ret
ENDP

PROC Physics_add_dynamic
    ARG @@drawer_ptr:dword
    USES eax, esi, edi

    call Utils_get_next_active_index, OFFSET dynamic_active, DYNAMIC_OBJECT_MAX_COUNT
    cmp eax, -1
    je @@return ;; check if not full and fail silently

    ;; set active
    call Utils_set_active, OFFSET dynamic_active, eax, 1
    ;; not full
    mov edi, OFFSET dynamic_objects
    mov esi, [@@drawer_ptr]
    mov [edi + 4*eax], esi

@@return:
    ret
ENDP

;; applies gravity and takes collisions into account
PROC Physics_apply_gravity_with_collision
    ARG @@drawer_ptr:dword, @@mass:dword
    USES eax, ebx, esi

    call Physics_check_colliding, [@@drawer_ptr], DIR_BOTTOM
    test eax, eax
    jnz @@return

    ;; no collision -> go down
    call Physics_apply_gravity, [@@drawer_ptr], [@@mass]

@@return:
    ret
ENDP

;; return the pointer to the first colliding object
;; direction: enum { UP=0, LEFT=1, BOTTOM=2, RIGHT=4, MIDDLE=8}
PROC Physics_check_colliding
    ARG @@drawer_ptr:dword, @@direction:dword
    USES ebx, ecx, edx, esi, edi

    mov esi, [@@drawer_ptr]

    ;; STATIC
    mov ecx, STATIC_OBJECT_MAX_COUNT
@@loop_static:
    push ecx
    dec ecx ; ecx in [0-len)

    call Utils_get_if_active, OFFSET static_active, OFFSET static_objects, ecx
    test eax, eax ; test if active
    jz @@end_static ; if NULL -> not active
    
    ;; check collision
    mov edi, eax ; dest PTR currently in eax
    call Physics_is_colliding, esi, [DWORD PTR edi], [@@direction]
    test eax, eax ; test if collision
    jz @@end_static ; if NULL -> no collision -> continue
    ;;; collision found
    mov eax, [edi]
    pop ecx ; cleaning
    jmp @@return

@@end_static:
    pop ecx
    loop @@loop_static

    ;; DYNAMIC
    mov ecx, DYNAMIC_OBJECT_MAX_COUNT
@@dyn_loop:
    push ecx
    dec ecx ; ecx in [0-len)

    call Utils_get_if_active, OFFSET dynamic_active, OFFSET dynamic_objects, ecx
    test eax, eax ; test if active
    jz @@end_dyn ; if NULL -> not active
    
    ;; check collision
    mov edi, eax ; dest PTR currently in eax
    call Physics_is_colliding, esi, [DWORD PTR edi], [@@direction]
    test eax, eax ; test if collision
    jz @@end_dyn ; if NULL -> no collision -> continue
    ;;; collision found
    mov eax, [edi]
    pop ecx ; cleaning
    jmp @@return

@@end_dyn:
    pop ecx
    loop @@dyn_loop

    ;; MOVING
    mov ecx, MOVING_OBJECT_MAX_COUNT
@@loop_mov:
    push ecx
    dec ecx ; ecx in [0-len)

    call Utils_get_if_active, OFFSET moving_active, OFFSET moving_objects, ecx
    test eax, eax ; test if active
    jz @@end_mov ; if NULL -> not active
    
    ;; check collision
    mov edi, eax ; dest PTR currently in eax
    call Physics_is_colliding, esi, [DWORD PTR edi], [@@direction]
    test eax, eax ; test if collision
    jz @@end_mov ; if NULL -> no collision -> continue
    ;;; collision found
    mov eax, [edi]
    pop ecx ; cleaing
    jmp @@return

@@end_mov:
    pop ecx
    loop @@loop_mov

    ;; none found
    xor eax, eax

@@return:
    ret
ENDP

;; calc gravity as velocity and not acceleration
PROC Physics_apply_gravity
    ARG @@drawer_ptr:dword, @@mass:dword
    USES eax, esi

    mov esi, [@@drawer_ptr]
    
    ;; check collision
    mov ax, [(Drawable PTR esi).y]
    add eax, [@@mass]
    
    mov [(Drawable PTR esi).y], ax

    ret
ENDP

;; checks collision
;; eax true=1, false=0
;; checks the 4 four directions + middle
;; tile based game -> no partial overlap
;; direction: enum { UP=0, LEFT=1, BOTTOM=2, RIGHT=4, MIDDLE=8}
PROC Physics_is_colliding
    ARG @@obj1_ptr:dword, @@obj2_ptr:dword, @@direction:dword
    USES ebx, edx, esi, edi
    
    mov esi, [@@obj1_ptr]
    mov edi, [@@obj2_ptr]

    cmp esi, edi
    jne @@not_equal

    xor eax, eax
    jmp @@return

@@not_equal:
    mov edx, [@@direction]
    test edx, edx ; edx = 0
    jz @@up
    test edx, 1
    jnz @@left
    test edx, 2
    jnz @@bottom
    test edx, 4
    jnz @@right
    test edx, 8
    jnz @@middle
    
    ;; nothing found
    ;; => no collision
    jmp @@no_collision

    ;; check up
@@up:
    ;; clean eax, ebx
    xor eax, eax
    xor ebx, ebx

    mov ax, [(Drawable PTR esi).x]
    mov bx, [(Drawable PTR esi).y]
    dec ebx ; getting up, but may lead to problems in the future
    inc eax
    call Physics_point_in_obj, edi, eax, ebx
    test eax, eax
    jz @@no_collision
    jmp @@collision

    ;; check left
@@left:
    ;; clean eax, ebx
    xor eax, eax
    xor ebx, ebx

    mov ax, [(Drawable PTR esi).x]
    mov bx, [(Drawable PTR esi).y]
    dec eax
    add bx, [(Drawable PTR esi).height]
    sub ebx, 5 ; getting up, but may lead to problems in the future
    call Physics_point_in_obj, edi, eax, ebx
    test eax, eax
    jz @@no_collision
    jmp @@collision

@@bottom:
    ;; clean eax, ebx
    xor eax, eax
    xor ebx, ebx

    mov ax, [(Drawable PTR esi).x]
    mov bx, [(Drawable PTR esi).y]
    inc eax
    add bx, [(Drawable PTR esi).height]
    inc ebx
    call Physics_point_in_obj, edi, eax, ebx
    test eax, eax
    jz @@no_collision
    jmp @@collision

@@right:
    ;; clean eax, ebx
    xor eax, eax
    xor ebx, ebx

    mov ax, [(Drawable PTR esi).x]
    mov bx, [(Drawable PTR esi).y]
    add ax, [(Drawable PTR esi).width]
    inc eax
    add bx, [(Drawable PTR esi).height]
    sub ebx, 5
    inc ebx
    call Physics_point_in_obj, edi, eax, ebx
    test eax, eax
    jz @@no_collision
    jmp @@collision
    
@@middle:
    ;; clean eax, ebx
    xor eax, eax
    xor ebx, ebx

    mov ax, [(Drawable PTR esi).x]
    mov bx, [(Drawable PTR esi).y]
    inc eax
    inc ebx
    call Physics_point_in_obj, edi, eax, ebx
    test eax, eax
    jz @@no_collision
    jmp @@collision

@@collision:
    mov eax, 1
    jmp @@return

@@no_collision:
    xor eax, eax

@@return:
    ret
ENDP

;; checks if point is in object
PROC Physics_point_in_obj
    ARG @@obj_ptr:dword, @@x:dword, @@y:dword
    USES esi

    mov esi, [@@obj_ptr]

    mov ax, [(Drawable PTR esi).x]
    cmp [@@x], eax
    jl @@not_obj

    add ax, [(Drawable PTR esi).width]
    cmp [@@x], eax
    jg @@not_obj

    mov ax, [(Drawable PTR esi).y]
    cmp [@@y], eax
    jl @@not_obj

    add ax, [(Drawable PTR esi).height]
    cmp [@@y], eax
    jg @@not_obj

    ;; point in obj
    mov eax, 1
    jmp @@return
    
@@not_obj:
    ;; not in obj
    xor eax, eax

@@return:    
    ret
ENDP

DATASEG

moving_active  db MOVING_OBJECT_MAX_COUNT/8  DUP(0)
static_active  db STATIC_OBJECT_MAX_COUNT/8  DUP(0)
dynamic_active db DYNAMIC_OBJECT_MAX_COUNT/8 DUP(0)

UDATASEG

;; storage pools for the physics engine
;; contains pointers to drawable objects
moving_objects  dd MOVING_OBJECT_MAX_COUNT  DUP(?) ; objects that move (playing + falling crates)
static_objects  dd STATIC_OBJECT_MAX_COUNT  DUP(?) ; objects that do not move
dynamic_objects dd DYNAMIC_OBJECT_MAX_COUNT DUP(?) ; objects that move but can change (fallen crates)

end
