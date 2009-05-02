;Copyright (C) 2000 Jonathan Leto <jonathan@leto.net>
;
;$Id: touch.asm,v 1.5 2002/02/02 12:33:38 konst Exp $
;
;hackers' touch
;
;syntax: touch [-c] file [file] ...
;
; All comments/feedback welcome.
;
;0.01: 20-Dec-2000	initial release
;0.02: 02-Feb-2002	various fixes and improvements (KB)

%include "system.inc"

CODESEG

do_exit:
	sys_exit 0 

START:
	pop	eax
	pop	eax
	xor	edi,edi		;-c flag
	dec	edi
.next0:
	inc	edi
.next:
	pop	eax
	or	eax,eax
	jz	do_exit

.continue:
	cmp	word [eax],'-c'
	jz	.next0
.create:
	mov	ebp,eax
	test	eax,eax
	jns	.touchfile

	or	edi,edi
	jnz	.touchfile

	; create new file
	sys_open ebp,O_RDWR|O_CREAT,0666q

.touchfile:
%ifdef	__BSD__
	sys_utimes ebp,NULL
%else
	sys_utime ebp,NULL
%endif

	jmps	.next

END
