;Copyright (C) 2001 Thomas M. Ogrisegg <tom@rhadamanthys.org>
;
;$Id: mesg.asm,v 1.4 2002/02/14 13:38:15 konst Exp $
;
;syntax: mesg [y|n]
;
;control write access to your terminal

%include "system.inc"

%assign BUFSIZE 0x100

CODESEG

START:
	sys_readlink fd0, buf, BUFSIZE
	test eax, eax
	js do_exit

	xor eax, eax
	sys_stat buf, statbuf
	mov eax, [ecx+Stat.st_mode]
	add esp, 8
	pop ebx
	test ebx, ebx
	jnz _chmod

	and eax, 16
	cmp eax, 16
	jnz isn
	mov ecx, yes
	jmp _write
isn:
	mov ecx, no
_write:
	sys_write STDOUT, ecx, 5

do_exit:
	sys_exit eax

_chmod:
	cmp byte [ebx], 'n'
	jz _no
	cmp byte [ebx], 'y'
	jnz do_exit
	or eax, 16
	jmp __do_chmod
_no:
	or eax, 16
	xor eax, 16
__do_chmod:
	sys_chmod buf, eax
	jmp do_exit

yes	db	"is y", __n
no	db	"is n", __n
fd0	db	"/proc/self/fd/0"

UDATASEG

buf	resb BUFSIZE
statbuf B_STRUC Stat, .st_mode

END
