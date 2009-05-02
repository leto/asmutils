;Copyright (C) 1999-2001 Konstantin Boldyshev <konst@linuxassembly.org>
;
;$Id: hostname.asm,v 1.8 2002/02/02 08:49:25 konst Exp $
;
;hackers' hostname/domainname
;
;syntax: hostname [name]
;	 domainname [name]
;
;if name parameter is omited it displays name, else sets it to name
;you must be root to set host/domain name
;
;0.01: 05-Jun-1999	initial release
;0.02: 17-Jun-1999	size improvements
;0.03: 04-Jun-1999	domainname added
;0.04: 18-Sep-1999	elf macros support 
;0.05: 03-Sep-2000	portable utsname, BSD port
;0.06: 04-Mar-2001	size improvements
;0.07: 03-Dec-2001	sysctl-based version

%include "system.inc"

;NOTE: sysctl-based version works on Linux as well;
;however, as sysctl support can be disabled in Linux kernel,
;sysctl-based version is not used by default on Linux.

%ifdef	__BSD__
%define	USE_SYSCTL
%endif

CODESEG

START:
	xor	edi,edi			;{host|domain}name flag

	pop	ebx
	pop	esi
.n1:
	lodsb
	or 	al,al
	jnz	.n1
	cmp	dword [esi-9],'host'
	jz	.n2
	inc	edi			;we are called as domainname
.n2:
	dec	ebx
	jz	.getname		;no parameters, write current name

	pop	ebx			;name parameter

	mov	esi,ebx			;calculate name length in esi
.n3:
	lodsb
	or	al,al
	jnz	.n3
	sub	esi,ebx
	dec	esi

%ifdef	USE_SYSCTL

	mov	eax,kern_hostname_req
	dec	edi
	jnz	.sysctl_set
	add	eax,byte 8
.sysctl_set:
	sys_sysctl eax, 2, 0, 0, ebx, esi

%else

	mov	ecx,esi
	dec	edi
	jz	.setdomain
	sys_sethostname
	jmps	.done_set
.setdomain:
	sys_setdomainname

%endif

.done_set:
	jmps	do_exit

.getname:

%ifdef USE_SYSCTL

	mov	dword [len],SYS_NMLN*2
	mov	eax,kern_hostname_req
	mov	edx,buf
	dec	edi
	jnz	.sysctl_get
	add	eax,byte 8
.sysctl_get:
	sys_sysctl	eax, 2, edx, len, 0, 0
	test	eax,eax
	js	do_exit
	mov	esi,edx

%else

	mov	esi,h
	sys_uname esi
	_add	esi,utsname.nodename
	dec	edi
	jnz	.done_get
	_add	esi,utsname.domainname-utsname.nodename

%endif

.done_get:				;esi should point to name buffer

	xor	edx,edx
.strlen:
	lodsb
	inc	edx
	or	al,al
	jnz	.strlen
	mov	byte [esi-1],__n
	sub	esi,edx
	sys_write STDOUT,esi
	xor	eax,eax
do_exit:
	sys_exit eax

%ifdef	USE_SYSCTL
kern_hostname_req:
	dd	CTL_KERN
	dd	KERN_HOSTNAME
kern_domainname_req:
	dd	CTL_KERN
	dd	KERN_DOMAINNAME
%endif

UDATASEG

%ifdef	USE_SYSCTL

len	resd	1
buf	resb	SYS_NMLN*2

%else

h B_STRUC utsname,.nodename,.domainname

%endif

END
