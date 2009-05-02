; Copyright (C) 2001 Stanislav Ryabenkiy <stani@ryabenkiy.com>
; Licensed under the GPL, version 2. 
;
; $Id: scan.asm,v 1.2 2002/02/02 08:49:25 konst Exp $
;
; hackers' scan
; (simple connect() portscanner)
;
; USAGE
;
; syntax: 	scan IP STARTPORT ENDPORT
;	
; ex:		scan 127.0.0.1 10 200
;
; You MUST specify start and end ports. They range from 1 to 65,536.
; You MUST use an ip. A hostname will not be resolved. 
;
;------------------------------------------------------------------------
; This program is free software; you can redestribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful, 
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
; GNU General Public License for more details.
; 
;------------------------------------------------------------------------
;
; IMPORTANT NOTICE
; 
; If you are located in the USA, take note that scanning over
; federal borders is illegal, and that scanning government 
; property might result in you being classified as a terrorist,
; in accordance with the PATRIOT act of 2001. 
;
; If you are outside the USA, check with your local authorities
; to ensure that scanning is legal in your country.
;
;
; ACKNOWLEDGEMENTS
; 
; Numerous routines were borrowed from other people. I gave credit
; to them in the code. 
; 
;
; NOTES
;
; Version 0.1 compiles to 431 bytes on my box. Code is ugly. It works, 
; but there must be (and are) better ways to make it work. Suggestions 
; on how to make the itoa loop work correctly are welcome (it segfaults 
; on me when i use a loop, but not in the current state.) 
;
;
; CHANGELOG
;
; 0.1:		27-Dec-2001	initial release
	 
%include "system.inc"

CODESEG

endl	db	__n 		; we need this to attach to our future 
				; strings
len	equ	$-endl

usage	db	"USAGE: scan ip startport endport",__n
len_u	equ	$-usage

START:
	pop	edx		; argc
	cmp	dl,3
	ja	.n1

.myusage:
	sys_write STDOUT, usage, len_u
	sys_exit 1

.n1:
	pop	edx		; argv[0]
	pop	esi		; argv[1], IP
	
	mov	edi, sockaddr_in

	;;; ip2int - from Jani Monoses' ping
	; FIXME: for some strange reason, I couldn't get this 
	; to work as a call
	
	xor	eax,eax
	xor	ecx,ecx
	xor	edx,edx
.cc:
	xor	ebx,ebx
.c:
	lodsb
	inc	edx
	sub	al,'0'
	jb	.next
	imul	ebx,byte 10
	add	ebx,eax
	jmp	short .c
.next:
	mov	[edi+ecx+4],bl	; the result is stored in edi
	inc	ecx
	cmp	ecx,byte 4
	jne	.cc
	
	;;; end of ip2int

	mov	word [edi], AF_INET
	pop	esi		; startport

	; atoi - borrowed from Jonathan Leeto's chown
	; FIXME: wery ugly. the following block is repeated twice.
	; I couldn't get it to work in a call.
					
	;; inupt:	esi:	points to string
	;; output:	eax:	points to 32 bit result

	xor	eax,eax
	xor	ebx,ebx
.nextstr1:	
  	lodsb		
 	test	al,al
	jz	.ret1
	sub	al,'0'
	imul	ebx,10
	add	ebx,eax	
	jmp	.nextstr1
.ret1:
	xchg	ebx,eax	

	mov 	 [startport], eax

	; atoi - borrowed from Jonathan Leeto's chown
	; see note on first atoi

	xor	eax,eax
	xor	ebx,ebx
.nextstr:	
  	lodsb		
 	test	al,al
	jz	.ret2
	sub	al,'0'
	imul	ebx,10
	add	ebx,eax	
	jmp	.nextstr
.ret2:
	xchg	ebx,eax	

	mov 	[endport], eax

	; on with the fun (end of atoi)
	
	xor	esi,esi		; now the loop works
	_mov	si, [startport]
.loop1:				; this loop keeps going infinite
 	call	.scan
	inc	si
	cmp	si, [endport]
	jnz	short .loop1
	jmp	do_exit


	
.scan:				; scan procedure, call for every port in question
	sys_socket AF_INET, SOCK_STREAM, 0x00
	push	eax		; save fd
	_mov	dx,si
	_mov	byte [edi+3], dl
	_mov	byte [edi+2], dh
	sys_connect eax, edi, 16	;edi holds sockaddr_in
	cmp	eax, 0
	jnz	short .return	; jump if port closed
	push	edi		; store old edi on stack
	_mov	edi,outbuf	; pass buffer addy
	xor	eax,eax
	_mov	eax,esi		; pass integer
	call	itoa
	sys_write STDOUT, outbuf, 6	; hope this works :-)
	sys_write STDOUT, endl, len
	
	pop	edi		; restore old edi
.return:
	pop eax			; fd
	sys_close eax
	ret

do_exit:
    sys_exit_true


itoa:				; partially borrowed from Brian Raiter's ls
	push	eax		; store number to display
	_mov	ecx, 6
	_mov	al, ' '
	rep stosb		; edi is filled with two spaces
	pop	eax		

	push	edi		; save end of string pointer
	mov	cl, 10
.decloop:
	cdq
	div	ecx
	add	dl,'0'
	dec	edi
	mov	[edi], dl
	or	eax,eax
	jnz	.decloop
	pop	edi		; returns position after string
	ret
	
				
UDATASEG

; for reference:
;
; struct sockaddr_in {
;	short int		sin_family;	// address family, 2 bytes
;	unsigned short int	sin_port;	// port number, 2 bytes
;	struct in_addr		sin_addr;	// internet address, 4 bytes
;	unsigned char		sin_zero[8];	// padding, 8 bytes
; };
;
; struct in_addr {
;	unsigned long s_addr;
; };
; 
	 
sockaddr_in:	resb	16
outbuf:		resb	6	; for printing the result of itoa
startport:	resb	2
endport:	resb	2
		
END
