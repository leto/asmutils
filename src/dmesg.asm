;Copyright (C) 1999 Indrek Mandre <indrek@mare.ee>
;
;$Id: dmesg.asm,v 1.7 2002/03/14 07:12:12 konst Exp $
;
;hackers' dmesg
;
;syntax: dmesg [-c] [-n level]
;
;example: dmesg
;         dmesg -c
;	  dmesg -n 1
;
;-c	clears the kernel buffer
;-n	set the console log level
;
;0.01: 17-Jun-1999	initial release
;0.02: 04-Jul-1999	fixed bug with 2.0 kernel, removed leading <n> (KB)
;0.03: 14-Mar-2000
;			fixed the "-c" option bug,
;			empty kernel buffer coredump,
;			added "-n" option
;			by Christopher Li <chrisl@turbolinux.com.cn>
;
;			check for unsuccessful sys_syslog,
;			clear buffer *after* print,
;			fast output (buffer-at-once) (KB)
;0.04: 05-Aug-2000	increased buffer size (KB)
;0.05: 14-Mar-2002	squeezed one byte (KB)

%include "system.inc"

CODESEG

%assign	BUFSIZE	0x8000

START:
	_mov	ebp,0		;-c flag
	_mov	ebx,3		;just print the buffer [3]
	pop	edi		;edi holds argument count
	dec	edi
	jz	.forward
	pop	eax		;our own name
	pop	eax
	cmp	word [eax],"-n"
	jnz	.clear
	dec	edi
	jz	.forward
	pop	ecx		;the log level
	xor	edx,edx
	mov	dl, byte [ecx]
	sub	dl,'0'
	jna	.forward	;less than 0, skip
	cmp	dl,8
	ja	.forward	;more than 8, skip
	_mov	ebx,8		;set the console level
	jmps	.syslog
.clear:
	cmp	word [eax],"-c"
	jnz	.forward
	inc	ebp
.forward:
	_mov	edx,BUFSIZE
.syslog:
	sys_syslog EMPTY,buf 
	test	eax,eax
	js	.quit
	jz	.quit
	mov	edi,buf_new
	mov	ebx,edi		;save for later use
	mov	esi,ecx
	mov	ecx,eax
.write:
	lodsb
	cmp	al,'<'
	jnz	.store
	cmp	byte [esi + 1],'>'
	jnz	.store
	lodsw
	lodsb
	sub	ecx,byte 3
.store:
	stosb
	loopnz	.write

	sub	edi,ebx
	sys_write STDOUT,ebx,edi

	or	ebp,ebp
	jz	.quit

	sys_syslog 4		;clear the kernel buffer [4] (-c argument)

.quit:
	sys_exit_true

UDATASEG

buf	resb	BUFSIZE
buf_new	resb	BUFSIZE

END
