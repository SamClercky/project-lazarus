ideal
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "physics.inc"
include "drawer.inc"
include "utils.inc"

PHYSICS_HALF_BOX equ 10

CODESEG

PROC Physics_reset
    USES eax, ecx, edi

    mov ecx, STATIC_OBJECT_MAX_COUNT/8
    mov edi, OFFSET static_active
    xor eax, eax
    rep stosb

    mov ecx, MOVING_OBJECT_MAX_COUNT/8
    mov edi, OFFSET moving_active
    xor eax, eax
    rep stosb

    mov ecx, DYNAMIC_OBJECT_MAX_COUNT/8
    mov edi, OFFSET dynamic_active
    xor eax, eax
    rep stosb

    ret
ENDP

PROC Physics_add_static
    ARG @@drawer_ptr:dword
    call Utils_add_to_container, [@@drawer_ptr], OFFSET static_active, OFFSET static_objects, STATIC_OBJECT_MAX_COUNT
    ret
ENDP

PROC Physics_del_static
    ARG @@index:dword
    call Utils_remove_from_container, OFFSET static_active, [@@index], STATIC_OBJECT_MAX_COUNT
    ret
ENDP

PROC Physics_add_dynamic
    ARG @@drawer_ptr:dword
    call Utils_add_to_container, [@@drawer_ptr], OFFSET dynamic_active, OFFSET dynamic_objects, DYNAMIC_OBJECT_MAX_COUNT
    ret
ENDP

PROC Physics_del_dynamic
    ARG @@index:dword
    call Utils_remove_from_container, OFFSET dynamic_active, [@@index], DYNAMIC_OBJECT_MAX_COUNT
    ret
ENDP

PROC Physics_add_moving
    ARG @@drawer_ptr:dword
    call Utils_add_to_container, [@@drawer_ptr], OFFSET moving_active, OFFSET moving_objects, MOVING_OBJECT_MAX_COUNT
    ret
ENDP

PROC Physics_del_moving
    ARG @@index:dword
    call Utils_remove_from_container, OFFSET moving_active, [@@index], MOVING_OBJECT_MAX_COUNT
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

PROC Physics_check_colliding_loop
    ARG @@active_ptr:dword, @@objects_ptr:dword, @@max_count:dword, @@drawer_ptr:dword, @@direction:dword
    USES ecx, edi

    xor eax, eax
    mov ecx, [@@max_count]
@@loop_check_colliding:
    push ecx
    dec ecx ; ecx in [0-len)

    call Utils_get_if_active, [@@active_ptr], [@@objects_ptr], ecx
    test eax, eax ; test if active
    jz @@end_loop ; if NULL -> not active
    
    ;; check collision
    mov edi, eax ; dest PTR currently in eax
    call Physics_is_colliding, [@@drawer_ptr], [DWORD PTR edi], [@@direction]
    test eax, eax ; test if collision
    jz @@end_loop ; if NULL -> no collision -> continue
    ;;; collision found
    mov eax, [edi]
    pop ecx ; cleaning
    jmp @@return

@@end_loop:
    pop ecx
    loop @@loop_check_colliding
    
    ;; no collision found
    xor eax, eax

@@return:
    ret
ENDP

;; return the pointer to the first colliding object
;; direction: enum { UP=0, LEFT=1, BOTTOM=2, RIGHT=4, MIDDLE=8}
PROC Physics_check_colliding
    ARG @@drawer_ptr:dword, @@direction:dword
    USES ebx, ecx, edx, esi, edi

    mov esi, [@@drawer_ptr]

    call Physics_check_colliding_loop, OFFSET static_active, OFFSET static_objects, STATIC_OBJECT_MAX_COUNT, esi, [@@direction]
    test eax, eax
    jnz @@return ; collision found (eax contains collision object)

    call Physics_check_colliding_loop, OFFSET dynamic_active, OFFSET dynamic_objects, DYNAMIC_OBJECT_MAX_COUNT, esi, [@@direction]
    test eax, eax
    jnz @@return ; collision found (eax contains collision object)
    
    call Physics_check_colliding_loop, OFFSET moving_active, OFFSET moving_objects, MOVING_OBJECT_MAX_COUNT, esi, [@@direction]
    test eax, eax
    jnz @@return ; collision found (eax contains collision object)

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
    dec ebx
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
    sub ebx, 5
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
    add eax, PHYSICS_HALF_BOX ; add half a box
    add ebx, PHYSICS_HALF_BOX ; add half a box
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
moving_objects  dd MOVING_OBJECT_MAX_COUNT  DUP(?) ; objects that move (player)
static_objects  dd STATIC_OBJECT_MAX_COUNT  DUP(?) ; objects that do not move (sidewalls)
dynamic_objects dd DYNAMIC_OBJECT_MAX_COUNT DUP(?) ; objects that move but can change (crates)

end
