; Copyright (c) 2001 Thomas M. Ogrisegg <tom@rhadamanthys.org>
;
; $Id: rot13.asm,v 1.3 2002/02/14 13:38:15 konst Exp $
;
; Enc/Decrypt strings by rotating characters (with 13).
; Often used in Usenet articles
;
; syntax: rot13

%include "system.inc"

%assign BUFSIZE 80

CODESEG

START:
	sub esp, BUFSIZE ;84

IOLoop:
	sys_read STDIN, esp, BUFSIZE ;84
	or eax, eax
	jz do_exit
	mov ebp, eax
	mov ecx, eax
	mov esi, esp
	mov edi, esi
	jmp xloop
rotloop:
	stosb
	dec ecx
	jz _out
xloop:
	lodsb
	cmp al, 'A'
	jnge rotloop
	cmp al, 'z'
	jg rotloop
	cmp al, 'Z'
	jng ok
	cmp al, 'a'
	jnge rotloop
ok:
	cmp al, 'M' 
	jng lower
	cmp al, 'Z'
	jng over
	cmp al, 'm'
	jng lower
	cmp al, 'z'
	jng over
	jmp rotloop
lower:		; %al == a-m, A-M
	add al, 13
	jmp rotloop
over:		; %al == n-z, N-Z
	sub al, 13
	jmp rotloop

_out:
	sys_write STDOUT, esp, ebp
	jmp IOLoop
do_exit:
	sys_exit eax

END
