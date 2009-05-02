;Copyright (C) 1999 Konstantin Boldyshev <konst@linuxassembly.org>
;
;$Id: chroot.asm,v 1.4 2002/02/02 08:49:25 konst Exp $
;
;hackers' chroot
;
;syntax: chroot directory [command]
;
;example: chroot /tmp
;	  chroot /mnt lilo
;
;Runs command with specified root directory
;If no command is given, runs /bin/sh
;You must be root to succeed
;
;0.01: 19-Dec-1999	initial release

%include "system.inc"

CODESEG

START:
	pop	ebp			;get argc
	dec	ebp			;exit if no args
	jz	do_exit

	pop	ebx

	pop	ebx
	sys_chroot
	or	eax,eax
	js	do_exit

	mov	ebx,[esp]		;ebx -- program name (*)
	or	ebx,ebx
	jnz	.set_args
	mov	ebx,shell
.set_args:
	mov	ecx,esp			;ecx -- arguments (**)
	lea	edx,[esp+(ebp+1)*4]	;edx -- environment (**)

	sys_execve

do_exit:
	sys_exit eax

shell	db	"/bin/sh";,EOL

END
