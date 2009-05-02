;Copyright (C) 1999 Indrek Mandre <indrek@mare.ee>
;
;$Id: yes.asm,v 1.6 2002/03/26 05:24:27 konst Exp $
;
;hackers' yes		[GNU replacement]
;
;syntax: yes [string...]
;
;example: yes string1 string2 string3
;         yes
;         yes onlyonestring
;
;Concatenates all strings, the resulting string can be 0xfff bytes long
;
;0.01: 17-Jun-1999	initial release
;0.02: 04-Jul-1999	fixed bug with 2.0 kernel (KB)
;0.03: 14-Mar-2002	size improvements (KB)

%include "system.inc"

CODESEG

%assign	BUFSIZE	0x1000

START:
	pop	ebp			;ebp holds argument count
	pop	eax			;we ignore our own name

	mov	edi,buf
	mov	edx,edi

	dec	ebp
	jnz	.nextarg		;take arguments and cat them to out buf

	mov	al,'y'
	stosb
	inc	ebp
;	jmps	.startinfiniteprint

.endofstring:
	dec	ebp
	jz	.startinfiniteprint	;print what we've got so far

	mov	al,' '
	stosb

.nextarg:
	pop	esi			;pop the string
.back:
	lodsb
	or	al,al			;end of string?
	jz	.endofstring
	stosb
	cmp	edi,buf + BUFSIZE - 2	;end of our dear buf?
	jl	.back			;in that case just print out what we got

.startinfiniteprint:
	mov	al,__n			;concatenate \n
	stosb
	sub	edi,edx			;length of final string
.myloop:
	sys_write STDOUT,buf,edi
	jmps	.myloop

;.exit:
;	sys_exit

UDATASEG

buf	resb	BUFSIZE			;our internal buffer size

END
