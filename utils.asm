ideal
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "utils.inc"

CODESEG

PROC Utils_set_active
    ARG @@active_array:dword, @@index:dword, @@value:dword
    USES eax, ecx, edx, esi

    mov esi, [@@active_array]
    mov eax, [@@index]
    xor edx, edx

    mov ecx, 8
    div ecx

    add esi, eax
    mov ecx, edx
    mov edx, 1
    shl edx, cl

    mov eax, [@@value]
    test eax, eax
    jnz @@one

    mov al, [esi]
    not edx
    and eax, edx
    jmp @@write

@@one:
    mov al, [esi]
    or eax, edx

@@write:
    mov [esi], al

    ret
ENDP

;; returns eax=NULL if no found otherwise value in array
PROC Utils_is_active
    ARG @@active_array:dword, @@index:dword
    USES ecx, edx, esi

    ;; check if active
    mov esi, [@@active_array]
    xor edx, edx ; reset edx
    mov eax, [@@index]

    mov ecx, 8
    div ecx
    
    mov ecx, edx
    add esi, eax
    mov al, [esi]
    shr al, cl

    and eax, 1

    ret
ENDP

;; returns eax=-1 if full
PROC Utils_get_next_active_index
    ARG @@active_array:dword, @@length:dword
    USES ebx, ecx, edx, esi, edi

    mov esi, [@@active_array]

    mov ecx, [@@length]
@@loop:
    push ecx
    dec ecx

    call Utils_is_active, [@@active_array], ecx
    test eax, eax
    jnz @@end_loop

    mov eax, ecx
    pop ecx ; cleaning
    jmp @@return
    
@@end_loop:
    pop ecx
    loop @@loop

    ;; nothing found
    mov eax, -1
    
@@return:
    ret
ENDP

;; returns eax=NULL if none found otherwise data at source_array
PROC Utils_get_if_active
    ARG @@active_array:dword, @@source_array:dword, @@index:dword
    USES edi

    call Utils_is_active, [@@active_array], [@@index]
    test eax, eax
    jz @@not_active
    mov edi, [@@source_array]
    mov eax, [@@index]
    lea eax, [edi + 4*eax]
    jmp @@return

@@not_active:
    xor eax, eax
    ; pass through
@@return:
    ret
ENDP
end
