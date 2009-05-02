;Copyright (C) 1999 Konstantin Boldyshev <konst@linuxassembly.org>
;
;$Id: tee.asm,v 1.6 2002/02/02 08:49:25 konst Exp $
;
;hackers' tee		[GNU replacement]
;
;syntax: tee [-ai] [file...]
;
;-a	append to files instead of overwriting
;-i	ignore interrupt signals
;
;returns error count
;
;Note that this tee can handle about 1000 specified files only,
;however it is more than enough.
;
;0.01: 04-Jul-1999	initial release
;0.02: 27-Jul-1999	files are created with permissions of 664
;0.03: 20-Aug-2000	"-i" bugfix, sys_sigaction instead of sys_signal (TH)

%include "system.inc"

%assign	BUFSIZE	0x2000

CODESEG

;ebp	-	return code

START:
	mov	edi,handles
	xor	ebp,ebp

	pop	ebx
	dec	ebx
	pop	ebx
	jz	open_done	;if no args - write to STDOUT only

	_mov	ecx,O_CREAT|O_WRONLY|O_TRUNC
	pop	ebx
	mov	esi,ebx
	lodsb
	cmp	al,'-'
	jnz	open_2
.scan:
	lodsb
	or	al,al
	jz	open_files
	cmp	al,'a'
	jnz	.i
	_mov	ecx,O_CREAT|O_WRONLY|O_APPEND
	jmps	.scan
.i:
	cmp	al,'i'
	jnz	near do_exit
	push	ecx
	sys_sigaction SIGPIPE,sa_struct,NULL	;sys_signal SIGPIPE,SIG_IGN
	sys_sigaction SIGINT			;sys_signal SIGINT
	pop	ecx
	jmps	.scan
	
open_files:
	pop	ebx		;pop filename pointer
	or	ebx,ebx
	jz	open_done	;exit if no more agrs
open_2:
	sys_open EMPTY,EMPTY,664q
	test	eax,eax
	jns	open_ok
	inc	ebp
	jmps	open_files
open_ok:
	stosd
	jmps	open_files

open_done:
	xor	eax,eax
	stosd
read_loop:
	sys_read STDIN,buf,BUFSIZE
	test	eax,eax
	js	read_error
	jz	close
	sys_write STDOUT,EMPTY,eax	;write to STDOUT

	mov	esi,handles
.write_loop:
	lodsd
	or	eax,eax
	jz	read_loop
	sys_write eax
	jmps	.write_loop
read_error:
	inc	ebp

close:
;	mov	esi,handles
;.close_loop:
;	lodsd
;	or	eax,eax
;	jz	do_exit
;	sys_close eax
;	jmp	short .close_loop

do_exit:
	sys_exit ebp

;dirty hack which works in our case
sa_struct	dd	SIG_IGN,0,0,0

UDATASEG

buf	resb	BUFSIZE

;well, here is our malloc() :-)
handles	resd	1

END
