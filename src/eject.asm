;Copyright (C) 1999 Bart Hanssens <antares@mail.dma.be>
;Copyright (C) 2000 H-Peter Recktenwald <phpr@snafu.de>
;
;$Id: eject.asm,v 1.5 2000/09/03 16:13:54 konst Exp $
;
;hackers' eject/ccd (eject CD-ROM)
;
;0.01: 29-Jul-1999	initial release
;0.10: 06-Apr-2000	ccd extension
;0.11: 06-May-2000	cleanup
;
;syntax: eject [device]
;        ccd [device [mountpoint [filesys [options]]]]
;
;if no device is given, use /dev/cdrom
; ----------------------------------------------------------------
; -ccd extension by H-Peter Recktenwald, Berlin <phpr@snafu.de>
;	file  	: eject.asm
;	started	: 0.00	15-jan-2000
;	version	: 0.10	06-mai-2000
;
; eject -ccd ("Change CD rom"):
;	un-mount cdrom, eject, wait for <enter>, re-mount
;
; syntax:
;	eject [specialfile]
;	eject -ccd [specialfile [mountpoint [filesys [options]]]]
; defaults:
; 	specialfile:	'/dev/cdrom'
;	mountpoint:	'/cdrom'
;	filesys:	'iso9660'
; 	options:	0 (binary! re below)
; exit code
;	is from device open.
;
; ccd
;	eject linked to 'ccd' executes 'eject' in -ccd mode w.o.
;	that option switch being passed (re compile options).
;
; bugs/mis-features:
; 1:	mountoptions argument raw binary only, ascii coded string
;	input left an exercise to the user, not required for -ccd.
; 2:	re-mounting doesn't update 'mtab', thus <df> etc might be
;	mislead. 'cat /proc/mounts' for the actual information.
; 3:	despite the many compile switches tried to keep the source
;	readble, with limited success...
; ----------------------------------------------------------------
; compile options:
;	(no option)	compile just the <eject> syscall
;	SYS_EJECT	disable (clear) any other options
;	ONLY_CCD	compile ccd only mode
;	WITH_CCD	compile with optional ccd mode
;	LINK_CCD	eject linked to ccd aliasing eject -ccd
; options priority:
;	SYS_EJECT	sys_open/ioctl (eject), only
;	ONLY_CCD	implies WITH_CCD, inhibits LINK_CCD
;	LINK_CCD	implies WITH_CCD
;	WITH_CCD	doesn't compile LINK_CCD dependent parts
;	(none)		sys_open/ioctl (eject), only
; ----------------------------------------------------------------



;compile options
%define LINK_CCD	; enable <ccd> linked to <eject> for <eject -ccd> action
;%define WITH_CCD	; enable <eject -ccd>
;%define ONLY_CCD	; enable <eject> alias <eject -ccd>, disable plain eject syscall action
;%define SYS_EJECT	; disable any option passed in

; compile options priority
%ifdef	SYS_EJECT	; top priority
%undef	ONLY_CCD
%undef  LINK_CCD
%undef  WITH_CCD
%endif
;
%ifdef	ONLY_CCD
%define WITH_CCD	; ONLY implies WITH
%undef  LINK_CCD	; and inhibits LINK
%endif
;
%ifdef	LINK_CCD
%define	WITH_CCD	; LINK implies WITH
%endif
;

 

%include "system.inc"

; test (ok)
; %define __ASM2MKH to enable <asm2mkh> to
; collecting currently valid constants from
; system data (/usr/include, etc.).
%ifndef __ASM2MKH
; ioctl no.s
%assign	CDROMEJECT	0x5309
%assign CDROMCLOSETRAY	0x5319
; flags
%define MS_RDONLY	1
%define MS_MGC_VAL	0xc0ed0000
%endif


    CODESEG

    
START:
%ifdef LINK_CCD
	pop edx			; arg.count
%else
	pop eax
%endif; <= LINK_CCD
	pop ecx			; prg.name
	mov ebx,dftdev		; vari reference, device default
%ifdef WITH_CCD
    %ifdef LINK_CCD
	mov edi,ecx		; name
	xor eax,eax		; <eol>
	lea ecx,[eax-1]		; maxcount
	repnz scasb
	mov eax,edx		; arg count
	mov ecx,[edi-4]		; program name
	mov edi,flag
;;;;	mov [edi],eax		; clear flag (might be dispensable..)
	cmp ecx,0+'ccd'
	setnz byte[edi]		; ccd mode/ioctl 'option' default := 00
    %else
	mov edi,flag		; flag & mountoptions ptr
        %ifdef ONLY_CCD
;;;;	mov byte[edi],0		;(.bss <nul> initiated, anyway)
        %else
	mov byte[edi],1
	%endif; <= ONLY_CCD
    %endif; <= LINK_CCD
	mov esi,ebx			 ; save device default
	lea ecx,[byte ebx+mountp-dftdev] ; mountpoint
	lea edx,[byte ebx+fstype-dftdev] ; mountoptions
	dec eax
    	jz .eject		;?; defaults only
.dlnk:
	pop ebx			; specialfile/"-ccd" option
    %ifdef ONLY_CCD
    %else
	cmp dword[ebx],'-ccd'	; option..
	jz .ccdo		;?;  ..given
	test byte[edi],-1
	jz .nopt		;?; executed by 'ccd' alias and not with -ccd switch
.ccdo:
	mov byte[edi],0		; clear flag for ccd option
	dec eax	
	mov ebx,esi		; restore default device name
	jz .eject		;?; use defaults
	pop ebx			; replace option by devicename
    %endif; <= ONLY_CCD
.nopt:
	dec eax
	jz .eject		;?; standard call; not -ccd option
; those are not relevant for the plain syscall mode, extra check not necessary:
	pop ecx			; mountp
	dec eax
	jz .eject
	pop edx			; fstype
	dec eax
	jz .eject
	pop edi			; options
.eject:
	push ecx		; mountpoint
	push ebx		; specialfile
    %ifdef ONLY_CCD
    %else
	test byte[edi],-1
	jnz .opn		;?; not -ccd, just the syscall
    %endif; <= ONLY_CCD
	sys_umount 		; eject won't work on a mounted device
.opn:
	sys_open EMPTY,O_RDONLY|O_NONBLOCK;
	push eax		; save exit code
	test eax,eax
	js .exit		;?; device error, try re-mounting

	sys_ioctl eax,CDROMEJECT;
    %ifdef ONLY_CCD
    %else
	test byte[edi],-1
	jnz .texit		;?; not -ccd, just the syscall
    %endif; <= ONLY_CCD
	push ebx		; device-fd

	push edx		; fstype

	xor edx,edx
	mov dl,ts.e-ts		; message length
	sys_write STDOUT,ts	; (time to change CD)
	mov dl,1
	sys_read STDIN		; read input until <enter>
	pop edx

	pop ebx
	sys_ioctl EMPTY,CDROMCLOSETRAY;

.exit:	;edx=fstype,edi=options	; (re-)mount, ready
	pop ecx			; ernum
	pop ebx			; device
	xchg ecx,[esp]		; mountpoint
	sys_mount EMPTY,EMPTY,EMPTY,MS_RDONLY|MS_MGC_VAL;
	pop eax
.texit:
	test eax,eax
	js .sexit		;?; ret device open error
	xor eax,eax		; clear fd, ret noerr
%else; => not WITH_CCD
	dec eax			; argcount
	jz .eject		;?; defaults only
	pop ebx			; specialfile
.eject:
	sys_open EMPTY,O_RDONLY|O_NONBLOCK;
	test eax,eax
	js .sexit		;?; device error, try re-mounting
	sys_ioctl eax,CDROMEJECT;
%endif;; <= WITH_CCD
.sexit:
	sys_exit eax;

; defaults
dftdev:	db '/dev'
mountp:	db '/cdrom',NULL
%ifdef WITH_CCD
options:dd 0
fstype:	db 'iso9660',NULL
ts:	db '<enter> ..',NULL
.e:
    UDATASEG
flag:	resd 1
%endif

    END
;-
;-=========================================================================;
;- ccd.asm <eof>
