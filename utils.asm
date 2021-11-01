ideal
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "utils.inc"

CODESEG

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
    shr eax, cl

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
    jz @@end_loop

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

    call Utils_is_active, [@@active_array], [@@index]
    test eax, eax
    jz @@not_active
    mov eax, [@@source_array]
    add eax, [@@index]
    jmp @@return

@@not_active:
    xor eax, eax
    ; pass through
@@return:
    ret
end