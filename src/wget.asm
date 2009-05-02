; Copyright (c) 2002 Thomas M. Ogrisegg
;
; wget - HTTP client
;
; syntax:
;       wget ip-address remote-filename
;
; License          :     GNU General Public License
; Author           :     Thomas Ogrisegg
; E-Mail           :     tom@rhadamanthys.org
; Version          :     0.3
; Created          :     03/16/02
; SUSV2-compliant  :     not in SUSV2
; GNU-compatible   :     no
;
; TODO: Add resume support, more options, DNS-resolver, ftp-client
;       and URL-parsing
;
; $Id: wget.asm,v 1.2 2002/06/16 14:19:58 konst Exp $

%include "system.inc"

%assign BUF_SIZ 0x2000		; Tune this to improve performance

CODESEG

START:
		pop ecx
		pop esi
		pop esi
		pop ebp
		cmp ecx,byte 3
		jne near .exit
		sys_socket AF_INET, SOCK_STREAM, IPPROTO_TCP
		test eax, eax
		js near .exit
		mov [sockfd], eax
		push word 0x5000		; port 80 (big-endian)
		push word AF_INET
		mov edi, esp
		call ip2int
		sys_connect [sockfd], edi, 0x10
		test eax, eax
		jnz near .exit
		mov esi, ebp
		sub esp, BUF_SIZ
		mov long [esp], 'GET '
		lea edi, [esp+4]
		xor ecx, ecx
		mov al, '/'
.Lstrcpy:
		inc ecx
		stosb
		lodsb
		or al, al
		jnz .Lstrcpy
		mov al, ' '
		stosb
		mov long [edi],   'HTTP'
		mov long [edi+4], '/1.0'
		mov long [edi+8], 0xa0d0a0d
		add ecx, 0x11
		sys_write [sockfd], esp, ecx
		sys_read [sockfd], esp, BUF_SIZ
		cmp long [esp], 'HTTP'
		jnz .exit
		cmp long [esp+9], '200 '
		jnz .exit
		mov edi, esp
		mov ecx, eax
		mov edx, eax
		mov al, __r
.Lloop:
		repnz scasb
		or ecx, ecx
		jz .exit
		cmp word [edi-1], 0xa0a
		jz .open
		cmp long [edi-1], 0xa0d0a0d
		jnz .Lloop
.open:
		add edi, 0x3
		push ecx
		sys_open ebp, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR
		test eax, eax 
		js .exit
		mov [destfd], eax
		pop eax
		sub eax, 0x3
.Lnloop:
		sys_write [destfd], edi, eax
		mov edi, esp
		sys_read [sockfd], edi, BUF_SIZ
		or eax, eax
		jnz .Lnloop
.exit:
		sys_exit 0x0

;; stolen copied from ping.asm
ip2int:
	xor		eax,eax
	xor		edx,edx
	xor		ecx,ecx
.cc:
	xor		ebx,ebx
.c:
	mov		al,[esi+edx]
	inc		edx
	sub		al,'0'
	jb		.next
	imul	ebx,byte 10
	add		ebx,eax
	jmp		.c
.next:
	mov		[edi+ecx+4],bl
	inc		ecx
	cmp		ecx, byte 4
	jne		.cc
	ret

UDATASEG
sockfd	LONG	1
destfd	LONG	1
END
