;Copyright (C) Indrek Mandre <indrek@mare.ee>
;
;$Id: true.asm,v 1.6 2002/03/07 06:16:39 konst Exp $
;
;hackers' true/false
;
;syntax: true
;	 false
;
;0.01: 17-Jun-1999	initial release
;0.02: 04-Jul-1999	fixed bug with 2.0 kernel (KB)
;0.03: 20-Sep-1999	size improvements (KB)
;0.04: 05-Jan-2001	even more size improvements ;) (KB)
;0.05  29-Aug-2001      even more, more size improvements ;)) [two bytes] (RM)

%include "system.inc"

CODESEG

START:
	pop	esi
	pop	esi
.n1:				; how we are called?
	lodsb
	or 	al,al
	jnz	.n1
	xor	ebx,ebx
	shr	byte [esi-5],1
	rcl 	ebx,1
;	cmp	byte [esi-5],'t'
;	jz	.exit
;	inc	ebx
.exit:
	sys_exit

END
