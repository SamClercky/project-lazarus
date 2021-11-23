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

PROC Utils_add_to_container
    ARG @@drawer_ptr:dword, @@active_ptr:dword, @@container_ptr:dword, @@max_count:dword
    USES eax, esi, edi

    call Utils_get_next_active_index, [@@active_ptr], [@@max_count]
    cmp eax, -1
    je @@return ;; check if not full and fail silently

    ;; set active
    call Utils_set_active, [@@active_ptr], eax, 1
    ;; not full
    mov edi, [@@container_ptr]
    mov esi, [@@drawer_ptr]
    mov [edi + 4*eax], esi

@@return:
    ret
ENDP

PROC Utils_remove_from_container
    ARG @@active_ptr:dword, @@index:dword, @@max_count:dword
    USES eax

    mov eax, [@@index]
    cmp eax, [@@max_count]
    jge @@return ;; index out of range, early return

    ;; deactivate
    call Utils_set_active, [@@active_ptr], eax, 0

@@return:
    ret
ENDP

;; Load file into memory, -1 in eax if failed
PROC Utils_read_file
    ARG @@file_name:dword, @@dest_buffer:dword, @@number_of_bytes:dword
    USES ebx, ecx, edx

    ;; opening file in read only mode
    mov ax, 3D00h
    mov edx, [@@file_name]
    int 21h

    jc @@return ; error occured, could not open file, err code in eax

    ;; read data
    mov bx, ax ; file handle
    mov ax, 3F00h
    mov ecx, [@@number_of_bytes]
    mov edx, [@@dest_buffer]
    int 21h

    jc @@return ; error occured, could not read file, err code in eax

    ;; close the file
    mov ax, 3E00h
    int 21h

    jc @@return ; error occured, could not close file, err code in eax

    ;; everything went OK -> eax = 0
    xor eax, eax

@@return:
    ret
ENDP

end
