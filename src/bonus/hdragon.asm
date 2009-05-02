; hdragon.asm
;
; $Id: hdragon.asm,v 1.1 2006/02/09 07:48:15 konst Exp $
;
; 640x480x8 harter's dragon impl
;
; (c) 2k2 Maciej Hrebien

%include "system.inc"

%assign MaxX 640
%assign MaxY 480

%assign NORTH 0
%assign EAST  1
%assign SOUTH 2
%assign WEST  3

%assign LEFT -1
%assign RIGHT 1

%assign NEST  16  ; > 16 will cross frame buffer & sigfault !
%assign COLOR 14
%assign DELAY 0xffff

CODESEG

; al  - drawing direction LEFT or RIGHT
; edx - nestle (how deep the code is)
; edi - frame buffer ptr
; esi - direct & pxy ptr

dragon:
	pusha

	or	edx,edx		; last nestle ?
	jz	put_pixel

	dec	edx
	push	eax

	mov	al,RIGHT
	call	dragon

	pop	eax
	add	[esi],al	; chg drawing direction (-/+)90 deg
	and	[esi],byte 3

	mov	al,LEFT
	call	dragon

	jmp	short d_ret

 put_pixel:

	push	esi
	lodsd

	cmp	al,NORTH	; where the next pixel will go ?
	je	goes_north
	cmp	al,SOUTH
	je	goes_south
	cmp	al,EAST
	je	go

	push	byte -1		; west
	pop	eax
	jmp	short go

 goes_north:

	mov	eax,-MaxX
	jmp	short go

 goes_south:

	mov	ax,MaxX
 go:
	add	eax,[esi]		; put the pixel on the proper side
	mov	[edi + eax],byte COLOR
	mov	[esi],eax		; save new pixels' position

	pop	esi

	_mov	ecx,DELAY
 delay:	loop	delay
 d_ret:
	popa
	ret

; main routine

START:
	sys_open fb0,O_RDWR

	or	eax,eax
	js	exit

	push	eax

;	sys_mmap 0,MaxX*MaxY,PROT_WRITE,MAP_SHARED,eax,0
	sys_mmap EMPTY,MaxX*MaxY,PROT_WRITE,MAP_SHARED,eax,EMPTY

	or	eax,eax
	js	merr

	mov	edi,eax
	push	eax

	mov	ecx,MaxX*MaxY	; blank the screen
	xor	al,al
	rep	stosb

	pop	edi

	push	dword MaxX*MaxY*2/3+MaxX/2	; pxy
	push	byte NORTH			; direct
	mov	esi,esp

;	mov	al,RIGHT
	inc	eax		; RIGHT == 1 && al == 0 !!
	_mov	edx,NEST
	call	dragon

	pop	eax
	pop	eax

	sys_munmap edi,MaxX*MaxY
 merr:
	pop	eax
	sys_close eax
 exit:
	sys_exit

fb0:	db "/dev/fb0",0

END
