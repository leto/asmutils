; Copyright (C) 2001 Thomas M. Ogrisegg
;
; write utility
;
; usage: write user [tty]
;
; BUGS/TODO:
;   Improve diagnostic messages
;   using mmap would be smarter...
;
; 06/07/02: added printing of username on the target terminal (TO)
;
; $Id: write.asm,v 1.4 2002/06/11 08:41:06 konst Exp $

%include "system.inc"

%assign BUFLEN 0x100

CODESEG

usage:
	sys_write STDOUT, helptxt, helplen
	sys_exit 0x1

START:
	pop ecx
	cmp ecx, byte 3
	jg usage
	cmp ecx, byte 1
	jz usage

	lea esi, [esp+ecx*4+4]
search_user:
	lodsd
	or eax, eax
	jz .Lout
	cmp long [eax], 'USER'
	jnz search_user
	add eax, 5
	cmp byte [eax-1], '='
	jnz search_user
	mov [user], eax
.Lout:

	pop eax
	pop esi
	mov edi, esi
	pop long [ttyname]

	push esi
	mov ecx, 32
	mov edx, ecx
	xor eax, eax
	repnz scasb
	sub ecx, edx
	not ecx
	test ecx, ecx
	jz near error ; exit
	push ecx

	sys_open utmpfile, O_RDONLY, 0
	mov [fd], eax

	sys_chdir devdir

_loop:
	sys_read [fd], utmpbuf, utmp_size
	or eax, eax
	jz near error ; exit
	lea edi, [utmpbuf+utmp.ut_user]
	mov esi, [esp+4]
	mov ecx, [esp]
	repz cmpsb
	or ecx, ecx
	jnz _loop

do_write:
	lea ebx, [utmpbuf+utmp.ut_line]
	mov esi, [ttyname]
	or esi, esi
	jz next_write
	mov edi, ebx
	mov ecx, 6
	repz cmpsb
	
	or ecx, ecx
	jnz _loop
	
next_write:
	sys_open ebx, O_WRONLY
	cmp eax, 0
	jg Next
	mov ecx, [ttyname]
	or ecx, ecx
	jz _loop
	jmp noperm
Next:
	mov [ttyfd], eax

	mov edi, buffer
	mov esi, message
	mov ecx, messagelen
	repnz movsb
	mov esi, [user]
	or esi, esi
	jz .Lnext
.Llabel:
	lodsb
	stosb
	or al, al
	jnz .Llabel
	mov byte [edi], __n
;	lea ecx, [edi-buffer]
	mov ecx, edi
	sub ecx, buffer
	sys_write [ttyfd], buffer, ecx
.Lnext:
	sys_write [ttyfd], beep, beeplen

io_loop:
	sys_read STDIN, buffer, BUFLEN
	_mov ebx,[ttyfd]
	test eax, eax
	jz eof
	sys_write EMPTY, buffer, eax
	jmps io_loop

eof:
	_mov ecx,EOF
	_mov edx,eoflen
	jmps do_exit

noperm:
	_mov ebx,STDERR
	_mov ecx,perm
	_mov edx,permlen
	jmps do_exit

error:
	_mov ebx,STDERR
	_mov ecx,nologin
	_mov edx,nologlen

do_exit:
	sys_write
	sys_exit 0x0

helptxt	db	"Usage: write user [ttyname]", __n
helplen	equ $ - helptxt

nologin db	"User not logged in or permission denied", __n
nologlen equ $ - nologin

perm	db	"Permission denied", __n
permlen equ $ - perm

utmpfile db _PATH_UTMP, EOL
devdir	db	"/dev", EOL

EOF		db	"EOF", __n
eoflen equ $ - EOF

message	db	"Message from "
messagelen  equ $ - message
beep	db	0x1B, 0x5B, 0x6D, 0x1B, 0x5B, 0x34, 0x6C, 0x07, __n
beeplen equ $ - beep

UDATASEG
ttyname	ULONG	1
user	ULONG	1
fd	ULONG	1
ttyfd	ULONG	1
utmpbuf B_STRUC utmp
buffer	UCHAR	BUFLEN
END
