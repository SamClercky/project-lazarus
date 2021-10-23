; -------------------------------------------------------------------
; 80386
; 32-bit x86 assembly language
; TASM
;
; author:	Stijn Bettens, David Blinder
; date:		25/09/2017
; program:	Hello World!
; -------------------------------------------------------------------

IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "drawer.inc"

; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG

PROC end_prog
    uses eax
    
    call disable_video
    mov ax, 4c00h
    int 21h

    ret
ENDP

start:
     sti            ; set The Interrupt Flag => enable interrupts
     cld            ; clear The Direction Flag

    ;; enable str ops
    push ds
    pop es
    
    call enable_video
    call Drawer_bg

	; Wait for keystroke and read character.
	mov ah,00h
	int 16h
    call disable_video

	call end_prog

; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------
DATASEG
	msg	db "Bye world!", 13, 10, '$'

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END start
