; Copyright (C) 2001, Tiago Gasiba (ee97034@fe.up.pt)
;
; $Id: readkey.asm,v 1.3 2002/02/02 08:49:25 konst Exp $
;
; hacker's readkey
;
; This program reads a keystroke and returns the key code
; in hex. It can be useful when writting script files.

%include "system.inc"

CODESEG

hex	db	'0123456789abcdef'

do_ioctl:
	sys_ioctl	STDIN
	ret

START:
	_mov	edx,oldtermios
	push	edx
	push	dword TCGETS
	pop	ecx
	sub	sp,byte 4
	call	do_ioctl

	pop	ecx
	_mov    edx,newtermios
	push	edx
	call	do_ioctl

	and	dword [newtermios+termios.c_lflag],~(ICANON|ECHO|ISIG)

	_mov	ecx,TCSETS
	pop	edx
	push	ecx
	call	do_ioctl

	_mov	eax,0
	mov	dword [newtermios],eax		; clean buffer ; #######
	sys_read STDIN,newtermios,4		; read keystroke

	pop	ecx
	pop	edx
	call	do_ioctl

	_mov	ecx,8				; convert number to ascii (hex)
	_mov	esi,oldtermios+7
	_mov	edx,dword [newtermios]
	_mov	ebx,hex
.outro:
	mov	eax,edx

	and	al,0xf
	xlatb
	mov	byte [esi],al
	dec	esi
	shr	edx,4
	loop	.outro

	mov	byte [oldtermios+8],0xa
	mov	word [prefix],"0x"

	sys_write	STDOUT,prefix,11	; write string

	sys_exit	0

UDATASEG

prefix:
	resb	2

oldtermios:
	B_STRUC termios,.c_iflag,.c_oflag
newtermios:
	B_STRUC termios,.c_iflag,.c_oflag

END
