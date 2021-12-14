ideal
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "game.inc"
include "player.inc"
include "crate.inc"
include "physics.inc"
include "drawer.inc"
include "utils.inc"

CODESEG

WALL_SIZE equ 20
KEY_CHECKS equ 4

BUTTON_WIDTH equ 20
BUTTON_HEIGHT equ 20
BUTTON_START_X equ 120
BUTTON_START_Y equ 120

GAME_STATE_CHANGED_DELAY equ 10

PROC Game_init
    ;; init rand generator so other functions can use it
    call Utils_rand_init
    
    ;; init button
    call Utils_read_file, OFFSET button_filename, OFFSET buttonData, BUTTON_WIDTH*BUTTON_HEIGHT
    
    ;; init players and crates
    call Player_init
    call Crate_init

    ;; load walls
    call Utils_read_file, OFFSET wallFileName, OFFSET wallSprite, 400
    call Utils_read_file, OFFSET bgFileName, OFFSET bgSprite, 200*320

    ;; install custom keyhandler
    call __keyb_installKeyboardHandler
    
    call Game_reset

    ret
ENDP

PROC Game_deinit
    call __keyb_uninstallKeyboardHandler
    
    ret
ENDP

PROC Game_update
    ;; drawing
    ;;; background
    call Drawer_bg, OFFSET bgSprite

    ;;; walls
    call Game_draw_walls, 0, 1, 0, 10
    call Game_draw_walls, 20, 15, 180, 10
    call Game_draw_walls, 300, 1, 0, 10
    
    ;; draw button
    call Drawer_draw, OFFSET button
    
    ;; decrement input delay timer
    mov al, [game_state_changed_timer]
    test al, al
    jz @@game_update_end_update_timer
    dec al
    mov [game_state_changed_timer], al

@@game_update_end_update_timer:

    movzx ecx, [is_game_running]
    mov eax, [OFFSET game_states + 4*ecx]
    jmp eax

game_first_start:
    ;; draw welcome screen
    ;; update screen
    call Drawer_update ;; update after entity update

    call Drawer_draw_txt, 15, 10, OFFSET game_begin_msg
    call Drawer_draw_txt, 10, 11, OFFSET game_start_msg
    
    jmp @@game_end_update

game_running:
    ;; draw and update entities
    call Player_update
    call Crate_update
    ;;; make new crates --> in Player_update

    ;; update screen
    call Drawer_update ;; update after entity update

    jmp @@game_end_update

game_game_won:
    ;; draw winning screen

    call Drawer_draw_txt, 15, 10, OFFSET game_won_msg
    call Drawer_draw_txt, 10, 11, OFFSET game_start_msg

    jmp @@game_end_update

game_game_over:
    ;; draw game over screen

    call Drawer_draw_txt, 15, 10, OFFSET game_over_msg
    call Drawer_draw_txt, 10, 11, OFFSET game_start_msg

    jmp @@game_end_update

@@game_end_update:
    
    ;; handle game input and return eax to see if the game loop needs to end
    mov al, [game_state_changed_timer]
    test al, al
    jnz @@game_end_input ; prevent keys to be pressed while in transition

    ;; process input
    call Game_handle_input
    test eax, eax ; if Esc is pressed the program ends
    jnz @@return

@@game_end_input:

    call Player_check_dead
    test eax, eax
    jz @@end_check_dead
    mov [is_game_running], 2 
    mov [game_state_changed_timer], GAME_STATE_CHANGED_DELAY ; set delay in transition
    call Game_reset ; reset for next time
    xor eax, eax ; reset eax so, the program does not end
    jmp @@return

@@end_check_dead:

    call Player_check_win, OFFSET button
    test eax, eax
    jz @@end_check_win
    mov [is_game_running], 3
    mov [game_state_changed_timer], GAME_STATE_CHANGED_DELAY ; set delay in transition
    call Game_reset ; reset for next time
    xor eax, eax ; reset eax so, the program does not end
    jmp @@return

@@end_check_win:

@@return:
    ret
ENDP

;; Draws the walls by using wallSprite and placing it
;; on the place where we want it to be placed
PROC Game_draw_walls
    ARG @@start_x:dword, @@times_x:dword, @@start_y:dword, @@times_y:dword
    USES eax, ecx, esi

    mov esi, OFFSET wallDrawable
    mov eax, [@@start_y]
    mov [(Drawable PTR esi).y], ax

    mov ecx, [@@times_y]
@@loop_y:

    ;; (re)set x coord
    mov eax, [@@start_x]
    mov [(Drawable PTR esi).x], ax

    push ecx
    mov ecx, [@@times_x]
@@loop_x:
    
    ;; draw on screen
    call Drawer_draw, esi

    ;; update x
    add [(Drawable PTR esi).x], WALL_SIZE

    loop @@loop_x
    
    ;; update y
    add [(Drawable PTR esi).y], WALL_SIZE

    pop ecx
    loop @@loop_y

    ret
ENDP

;; code most from mykeyb example
; Installs the custom keyboard handler
PROC __keyb_installKeyboardHandler
    push	ebp
    mov		ebp, esp

	push	eax
	push	ebx
	push	ecx
	push	edx
	push	edi
	push	ds
	push	es
		
	; clear state buffer and the two state bytes
	cld
	mov		ecx, (128 / 2) + 1
	mov		edi, offset __keyb_keyboardState
	xor		eax, eax
	rep		stosw
	
	; store current handler
	push	es			
	mov		eax, 3509h			; get current interrupt handler 09h
	int		21h					; in ES:EBX
	mov		[originalKeyboardHandlerS], es	; store SELECTOR
	mov		[originalKeyboardHandlerO], ebx	; store OFFSET
	pop		es
		
	; set new handler
	push	ds
	mov		ax, cs
	mov		ds, ax
	mov		edx, offset keyboardHandler			; new OFFSET
	mov		eax, 2509h							; set custom interrupt handler 09h
	int		21h									; uses DS:EDX
	pop		ds
	
	pop		es
	pop		ds
	pop		edi
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax	
    
    mov		esp, ebp
    pop		ebp
    ret
ENDP __keyb_installKeyboardHandler

; Restores the original keyboard handler
PROC __keyb_uninstallKeyboardHandler
    push	ebp
    mov		ebp, esp

	push	eax
	push	edx
	push	ds
		
	mov		edx, [originalKeyboardHandlerO]		; retrieve OFFSET
	mov		ds, [originalKeyboardHandlerS]		; retrieve SELECTOR
	mov		eax, 2509h							; set original interrupt handler 09h
	int		21h									; uses DS:EDX
	
	pop		ds
	pop		edx
	pop		eax
	
    mov		esp, ebp
    pop		ebp
    ret
ENDP __keyb_uninstallKeyboardHandler

; Keyboard handler (Interrupt function, DO NOT CALL MANUALLY!)
PROC keyboardHandler
	KEY_BUFFER	EQU 60h			; the port of the keyboard buffer
	KEY_CONTROL	EQU 61h			; the port of the keyboard controller
	PIC_PORT	EQU 20h			; the port of the peripheral

	push	eax
	push	ebx
	push	esi
	push	ds
	
	; setup DS for access to data variables
	mov		ax, _DATA
	mov		ds, ax
	
	; handle the keyboard input
	sti							; re-enable CPU interrupts
	in		al, KEY_BUFFER		; get the key that was pressed from the keyboard
	mov		bl, al				; store scan code for later use
	mov		[__keyb_rawScanCode], al	; store the key in global variable
	in		al, KEY_CONTROL		; set the control register to reflect key was read
	or		al, 82h				; set the proper bits to reset the keyboard flip flop
	out		KEY_CONTROL, al		; send the new data back to the control register
	and		al, 7fh				; mask off high bit
	out		KEY_CONTROL, al		; complete the reset
	mov		al, 20h				; reset command
	out		PIC_PORT, al		; tell PIC to re-enable interrupts

	; process the retrieved scan code and update __keyboardState and __keysActive
	; scan codes of 128 or larger are key release codes
	mov		al, bl				; put scan code in al
	shl		ax, 1				; bit 7 is now bit 0 in ah
	not		ah
	and		ah, 1				; ah now contains 0 if key released, and 1 if key pressed
	shr		al, 1				; al now contains the actual scan code ([0;127])
	xor		ebx, ebx	
	mov		bl, al				; bl now contains the actual scan code ([0;127])
	lea		esi, [__keyb_keyboardState + ebx]	; load address of key relative to __keyboardState in ebx
	mov		al, [esi]			; load the keyboard state of the scan code in al
	; al = tracked state (0 or 1) of pressed key (the value in memory)
	; ah = physical state (0 or 1) of pressed key
	neg		al
	add		al, ah				; al contains -1, 0 or +1 (-1 on key release, 0 on no change and +1 on key press)
	add		[__keyb_keysActive], al	; update __keysActive counter
	mov		al, ah
	mov		[esi], al			; update tracked state
	
	pop		ds
	pop		esi
	pop		ebx
	pop		eax
	
	iretd
ENDP keyboardHandler

;; eax = 0 -> everything ok, eax = 1 -> end game
;; scan codes: https://www.fountainware.com/EXPL/bios_key_codes.htm
PROC Game_handle_input
    USES ebx, edx

    ;; check for Esc
    mov al, [__keyb_rawScanCode]
    cmp al, 01h
    je @@stop_game

    mov ecx, KEY_CHECKS

@@next_key:
    xor ebx, ebx
    movzx eax, [byte ptr offset keybscancodes + ecx - 1]
    mov bl, [offset __keyb_keyboardState + eax]
    test bl, bl ; bl=1 if pressed
    jz @@keys_end ; nothing pressed, continue

    ;; process key
    call Player_handle_input, eax ; eax contains keycode

    ;; (re)start game if not running
    movzx ebx, [is_game_running] ;; if running 1
    dec ebx ;; if running 0
    test ebx, ebx
    jz @@end_restart 

    mov [is_game_running], 1 ; continue game

@@end_restart:

@@keys_end:
    loop @@next_key

    jmp @@normal_end ; we processed all keys normally

@@stop_game:
    mov eax, 1
    jmp @@return

@@normal_end:
    xor eax, eax

@@return:
    ret
ENDP

;; set/reset game
PROC Game_reset

    call Physics_reset
    call Crate_reset
    call Player_reset

    ;; set initial vars for game 
    ;; fill buffer with non random data -> less glitch at the start
    call Drawer_bg, OFFSET bgSprite
    call Drawer_update

    ;; init physics
    call Physics_add_static, OFFSET wallL
    call Physics_add_static, OFFSET wallR
    call Physics_add_static, OFFSET wallB

    ret
ENDP

DATASEG
  
  ;; button
  button Drawable <BUTTON_START_X,BUTTON_START_Y,BUTTON_WIDTH,BUTTON_HEIGHT,offset buttonData>
  
  ;; are there only for the physics
  wallL Drawable <0,0,20,200,?>
  wallB Drawable <10,180,300,20,?>
  wallR Drawable <300,0,20,200,?>
  
  ;; sprites for the wall that is loaded on startup
  bgFileName db "sprites\bg.b", 0
  wallFileName db "sprites\wall.b", 0
  wallDrawable Drawable <0,0,20,20,OFFSET wallSprite>
  
  ;; sprite for button
  button_filename db "sprites\btn.b", 0

  ;; Game is running, contains current game state (index of game_states)
  is_game_running db 0

  ;;               T    L    B    R
  keybscancodes db 48h, 4Bh, 50h, 4Dh

  ;;             0                 1             2               3
  game_states dd game_first_start, game_running, game_game_over, game_game_won

  ;; game messages
  game_begin_msg db "START GAME", '$'
  game_over_msg db "GAME OVER", '$'
  game_start_msg db "Press any ARROW key", '$'
  game_won_msg db "YOU WON", '$'

  game_state_changed_timer db GAME_STATE_CHANGED_DELAY
UDATASEG
  wallSprite db 400 DUP(?)
  bgSprite db 200*320 DUP(?)
  buttonData db BUTTON_WIDTH*BUTTON_HEIGHT DUP(?)
  
  ;; mostly from example MYKEYB
  originalKeyboardHandlerS	dw ?			; SELECTOR of original keyboard handler
  originalKeyboardHandlerO	dd ?			; OFFSET of original keyboard handler

__keyb_keyboardState		db 128 dup(?)	; state for all 128 keys
__keyb_rawScanCode			db ?			; scan code of last pressed key
__keyb_keysActive			db ?			; number of actively pressed keys

end
