;Copyright (C) 1999 Konstantin Boldyshev <konst@linuxassembly.org>
;
;$Id: echo.asm,v 1.5 2000/12/10 08:20:36 konst Exp $
;
;hackers' echo		[GNU replacement]
;
;syntax: echo [OPTION] [STRING ...]
;
;-n	do not add newline
;-e	interpretation of the following backslash-escaped characters:
;	\a	alert (bell)
;	\b	backspace
;	\e	escape
;	\c	suppress trailing newline
;	\f	form feed
;	\n	new line
;	\r	carriage return
;	\t	horizontal tab
;	\v	vertical tab
;	\\	backslash
;	\num	the character whose ASCII code is NUM (octal).
;-E	explicitly turn off above -e interpretation
;
;example: echo -e "\tHello, world!\a"
;
;0.01: 17-Jun-1999	initial release
;0.02: 04-Jul-1999	small bugfixes
;0.03: 19-Dec-1999	-eE support and full GNU compliance
;0.04: 08-Feb-2000	\e added ( but what for? :)
;0.05: 17-Sep-2000	removed trailing '\0'


%include "system.inc"

CODESEG

%assign BufSize	0x4000
%assign _n	00000001b
%assign _e	00000010b
%assign _E	00000100b

e_num	equ	8
e_asc	db	"abefnrtv"
e_bin	db	__a, __b, __e, __f, __n, __r, __t, __v

START:
	_mov	edi,Buf
	_mov	ebp,edi

	pop	ebx
	dec	ebx
	jz	.final

	pop	ebx

.arguments:
	pop	ebx
	mov	esi,ebx

	or	esi,esi
	jnz	.a

.final:
	dec	edi
	mov	edx,edi
	sub	edx,ebp
	or	edx,edx
	jz	.check_n
	dec	edi
	dec	edx

.check_n:
	test	[flag],byte _n
	jnz	.write_string

	mov	al,__n
	stosb
	inc	edx

.write_string:
	sys_write STDOUT,ebp

.exit:
	sys_exit_true

.a:
	lodsb
	cmp	al,'-'
	jnz	.end_of_args

	xor	dh,dh		;flag

.check_args:
	lodsb

	or	al,al
	jnz	.switches
	or	dh,dh
	jz	.end_of_args

	or	[flag],dh
	jmp	short .arguments

.switches:
	mov	dl,_n
	cmp	al,'n'
	jz	.found_arg
	mov	dl,_e
	cmp	al,'e'
	jz	.found_arg
	mov	dl,_E
	cmp	al,'E'
	jz	.found_arg
	xor	dh,dh
	jmp	short .end_of_args

.found_arg:
	or	dh,dl
	jmp	short .check_args
	
;
;
;

.parse_loop:

	pop	ebx

.end_of_args:

	mov	esi,ebx

	or	esi,esi
	jz	.final

.parse:
	lodsb

	xor	ebx,ebx
	mov	dl,[flag]
	test	dl,_E
	jnz	.store
	test	dl,_e
	jz	.store

;escape sequence parsing

	cmp	al,'\'
	jnz	.store
	lodsb
	cmp	al,'\'
	jz	.store

	cmp	al,'c'
	jnz	.esc
	or	[flag], byte _n
	jmp	short .parse

.esc:
	push	edi
	_mov	ecx,e_num
	_mov	edx,ecx
	_mov	edi,e_asc
	repnz	scasb
	jnz	.octal
	
	inc	ecx
	sub	edx,ecx
	mov	al,[e_bin + edx]
	pop	edi
	jmp	short .store

.octal:
	pop	edi

	push	eax
	xor	edx,edx
	mov	cx,0x0800

.next_octal_digit:
	cmp	al,'0'
	jb	.done_octal
	cmp	al,'7'
	ja	.done_octal

	sub	al,'0'
	mov	dh,al
	mov	al,dl
	mul	ch
	mov	dl,al
	add	dl,dh
	
	cmp	cl,2
	jnz	.next_char
	mov	cl,-1
	jmp	short .done_octal

.next_char:
	lodsb
	inc	ecx
	jmp	short .next_octal_digit

.no_esc:
	push	eax
	mov	al,'\'
	stosb
	pop	eax

.store:
	stosb
	or	al,al
	jnz	.parse
	or	ebx,ebx
	jnz	.parse
	mov	al,' '
	stosb
	jmp	.parse_loop

.done_octal:
	pop	eax

	or	cl,cl
	jz	.no_esc

	cmp	cl,-1
	jz	.restore_orig

	dec	esi

.restore_orig:
	mov	al,dl
	or	al,al
	jnz	.store
	inc	ebx
	jmps	.store

UDATASEG

flag	resb	1
Buf	resb	BufSize

END
