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
include "player.inc"
include "crate.inc"

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

;; waits for VBI (code mostly from course)
PROC waitForVBI
    USES eax, edx

    mov dx, 03dah
@@wait_end:
    in al, dx
    and al, 8 ; get correct bit
    jnz @@wait_end
@@wait_begin:
    in al, dx
    and al, 8
    jz @@wait_begin

    ret
ENDP

start:
     sti            ; set The Interrupt Flag => enable interrupts
     cld            ; clear The Direction Flag

    ;; enable str ops
    push ds
    pop es
    
    call enable_video

@@game_loop:
    call waitForVBI
    call Drawer_bg
    call Crate_draw
    call Player_draw

    ;; update screen
    call Drawer_update
    
    ;; check if ending
    mov ah, 01h
    int 16h
    jz @@game_loop ; continue game

	; Wait for keystroke and read character.
	;mov ah,00h
	;int 16h
    ;call disable_video


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
