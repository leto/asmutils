; Copyright (C) 2002 Thomas M. Ogrisegg
;
; getty - show login prompt
;
; syntax:
;       getty tty-device
;
; License           :       GNU General Public License
; Author            :       Thomas Ogrisegg
; E-Mail            :       tom@rhadamanthys.org
; Version           :       1.0
; Created           :       06/06/02
;
; $Id: getty.asm,v 1.2 2006/02/09 08:02:57 konst Exp $
;
; This getty (as most others) expects a /bin/login program to 
; do the actual authentication.
;

%include "system.inc"

%ifdef __LINUX__
%define HAVE_VHANGUP
%define WANT_CLEAR
%endif

CODESEG

__issue	db	"/etc/issue", NULL
__dev	db	"/dev", NULL
__login	db	"/bin/login", NULL
__ddash	db	"--", NULL
__clear	db	0x1b,"[H",0x1b,"[J"

issue:
	mov edi, iobuf
	sys_open __issue, O_RDONLY
	or eax, eax
	js near .Lret
	mov ebp, eax
	push ebp
	sys_lseek eax, 0, SEEK_END
	or eax, eax
	js near .Lret
	push eax
	push edi
	sys_mmap NULL, eax, PROT_READ, MAP_PRIVATE, ebp, 0
	pop edi
	push eax
	or eax, eax
	js near .Lret
	mov esi, eax
	;; Just like other getty's...
	mov al, __n
	stosb
.Liloop:
	lodsb
	or al, al
	jz near .Lmapret
	cmp al, '\'
	jnz near .Lstos
	lodsb
	cmp al, 's'
	jnz .Lnext1
	mov eax, uname.sysname
	jmp .Lstrcpy
.Lnext1:
	cmp al, 'n'
	jnz .Lnext2
	mov eax, uname.nodename
	jmp .Lstrcpy
.Lnext2:
	cmp al, 'm'
	jnz .Lnext3
	mov eax, uname.machine
	jmp .Lstrcpy
.Lnext3:
	cmp al, 'o'
	jnz .Lnext4
	mov eax, uname.domainname
	jmp .Lstrcpy
.Lnext4:
	cmp al, 'r'
	jnz .Lnext5
	mov eax, uname.release
	jmp .Lstrcpy
.Lnext5:
	cmp al, 'v'
	jnz .Lnext6
	mov eax, uname.version
	jmp .Lstrcpy
.Lnext6:
	cmp al, 'l'
	jnz .Lstos
	mov eax, [tty]
	jmp .Lstrcpy
.Lstrcpy:
	push esi
	mov esi, eax
.Llabel:
        lodsb
        stosb
        or al, al
        jnz .Llabel
        dec edi
	pop esi
	jmp .Liloop
.Lstos:
	stosb
	jmp .Liloop
.Lmapret:
	pop eax
	pop ebx
	sys_munmap eax, ebx
	pop eax
	sys_close eax
.Lret:
	mov esi, uname.nodename
.Lcopy:
	lodsb
	stosb
	or al, al
	jnz .Lcopy
	dec edi
.Lcopy2:
	mov long [edi], ' log'
	mov long [edi+4], 'in: '
	add edi, 8

	ret

START:
	pop ecx
	lea eax, [esp+ecx*4+4]
	mov [envp], eax
	dec ecx
	jz near exit
	pop esi
	pop long [tty]
	sys_uname uname
	sys_signal SIGHUP, SIG_IGN
%ifdef HAVE_VHANGUP
	sys_vhangup
%endif
	sys_close STDIN
	sys_close STDOUT
	sys_close STDERR
	sys_chdir __dev
	sys_open [tty], O_RDWR
	or eax, eax
	js near exit
	jnz near exit
	sys_dup STDIN
	sys_dup STDIN
	sys_fchmod STDIN, 0600
%ifdef WANT_CLEAR
	sys_write STDOUT, __clear, 6
%endif
	call issue
;	lea edx, [edi-iobuf]
	mov edx,edi
	sub edx,iobuf
	sys_write STDOUT, iobuf
	sys_setsid
	sys_read STDIN, iobuf, 0x200
	or eax, eax
	js exit
	mov byte [iobuf+eax-1], 0
	push long NULL
	push long iobuf
	push long __ddash
	push long __login
	mov edi, esp
	sys_execve __login, edi, [envp]
exit:
	sys_exit 0

UDATASEG
issmap	ULONG	1
maplen	ULONG	1
tty	ULONG	1
envp	ULONG	1
uname	B_STRUC	utsname,.sysname,.nodename,.release,.version,.machine,.domainname
iobuf	UCHAR	0x200
END
