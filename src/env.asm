;Copyright (C) 2000 Edward Popkov <evpopkov@carry.neonet.lv>
;
;$Id: env.asm,v 1.3 2002/02/02 08:49:25 konst Exp $
;
;hackers' env
;
;syntax: env
;
;0.01: 27-Feb-2000	initial release

%include "system.inc"

CODESEG

START:
	pop	ebp
.env:
	inc	ebp
	mov	esi,[esp + ebp * 4]
	test	esi,esi
	jz	do_exit
	mov	ecx,esi
	xor	edx,edx
	dec	edx
.slen:
	inc	edx
	lodsb
	test	al,al
	jnz	.slen
	mov	[esi-1],byte 0xa
	inc	edx
	sys_write STDOUT
	jmps	.env

do_exit:
	sys_exit_true

END
