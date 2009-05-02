;Copyright (C) 2000 Konstantin Boldyshev <konst@linuxassembly.org>
;
;$Id: tty.asm,v 1.2 2002/02/02 08:49:25 konst Exp $
;
;hackers' tty
;
;syntax: tty
;
;0.01: 21-Mar-2000	initial release

%include "system.inc"

%assign	BUFSIZE	0x1000

CODESEG

START:
	sys_readlink fd0, buf, BUFSIZE
	test	eax,eax
	js	do_exit

	inc	eax
	mov	edx,eax
	mov	esi,ecx
.next:
	lodsb
	or	al,al
	jnz	.next
	mov	byte [esi-1],__n

	sys_write STDOUT

do_exit:
	sys_exit eax

fd0	db	"/proc/self/fd/0"	;,EOL

UDATASEG

buf	resb	BUFSIZE

END
