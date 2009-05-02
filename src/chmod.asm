;Copyright (C) 2000-2002 Konstantin Boldyshev <konst@linuxassembly.org>
;
;$Id: chmod.asm,v 1.4 2002/10/09 18:04:10 konst Exp $
;
;hackers' chmod
;
;syntax: chmod MODE [FILE...]
;
;only octal mode strings are suppoted (e.g. 755)
;
;0.01: 10-Jan-2000	initial release
;0.02: 09-Oct-2002	fixed "chmod 4755" bug (KB)

%include "system.inc"

CODESEG

START:
	pop	ebx
	_cmp	ebx,3
	jb	.exit

	pop	esi
	pop	esi

	call	parse_mode_string
	_cmp	eax,-1
	jz	.exit

	mov	ecx,eax

.next_file:
	pop	ebx
	or	ebx,ebx
	jz	.exit
	sys_chmod
	jmps	.next_file
.exit:
	sys_exit eax


;
;
;

;<edi	-	modestring
;>eax	-	mode

parse_mode_string:

%assign	MODE_NONE	00000000b
%assign	MODE_XIFX	00000001b
%assign	MODE_COPY	00000010b

	push	edi
	push	esi
	push	edx
	push	ecx
	push	ebx

	mov	edx,esi
	xor	ecx,ecx
	xor	eax,eax
	_mov	ebx,8

.next:
	mov	cl,[esi]
	or	cl,cl
	jz	.done_ok
	sub	cl,'0'
	jb	.done_err
	cmp	cl,7
	ja	.done_err
	mul	bx
	add	eax,ecx
	inc	esi
	jmps	.next

.done_ok:
	cmp	edx,esi
	jnz	.return

.done_err:

%ifdef PARSE_SYMBOLIC_MODESTRING
	xor	ebp,ebp
	mov	esi,edx

.cmp_who:
	lodsb
	_mov	ecx,4
	_mov	edi,who
	call	.compare
	jc	.cmp_what1
	or	ebp,[who_c + ebx]
	jmps	cmp_who

.cmp_what:
	lodsb
.cmp_what1:
	_mov	ecx,3
	_mov	edi,what
	call	.compare
	jc	.cmp_mode1

.cmp_mode:
	lodsb
.cmp_mode1:
	_mov	ecx,9
	_mov	edi,mode
	call	.compare
	jc	.cmp_done
	or	ebp, [mode_c + ebx]
.cmp_done:

%else
	xor	eax,eax
	dec	eax
%endif

.return:
	pop	ebx
	pop	ecx
	pop	edx
	pop	esi
	pop	edi
	ret


%ifdef PARSE_SYMBOLIC_MODESTRING

.compare:
	xor	ebx,ebx
.cmp_loop:
	cmp	al,[edi + ebx]
	clc
	jz	.done
	inc	ebx
	loop	.cmp_loop
	stc
.done:
	ret

what	db	"+-="
mode	db	"rwxXst"
who	db	"ugoa"
mode_c	dd	0444q,0222q,0111q,0111q,6000q,1000q,
	dd	0700q,0070q,0007q
mode_f	db	MODE_NONE,MODE_NONE,MODE_NONE,MODE_XIFX,MODE_NONE,MODE_NONE
	db	MODE_COPY,MODE_COPY,MODE_COPY
who_c	dd	4700q,2070q,1007q,7777q

%endif

END
