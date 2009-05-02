; Copyright (C) 2001 Joshua Hudson <joshudson@hotmail.com>
;
; $Id: mknod.asm,v 1.2 2001/09/17 09:36:19 konst Exp $
;
; hacker's mknod/mkfifo
;
; Usage: mknod [-m mode] name type major minor
; Type is b	block     (e.g. /dev/hda1)
; 	  c	character (e.g. /dev/ttyS1)
;	  p	fifo	  (e.g. /dev/fifo)
;
; Usage: mkfifo name
;
; This mknod/mkfifo is GNU compatible

%include "system.inc"

CODESEG

START:
; Here we load esi with umask and set umask to 0
	xor	ebx, ebx
	sys_umask
	mov	esi, 0x1B6
	xor	esi, eax
	pop	ebx
	pop	ebx		;argv[0]
check_fifo:			;See if we are being called as mkfifo
	inc	ebx
	cmp	byte [ebx], 0
	jne	check_fifo
	dec	ebx
	cmp	byte [ebx], 'o'
	je	mkfifo

; Parse mknod options [ only -m ]
	pop	ebx
	or	ebx, ebx
	jz	bad_args
	cmp	word [ebx], '-m'
	jne	mknod_notmode
	inc	ebx
	inc	ebx
	cmp	byte [ebx], 0
	jne	mknod_setmode
	pop	ebx
	or	ebx, ebx
	jz	bad_args
mknod_setmode:
	call	setmode
	pop	ebx
	or	ebx, ebx
	jz	bad_args

mknod_notmode:		; Should have name type major minor
	; Name already in ebx.
	pop	ebp			; Loaded type
	or	ebp, ebp
	jz	bad_args
	cmp	byte [ebp], 'b'
	je	block
	cmp	byte [ebp], 'c'
	je	char
	cmp	byte [ebp], 'u'		; 'u' is sometimes used for char !!!
	je	char
	cmp	byte [ebp], 'p'
	je	fifo
	jmps	bad_args

; Got here in processing mkfifo
mkfifo:
	pop	ebx
	or	ebx, ebx
	jz	bad_args	
	cmp	word [ebx], '-m'
	jne	fifo
	inc	ebx
	inc	ebx
	cmp	[ebx], byte 0
	jne	mkfifo_setmode
	pop	ebx
	or	ebx, ebx
	jz	bad_args
mkfifo_setmode:	
	call	setmode
	pop	ebx
	or	ebx, ebx
	jz	bad_args
	jmps	fifo

bad_args:
	sys_write	STDERR, BadArgs, BadArgsLen
	mov	bl, 1
	jmp	goodbye

block	_mov	ecx, S_IFBLK
	jmps	mknod_ok
char	_mov	ecx, S_IFCHR
	jmps	mknod_ok
fifo	_mov	ecx, S_IFIFO
	xor	edx, edx
	or	ecx, esi
	jmps	mknod_go	; No need for major / minor

mknod_ok:
	or	ecx, esi
	; Find major << 8 + minor
	pop	ebp
	or	ebp, ebp
	jz	bad_args
	call	atoi		; Input in ebp, output in eax
	shl	eax, 8
	xchg	eax, edx	; mov edx, eax
	pop	ebp
	or	ebp, ebp
	jz	bad_args
	push	edx
	call	atoi
	pop	edx
	add	edx, eax
mknod_go:
	sys_mknod	; ebx = name, ecx = mode | perm, edx = dev
	xchg	ebx, eax ; return mknod's error code
goodbye:
	sys_exit

BadArgs	db	"Usage: mknod [-m mode] NAME TYPE MAJOR MINOR", __n
BadArgsLen equ $-BadArgs

; process mode: return in esi
setmode:
	xor	eax, eax
	xor	esi, esi
	mov	cl, 3
.setmode_read:
	mov	al, [ebx]
	inc	ebx
	sub	al, '0'
	js	.setmode_done
	cmp	al, 8
	jge	.setmode_done
	shl	esi, cl
	or	esi, eax
	jmps	.setmode_read
.setmode_done:
	ret

; Convert string in [ebp] to number in eax
; Preserve ebx, ecx, edx !
atoi:
	push	ebx
	push	ecx
	push	edx
	xor	eax, eax
	xor	ebx, ebx
atoi_go:
	mov	bl, [ebp]
	inc	ebp
	sub	bl, '0'
	js	atoi_done
	cmp	bl, 9
	jg	atoi_done
	xor	edx, edx
	_mov	ecx, 10
	mul	ecx
	add	eax, ebx
	jmps	atoi_go
atoi_done:
	pop	edx
	pop	ecx
	pop	ebx
	ret

;DEBUG:
;	pusha
;	sys_write	STDERR, DEBUGMSG, 6
;	popa
;	ret
;
;DEBUGMSG	db	"DEBUG", __n

END
