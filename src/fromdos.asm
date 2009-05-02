; Copyright (C) 2001, Tiago Gasiba (ee97034@fe.up.pt)
;
; $Id: fromdos.asm,v 1.1 2001/08/19 12:41:59 konst Exp $
;
; hackers' fromdos/todos
;
;  This program converts ascii text files from DOS/UNIX
; to UNIX/DOS formats
;
; Example of usage:
;     fromdos < text.dos > text.unix
;     todos < text.unix > text.dos
;

%include "system.inc"

CODESEG
NEW_CHAR	db	0xd

START:
	pop	eax				; argc
	dec	eax
	jnz	.saida
	pop	esi				; argv[0]
.n1:						; how we are called?
	lodsb
	or 	al,al
	jnz	.n1

	_mov	ecx,buffer			; save in ecx addr buffer

.repete:
	sys_read	STDIN,ecx,1

	test	eax,eax
	jz	.saida

	cmp	word [esi-6],'om'		; executing fromdos ???
	je	.fromdos

.todos:						; assume we're executing todos
	cmp	byte [ecx],0xa			; search for Line Feed
	jne	.continua

	push	ecx
	sys_write	STDOUT,NEW_CHAR,1	; insert Carriage Return
	pop	ecx

.continua:
	sys_write	STDOUT,ecx,1		; write read char
	jmp	short	.repete
	
.fromdos:
	cmp	byte [ecx],0xd			; search for Carriage Return
	je	.repete
	jmp	short	.continua

.saida:
	sys_exit	0

UDATASEG
buffer	resb	1
	
END
