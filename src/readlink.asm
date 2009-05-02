;Copyright (C) 2001 by Joshua Hudson
;
;$Id: readlink.asm,v 1.1 2001/08/14 18:55:38 konst Exp $
;
;usage: readlink symlink [...]

%include "system.inc"

CODESEG

START:
	pop	ebp
	pop	eax	; Program name
.next:
	dec	ebp
	jz	.done
	_mov	edx, 1024
	_mov	ecx, buf
	pop	ebx		; Path name
	sys_readlink
	test	eax, eax
	jc	.next
	xchg	edx, eax		; one byte smaller than mov
	mov	[buf + edx], byte __n
	inc	edx
	sys_write	STDOUT, buf
	jmps	.next
.done	sys_exit_true

UDATASEG

buf	resb 1025

END
