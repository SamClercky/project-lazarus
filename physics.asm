ideal
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "physics.inc"
include "drawer.inc"

CODESEG

;; calc gravity as velocity and not acceleration
PROC Physics_apply_gravity
    ARG @@drawer_ptr:dword, @@mass:dword
    USES eax, esi

    mov esi, [@@drawer_ptr]
    
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
    mov ax, [(Drawable PTR esi).x]
    mov bx, [(Drawable PTR esi).y]
    inc ebx ; getting up, but may lead to problems in the future
    dec eax
    call Physics_point_in_obj, edi, eax, ebx
    test eax, eax
    jz @@no_collision
    jmp @@collision

@@bottom:
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
    mov ax, [(Drawable PTR esi).x]
    mov bx, [(Drawable PTR esi).y]
    add ax, [(Drawable PTR esi).width]
    inc eax
    inc ebx
    call Physics_point_in_obj, edi, eax, ebx
    test eax, eax
    jz @@no_collision
    jmp @@collision
    
@@middle:
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

end


