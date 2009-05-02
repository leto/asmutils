; Copyright (C) 2004 by Joshua Hudson
;
; $Id: gi.asm,v 1.2 2006/02/18 10:04:00 konst Exp $
;
; asmutils gi
;
; gi displays IP address of a given network interface
;
; Usage: gi eth0
;
; Return value is weird:
; returns number of chars written including nl
; return value > 16 is an error

%include 'system.inc'
CODESEG

START:
	pop	eax
	pop	esi
	pop	esi
	or	esi, esi
	jz	.exit
	sys_socket	AF_INET, SOCK_DGRAM, IPPROTO_IP
	xchg	eax, ebx
	mov	edi, ifreq
	mov	edx, edi
.copy	lodsb
	stosb
	cmp	al, 0
	jnz	.copy
	_mov	ecx, SIOCGIFADDR
	sys_ioctl
	or	eax, eax
	js	.exit
	mov	edi, ifreq	; Override ioctl buffer
	mov	ebp, [addr]
	push	edi

	mov	ecx, 4
.nbyte	mov	eax, ebp
	shr	ebp, 8
	push	ecx
	and	eax, 255
	
	xor	ecx, ecx
	_mov	ebx, 10
.itoa_l	xor	edx, edx
	div	ebx
	add	dl, '0'
	inc	ecx
	or	eax, eax
	push	edx
	jnz	.itoa_l
.itoa_p	pop	eax
	stosb
	loop	.itoa_p	

	mov	al, '.'
	pop	ecx
	stosb
	loop	.nbyte

	mov	[edi - 1], byte __n
	pop	ecx
	mov	edx, edi
	sub	edx, ecx
	sys_write	STDOUT
.exit	sys_exit	eax

UDATASEG
ifreq	resb	16	; name
flags	resb	2
port	resb	2
addr	resb	2
unused	resb	8
END
