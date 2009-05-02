;Copyright (C) Alexandr Gorlov <ct@mail.ru>
;
;$Id: dirname.asm,v 1.2 2000/09/03 16:13:54 konst Exp $
;
;hackers dirname
;
;0.01: 15-Mar-2000	initial release
;0.02: 21-Mar-2000	full rewrite ;)
;0.03: 04-May-2000	"/" fixed, <strlen> shorter (PR)
;
;syntax: 
;	 dirname <path>

%include "system.inc"

lf 	equ	0x0A

CODESEG

START:

;====== У нас 2 аргумента ? ===========

	pop	ecx		; argc

	dec	ecx
	dec	ecx
	jnz	.exit		; argc == 2, else .exit
				; !!?? Show syntax, in next version
	
	pop	edi
	pop	edi		; Get the address of ASCIIZ string

	call	StrLen		; edx: = length of our string

	call	Strip_trailing_slashes

	push	edi		; ( addr )
	
	add	edi, edx	;
	dec	edi		; edi : = last character in string

	mov	ecx, edx	 
	mov	al, "/"
	repne	scasb

.if:	pop	edi		;exit orderly...
	jnz	.then		;no more "/"-s
	test	ecx,ecx		;leave just "/"
    	jnz	.else
	inc	ecx
.else:				
	mov	edx, ecx
	call	Strip_trailing_slashes

	dec edx
.lf:
	inc edx

	mov	byte [edx+edi], lf
	inc	edx
	sys_write STDOUT, edi, edx
	sys_exit
.then:

	sys_write STDOUT, dot, len_dot

.exit:
	sys_exit


dot	db	'.', lf
len_dot	equ $ - dot

;
;Return string length
;
;>EDI
;<EDX
;Regs: none ;)
StrLen:
        mov     edx,edi
        dec     edx
.l1:
        inc     edx
        cmp     [edx],byte 0
        jnz     .l1
        sub     edx,edi
        ret

;============================================================================
; Strip_trailing_slashes - remove all "/" characters in the end of the string
;============================================================================
;In:	edi - addr of string
;	edx - length of string
;	edi - addr of string
;Out:	edx - new length of the string
;============================================================================
Strip_trailing_slashes:
	push	eax
	
	mov	al, "/"
	xchg	edi, edx
	add	edi, edx
	dec	edi
	std

.loop:
	cmp	edi, edx
	je	.end
	scasb
	je	.loop
	inc	edi
.end:
	sub	edi, edx
	inc	edi
	xchg	edi, edx

	pop	eax
	ret

END
