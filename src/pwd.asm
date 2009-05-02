;Copyright (C) 1999-2002 Konstantin Boldyshev <konst@linuxassembly.org>
;Copyright (C) 1999 Yuri Ivliev <yuru@black.cat.kazan.su>
;
;$Id: pwd.asm,v 1.9 2002/03/14 17:42:08 konst Exp $
;
;hackers' pwd
;
;syntax: pwd
;
;0.01: 05-Jun-1999	initial release (KB)
;0.02: 17-Jun-1999	size improvements (KB)
;0.03: 04-Jul-1999	Linux 2.0 stat-based part added (YI)
;0.04: 18-Sep-1999	elf macros support (KB)
;0.05: 17-Dec-1999	size improvements (KB)
;0.06: 08-Feb-2000	(KB)
;0.07: 21-Aug-2000	STAT_PWD define (KB)
;0.08: 14-Mar-2002	bugfixes, syscall optimization, and portability fixes
;			in stat-based version (KB)

%include "system.inc"

%ifdef __LINUX__
%if __KERNEL__ <= 20
%define STAT_PWD
%endif
%endif

%ifdef __OPENBSD__
%define STAT_PWD	;no getcwd :(
%endif

%assign	PATHSIZE	0x100
%assign	BUFSIZE		0x1000

CODESEG

START:

%ifdef STAT_PWD

%assign	lBackPath	0x00000040

;;getting root's inode and block device
	sys_lstat Root.path,st		;get stat for root
	mov	eax,[ecx+Stat.st_dev]
	mov	[Root.st_dev],eax
	mov	eax,[ecx+Stat.st_ino]
	mov	[Root.st_ino],eax
;;data initialization
	mov	ebp,BackPath		;ebp - current position in BackPath
	mov	dword [ebp],'./'	;we are starting from current dir
	mov	edi,path+PATHSIZE-1	;edi - current position in Path - 1
	mov	byte [edi], __n		;NL at the end of Path
	dec	edi
;;the begin of up to root loop
.up:
	sys_lstat BackPath,st		;get stat for current location
	test	eax,eax
	js	.exit
	mov	byte [edi],'/'
	dec	edi
	mov	eax,[ecx+Stat.st_dev]
	cmp	eax,[Root.st_dev]	;is our block device roots'?
	jne	.continue		;no
	mov	eax,[ecx+Stat.st_ino]
	cmp	eax,[Root.st_ino]	;is our inode roots'?
	jne	.continue		;no
;;the begin of exit pwd
	inc	edi			;yes, pwd comptete
	mov	esi,path+PATHSIZE-2
	mov	edx,esi
	sub	edx,edi			;is "/" our current dir?
	jz	.print			;yes
	mov	byte [esi],__n		;no, remove leading slash
	dec	edx
.print:
	inc	edx
	inc	edx
	sys_write STDOUT,edi		;print work dir
.exit:
	sys_exit_true			;and go out
;; the end of exit pwd
.continue:
	mov	dword [ebp],'../'	;move current location up
	lea	ebp,[ebp+3] 
	mov	ax,[ecx+Stat.st_dev]
	mov	[Dev],ax		;save block device for prev location
	mov	eax,[ecx+Stat.st_ino]
	mov	[Inode],eax		;save inode for prev location
	sys_open BackPath,O_RDONLY	;open current location
	test	eax,eax
	js	.exit
	mov	edx,eax
;; start of get directory entry loop
.get_de:
	mov	ebx,edx
%ifdef	__BSD__
	sys_getdirentries EMPTY,buf,BUFSIZE,st	;get current dirent
%else
	sys_getdents EMPTY,buf,BUFSIZE		;get current dirent
%endif
	test	eax,eax
	jle	near .exit
	mov	[de_num],eax			;save dirents size
	mov	edx,ebx
	mov	esi,ecx				;esi - pointer to dirent
.next_de:
	;concatenate current location and current dirent name
;;;;	mov	ecx,ebp
;;;;	lea	ebx,[esi+dirent.d_name]
	mov	ebx,ebp
	xor	ecx,ecx
.next.d_name.1:
;;;;	mov	al,[ebx]
;;;;	inc	ebx
	mov	al,[esi+ecx+dirent.d_name]
;;;;	mov	[ecx],al
	mov	[ebx+ecx],al
	inc	ecx
	or	al,al
	jnz	.next.d_name.1
	sys_lstat BackPath,st		;get stat for current dirent
	test	eax,eax
	js	near .exit
	mov	ax,[ecx+Stat.st_dev]
	cmp	ax,[Dev]		;is this block device ours'
	jne	.done_de		;no, try next dirent
	mov	eax,[ecx+Stat.st_ino]
	cmp	eax,[Inode]		;is this inode ours'
	jne	.done_de		;no, try next dirent
;; the end of get directory entry loop
	sys_close edx			;close current location
	mov	[ebp],al
	lea	esi,[esi+dirent.d_name]
;;;;	mov	ebx,esi
	xor	ecx,ecx
.next.d_name.2:
;;;;	inc	esi
;;;;	cmp	al,[esi]
	inc	ecx
	cmp	al,[esi+ecx]
	jc	.next.d_name.2
;;;;	mov	ecx,esi
;;;;	sub	ecx,ebx
;;;;	dec	esi
	lea	esi,[esi+ecx-1]
	std
	rep	movsb
	jmp	.up

.done_de:
	movzx	ecx,word [esi+dirent.d_reclen]
	add	esi,ecx
	sub	[de_num],ecx
	jg	.next_de
	jmp	.get_de

;; the end of up to root loop

Root.path	db	'/',EOL

%else

	sys_getcwd path,PATHSIZE

	mov	esi,ebx
	xor	edx,edx
.next:
	inc	edx
	lodsb
	or	al,al
	jnz	.next
	mov	byte [esi-1],__n
	sub	esi,edx
	sys_write	STDOUT,esi
	sys_exit_true
%endif


UDATASEG

path		resb	PATHSIZE	;path buffer

%ifdef STAT_PWD

BackPath	CHAR	lBackPath	;back path buffer

Dev		UINT	1
Root.st_dev	UINT	1
Inode		UINT	1
Root.st_ino	UINT	1

st	B_STRUC Stat,.st_dev,.st_ino

de_num		resd	1
buf		resb	0x1000

%endif

END
