;Copyright (C) 1999 Cecchinel Stephan <inter.zone@free.fr>
;
;$Id: nc.asm,v 1.4 2000/12/10 08:20:36 konst Exp $
;
;hackers' netcat
;
;syntax: nc -l port ip port	get input from port, output to ip port
;	 nc -l port		get input from port, output to STDOUT
;	 nc ip port		get input from STDIN, output to ip port
;
;ip is in form xxx.xxx.xxx.xxx  only numeric (no DNS lookup)
;
;0.01: 27-Dec-1999	initial release (CS)
;0.02: 10-Sep-2000	heavy rewrite, size improvements,
;			portability fixes and cleanup (KB)

%include "system.inc"

CODESEG

START:
	_mov	ebp,STDIN
	_mov	edi,STDOUT

	pop	ebx
	pop	ebx
        pop	esi
	test	esi,esi
	jz	near .read

	mov	ebx,sa
	mov	dword [ebx],AF_INET

	cmp	word [esi],"-l"
        jnz	near .writesock

.readsock:

;first we create socket

	call	createsocket

;then we bind to port

	pop	esi		;next arg, port to listen
	call	StrToLong	;convert ascii to int
	mov	byte [ebx+2],dh
	mov	byte [ebx+3],dl

	mov	esi,eax
	sys_bind esi,sa,16
        test	eax,eax
        js	near .exit

	sys_listen esi,0xff

;accept incoming connection

	sys_accept esi,arg1,arg2
	mov	ebp,eax

	pop	esi
	test	esi,esi
	jz	.read

.writesock:

	call	createsocket
	mov	edi,eax

;inet_aton:  	convert ascii xxx.xxx.xxx.xxx ip notation
;		to network oriented 32 bit number
;input: esi:	ascii string
;ouput: edi:	to store 32 bit number

	lea	ebx,[sa+4]
	_mov	ecx,4
.conv:	call	StrToLong
	mov	[ebx],dl
	inc	ebx
	loop	.conv

	pop	esi			;take next arg (port)
	call	StrToLong		;convert to int
	mov	byte[ebx+2-8],dh	;store port in network order
	mov	byte[ebx+3-8],dl

	sys_connect edi,sa,16
	test	eax,eax
        js	.exit

.read:
	mov	esi,buffer
	sys_read ebp,esi,1024
	test	eax,eax
        js	.exit
	jz	.exit
	sys_write edi,esi,eax
	jmps	.read

.exit:
quit:
	sys_exit

createsocket:
	push	ebx
	sys_socket PF_INET,SOCK_STREAM,IPPROTO_TCP
        test	eax,eax
        js	quit
	pop	ebx
	ret

;convert ascii decimal string to 32 bit number
;input:  esi point to ascii
;return: edx=32 bit number

StrToLong:
	push	eax
	xor	eax,eax
	xor	edx,edx
.next:
	lodsb
	sub	al,'0'
	jb	.ret
	add	edx,edx
	lea	edx,[edx+edx*4]
	add	edx,eax
	jmps	.next
.ret:
	pop	eax
	ret

UDATASEG

sa	resb	0x10
buffer	resb	1024

arg1	resb	0x20
arg2	resd	1

END
