;Copyright (C) 1999-2000 Konstantin Boldyshev <konst@linuxassembly.org>
;
;$Id: ln.asm,v 1.3 2000/12/10 08:20:36 konst Exp $
;
;hackers' ln/sln
;
;0.01: 29-Jul-1999	initial release
;0.02: 28-Sep-1999	Added no option check (docwhat@gerf.org)
;0.03: 10-Sep-2000	merged with sln
;
;syntax: ln [-s] target link_name
;	 sln src dest
;
;example: ln -s vmlinuz-2.2.10 vmlinuz
;	  sln aaa bbb

%include "system.inc"

CODESEG

START:
	pop     ebx	;argc
	pop	esi	;argv[0]
.n1:			;how we are called?
	lodsb
	or 	al,al
	jnz	.n1

	cmp	ebx,byte 3
	jb	.quit

	pop	edi	;target or '-s'
	pop	ebp	;link_name

	cmp	byte [esi-4],'s'
	jz	.sln

	cmp	word [edi],"-s"
	jnz	.hardlink
	pop	edi

.symlink:
	sys_symlink ebp,edi

.quit:
	sys_exit eax

.sln:
	xchg	ebp,edi
	sys_unlink edi
	jmps	.symlink

.hardlink:
	sys_link edi,ebp
	jmps	.quit

END
