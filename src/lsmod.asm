;Copyright (C) 1999 Indrek Mandre <indrek@mare.ee>
;
;$Id: lsmod.asm,v 1.6 2002/03/07 06:16:39 konst Exp $
;
;hackers' lsmod/rmmod
;
;syntax: lsmod
;	 rmmod module...
;
;example: rmmod sound ppp
;
;0.01: 17-Jun-1999	initial release
;0.02: 04-Jul-1999	fixed bug with 2.0 kernel
;0.03: 06-Sep-2000	merged with rmmod (KB)
;0.04: 04-Dec-2001	sys_query_module when /proc/modules is missing (KB)

%include "system.inc"

CODESEG

%if __KERNEL__ = 20
header	db	'Module         Pages    Used by',__n
%else		;if __KERNEL__ >= 22
header	db	'Module                  Size  Used by',__n
%endif
_hlength	equ	$-header
%assign hlength _hlength

%assign	BUFSIZE	0x2000

START:
	pop	ebp
	pop	esi	;our name
.n1:			;how we are called?
	lodsb
	or 	al,al
	jnz	.n1
	cmp	word [esi-6],'ls'
	jz	do_lsmod

do_rmmod:
	dec	ebp
	jz	do_exit	;no arguments - error

.rmmod_loop:
	pop	ebx	;take the name of the module
	sys_delete_module
	test	eax,eax
	js	do_exit
	dec	ebp
	jnz	.rmmod_loop

do_exit:
	sys_exit eax

do_lsmod:
        sys_write STDOUT,header,hlength

	sys_open filename, O_RDONLY
	test	eax, eax
	js	.query_module

;	mov	ebp, eax
	sys_read eax, buf, BUFSIZE
	mov	edx, eax

.write:
	sys_write STDOUT
;	sys_close ebp
.w2:
	jmps	do_exit

.query_module:
	sys_query_module NULL, QM_MODULES, buf, BUFSIZE, qret
	test	eax,eax
	js	.w2

	mov	ecx,[qret]
	mov	esi,edx
.q0:
	lodsb
	or	al,al
	jnz	.q0
	mov	byte [esi - 1],__n
	loop	.q0
	sub	esi,edx
	mov	ecx,edx
	mov	edx,esi
	jmps	.write

filename	db	"/proc/modules",EOL

UDATASEG

qret	resd	1
buf	resb	BUFSIZE

END
