;Copyright (C) 1999-2002 Konstantin Boldyshev <konst@linuxassembly.org>
;
;$Id: asmutils.asm,v 1.6 2006/02/09 07:42:11 konst Exp $
;
;asmutils multicall binary
;
;0.03: 17-Jan-2001	initial public release
;0.04: 06-Jun-2002	fixed startup stack, call for script-writers

%include "system.inc"

CODESEG

names:

dd	"arch",	_uname
dd	"base",	_basename
dd	"echo",	_echo
dd	"fact",	_factor
dd	"fals",	_true
dd	"kill",	_kill
dd	"pwd",	_pwd
dd	"slee",	_sleep
dd	"sync",	_sync
dd	"tee",	_tee
dd	"true",	_true
dd	"unam",	_uname
dd	"yes",	_yes

START:
	push	eax
	pusha
	mov	esi,[esp + 4*9 + 4]
	mov	ebx,esi
.n1:
	lodsb
	or 	al,al
	jnz	.n1
.n2:
	dec	esi
	cmp	ebx,esi
	jz	.n3
	cmp	byte [esi],'/'	
	jnz	.n2
	inc	esi	
.n3:

	xor	ebx,ebx
.find_name:
	mov	eax,[ebx + names]
	or	eax,eax
	jz	.exit
	cmp	eax,[esi]
	jz	.run_it
	add	ebx,byte 8
	jmps	.find_name

.run_it:
	
	mov	eax,[ebx + names + 4]
	mov	[esp + 4*8],eax
	popa
	ret

.exit:

	sys_write STDOUT, poem, length
	sys_exit 0

;
;
;

poem	db	__n
	db	"this is not a nasty bug",__n
	db	"this is just a cool loopback",__n
	db	__n
	db	__t,"- an ancient assembly poem -",__n
	db	__t,"(by an ancient assembly poet)",__n
	db	__n
	db	"This eventually will be the asmutils multicall binary.",__n
	db	"The whole idea behind it is that it should be auto-generated",__n
	db	"from other .asm files (and of course startup code) with some",__n
	db	"script with no manual adjustments,  when other programs will",__n
	db	"be in a more-or-less usable and reliable state.  The day has",__n
	db	"not come yet, but it is closer with each release. Meanwhile,",__n
	db	"do not waste your time on improving this source code, better",__n
	db	"be the one who implements the above described script.",__n,__n
length	equ	$-poem

_uname:
_basename:
_echo:
_factor:
_true:
_kill:
_pwd:
_sleep:
_sync:
_tee:
_yes:

;write applet name to stdout
	pop	eax

	pop	esi
	mov	ecx,esi
.n1:
	lodsb
	or 	al,al
	jnz	.n1
.n2:
	mov	byte [esi - 1],__n
	sub	esi,ecx
	sys_write STDOUT,EMPTY,esi

	sys_exit 1

END
