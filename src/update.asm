;Copyright (C) 1999-2001 Konstantin Boldyshev <konst@linuxassembly.org>
;
;$Id: update.asm,v 1.6 2002/02/02 08:49:25 konst Exp $
;
;hackers' update
;
;initial version was based on "updated"
;by Sander van Malssen <svm@kozmix.hacktic.nl>
;
;syntax: update [PERIOD]
;
;PERIOD (in seconds) - flush period, if missing use default of 30
;
;example:	update
;		update 60
;
;0.01: 05-Jun-1999	initial release
;0.02: 17-Jun-1999	period parameter added
;0.03: 04-Jul-1999	fixed bug with 2.0 kernel,removed MAXPERIOD,
;			sys_nanosleep instead of SIGALRM
;0.04: 18-Sep-1999	elf macros support
;0.05: 22-Jan-2001	minor size improvement

%include "system.inc"

%assign	PERIOD	30	;default flush interval in seconds

CODESEG

;ebp - flush period

START:
	_mov	ebp,PERIOD
	pop	esi
	dec	esi
	jz	.start
	pop	esi
	pop	esi

;convert string to integer

	xor	eax,eax
	xor	ebx,ebx
.next_digit:
	lodsb
	sub	al,'0'
	jb	.done
	cmp	al,9
	ja	.done
	imul	ebx,byte 10
	add	ebx,eax
	jmps	.next_digit
.done:
	or	ebx,ebx		;this check can be removed if sure
	jz	.start
	mov	ebp,ebx
.start:	
	mov	[t.tv_sec],ebp
	sys_fork
	test	eax,eax
	jz	.child
	sys_exit

.child:
	sys_bdflush 1,0
	sys_nanosleep t	;,NULL
	jmps	.child

UDATASEG

t B_STRUC timespec,.tv_sec

END
