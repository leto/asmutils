;Copyright (C) 1999 Indrek Mandre <indrek@mare.ee>
;
;$Id: basename.asm,v 1.5 2002/03/14 07:12:12 konst Exp $
;
;hackers' basename	[GNU replacement]
;
;syntax: basename path [suffix]
;
;example: basename /bin/basename
;         basename /kala.xxx xxx
;
; in case of error exits with code 256, 0 otherwise
;
;0.01: 17-Jun-1999	initial release
;0.02: 04-Jul-1999	bugfixes
;0.03: 29-Jul-1999	size improvements (KB)
;0.04: 14-Mar-2002	size improvements (KB)

%include "system.inc"

CODESEG

START:
	_mov	ebx,1		;error code

	pop	eax
	mov	edi,eax		;edi holds argument count
        dec	edi
	jz	.exit
	cmp	edi,byte 2	;must be not more than two arguments
	jg	.exit

	pop	eax		;skip our name
	pop	eax		;the path
	mov	ebx,eax		;mark the beginning of path
	xor	edx,edx
	cmp	byte [eax],EOL
	je	.printout
.loopone:
	inc	eax
	cmp	byte [eax],EOL
	jne	.loopone
	mov	edx,eax		;mark the end
.backwego:
	dec	eax
	cmp	eax,ebx
	jnl	.empty
	xor	edx,edx
	jmps	.printout
.empty:
	cmp	byte [eax],'/'
	je	.backwego
	inc	eax
	mov	edx,eax
.looptwo:
	dec	eax
	cmp	byte [eax],'/'
	je	.endlooptwoinceax
	cmp	eax,ebx
	je	.endlooptwo
	jmps	.looptwo

;end of checkinf of suffix

.goaftersuffixpopeax:
	pop	eax
.goaftersuffix:
	pop	edx
	pop	ecx

.printout:
	mov	byte [ecx+edx],__n
	inc	edx
	sys_write STDOUT
	xor	ebx,ebx
.exit:
	sys_exit

.endlooptwoinceax:
	inc	eax

.endlooptwo:
	mov	ecx,eax
	sub	edx,eax
	dec	edi
	jz	.printout	;we have no suffix to remove
	pop	eax
	push	ecx
	push	edx
	add	ecx,edx
  
;now we check for suffix
	mov	ebx,eax		;save start of suffix

	cmp	byte [eax],EOL
	je	.goaftersuffix	;there was nothing in suffix string, so nothin to remove
.suffixloop:
	inc	eax
	cmp	byte [eax],EOL
	jne	.suffixloop
.endsuffixloop:
	sub	eax,ebx		;we have length of suffix here now
	cmp	eax,edx		;in case suffix is longer jump out
	jge	.goaftersuffix
	add	eax,ebx

	push	eax

;now comes the comparing part

.sloop:
	dec	eax
	dec	ecx

	mov	dl,[eax]
	cmp	[ecx],dl
	jne	.goaftersuffixpopeax	;not equal

	cmp	eax,ebx
	jne	.sloop

;we got here, it means suffix matched

	pop	eax
	sub	eax,ebx		;we have here the all famous length
	pop	edx
	pop	ecx
	sub	edx,eax		;decrement the length by suffix
	jmps	.printout	;and print it out

END
