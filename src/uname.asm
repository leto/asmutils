;Copyright (C) 1999-2001 Konstantin Boldyshev <konst@linuxassembly.org>
;
;$Id: uname.asm,v 1.9 2002/02/02 08:49:25 konst Exp $
;
;hackers' uname/arch	[GNU replacement]
;
;syntax: uname [-snrvma]
;	 arch (same as uname -m)
;
;-s	os name (default)
;-n	network nodename
;-r	os release
;-v	os version
;-m	machine (hardware) type
;-p	processor (supported only in sysctl based version)
;-a	all the above information
;
;0.01: 17-Jun-1999	initial release
;0.02: 03-Jul-1999	arch support
;0.03: 18-Sep-1999	elf macros support
;0.04: 03-Sep-2000	portable utsname
;0.05: 22-Oct-2000	sysctl based part (TH),
;			size improvemets (KB)
;0.06: 04-Mar-2001	use B_STRUC (KB)
;0.07: 03-Dec-2001	various sysctl fixes on BSD (KB)

%include "system.inc"

%ifdef __BSD__
%define USE_SYSCTL
%endif

%assign	SYSNAME		00000001b
%assign	NODENAME	00000010b
%assign	RELEASE		00000100b
%assign	VERSION		00001000b
%assign	MACHINE		00010000b
%assign PROCESSOR	00100000b

%ifdef USE_SYSCTL
%assign BUF_LEN		128
%assign	ARGC	6
%else
%assign	ARGC	5
%endif

CODESEG

keys	db	"snrvmp"
lf	db	__n

;
;edi	-	switches flag
;

START:
	pop	ebx
	pop	esi
	dec	ebx
	jnz	args

	mov	dl,SYSNAME	;default
.n1:				;how we are called?
	lodsb
	or 	al,al
	jnz	.n1
	cmp	dword [esi-5],'arch'
	jnz	get_uname
	mov	dl,MACHINE	;we are called as arch
	jmps	get_uname

args:
	pop	esi
	lodsb
	cmp	al,'-'
	jnz	near do_exit

.inner_stage:
	lodsb
	or	al,al
	jz	.check
.scan_other:
	_mov	ecx,ARGC
	_mov	edi,keys
	mov	ebp,edi
	repnz	scasb
	jnz	.a
	dec	edi
	sub	edi,ebp
	mov	ecx,edi
	bts	edx,ecx
	jmps	.inner_stage
.a:
	cmp	al,'a'
	jnz	near do_exit
	mov	dl,SYSNAME|NODENAME|RELEASE|VERSION|MACHINE|PROCESSOR
	jmps	.inner_stage

.check:
	or	dl,dl
	jz	near do_exit

	dec	ebx
	jnz	args

get_uname:

	_mov	ecx,ARGC
	mov	edi,edx

%ifdef	USE_SYSCTL

	_mov	ebp,req_start

%else

	sys_uname h
	mov	ebp,ebx

%endif

.printinfo:
	shr	edi, 1
	jnc	.skip

	push	ecx

	mov	ecx,space
	cmp	[ecx],byte 0
	jz	.first_entry
	sys_write STDOUT,space,1
.first_entry:
	mov	[ecx],byte 0x20

%ifdef	USE_SYSCTL

	mov	dword [oldlenp], BUF_LEN
	pusha
	mov	ebx,ebp
	sys_sysctl	EMPTY, 2, buffer, oldlenp, 0, 0
	test	eax,eax
	js	.skip_write
	mov	eax,[oldlenp]
	dec	eax
	sys_write	STDOUT, buffer, eax
.skip_write:
	popa

%else

	mov	esi,ebp
	xor	edx,edx
.next:
	lodsb
	inc	edx
	or	al,al
	jnz	.next
	sub	esi,edx
	dec	edx

	sys_write	STDOUT,esi

%endif

	pop	ecx

.skip:
%ifdef	USE_SYSCTL
	_add	ebp,8
%else
	_add	ebp,SYS_NMLN
%endif
	loop	.printinfo

do_exit:
	sys_write	EMPTY, lf, 1
	sys_exit	0


%ifdef USE_SYSCTL
req_start:
kern_ostype_req:
	dd	CTL_KERN
	dd	KERN_OSTYPE
kern_hostname_req:
	dd	CTL_KERN
	dd	KERN_HOSTNAME
kern_osrelease_req:
	dd	CTL_KERN
	dd	KERN_OSRELEASE
kern_osversion_req:
	dd	CTL_KERN
	dd	KERN_VERSION
hw_machine_req:
	dd	CTL_HW
	dd	HW_MACHINE
hw_model_req:
	dd	CTL_HW
	dd	HW_MODEL
req_end:
%endif

UDATASEG

space	resb	1

%ifdef USE_SYSCTL

oldlenp		DWORD	1
buffer		CHAR	BUF_LEN

%else

h B_STRUC utsname,.sysname,.nodename,.release,.version,.machine,.domainname

%endif

END
