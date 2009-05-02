;Copyright (C) 2001 Jani Monoses <jani@astechnix.ro>
;
;$Id: ping.asm,v 1.2 2001/07/20 07:04:18 konst Exp $
;
;hackers' ping
;
;syntax:	ping	xxx.xxx.xxx.xxx
;		only IP numbers (no hostnames)
;		no parameters 	(yet)
;
;Very simple ping program
;sends a minimal ICMP ECHO_REQUEST packet (8 bytes)
;and exits on receiving whatever seems to be a reply to it
;or after a hardcoded 5 second interval 
;
;must be run as root or made setuid root (uses SOCKET_RAW)

%include "system.inc"


CODESEG

;	This is what the ICMP header looks like
;	and this is all we send - 20 bytes long IP header + 8 bytes ICMP
;	a reply to this request should have the TYPE
;	field set to 0 (ECHO_REPLY) and the rest look the same
;	The packet  has a precomputed valid checksum for itself
; 
;
;		0				31	
;		|TYPE 	| CODE 	|     CHECKSUM  |
;		|      ID	|	SEQ	|


icmp_packet db 	08, 00, 0xf7, 0xff, 00, 00,  00, 00
;icmp_packet_len equ $-icmp_packet

repl db ' is alive!', 10
;repl_len equ $-repl

;these are defined here instead of letting NASM calculate them with $-... 
;in order to save 2 * 3 bytes in the code.

%assign	icmp_packet_len	8
%assign	repl_len	11
%assign TIMEOUT		5					;default timeout for select()

START:
	pop		ebx					;get argument count
	dec		ebx
	jz		near .exit				;if no args bail out	
	pop		ebx					;arg 0 - program name
	pop		esi					;arg 1 - IP number
	
	push		byte repl_len				;push args for sys_writev
	push		dword repl				;(reply message)


	mov		edi, sockaddr_in
	call		.ip2int					;fill in sin_addr.s_addr 
	mov		dword[edi], AF_INET | (IPPROTO_IP << 16);fill in sin_family and sin_port

	push		edx					;more args for sys_writev
	push		esi					;(IP number)	

	sys_socket	AF_INET, SOCK_RAW, IPPROTO_ICMP		;create raw socket
	test		eax,eax									
	js		near .exit

	mov		ebp, eax				;save socket descriptor
	
	sys_sendto	ebp, icmp_packet, icmp_packet_len , 0, edi, 16	;send echo request
	test		eax,eax
	js		.exit
	
	
	mov		byte[timeout], TIMEOUT			;timeout in seconds for select

.recvloop:	

	bts		[read_fdset],ebp			;FD_SET
	inc		ebp
	sys_select	ebp,read_fdset,0,0,timeout	
	or		eax,eax					;timed out ?
	jz		.exit

	dec		ebp
	mov		edi,recv_packet
	sys_recvfrom	ebp, edi, 28, 0, 0, 0			;get packet from network
	cmp		byte[edi+20], 0				;is it an ECHO_REPLY?
	jne		.recvloop				

;	arguments are already on the stack for sys_writev

	sys_writev	STDOUT, esp, 2
.exit:
	sys_exit	eax					

;function ip2int - converts IP number in dotted 4 notation pointed to by esi, to int32 in edx

.ip2int:
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
	imul		ebx,byte 10
	add		ebx,eax
	jmp		short .c	
.next:
	mov		[edi+ecx+4],bl
	inc		ecx
	cmp		ecx, byte 4
	jne		.cc
	ret	

UDATASEG

timeout:	resb 8		
read_fdset	resb 2	
sockaddr_in:	resb 16	;sizeof struct sockaddr_in
recv_packet:	resb 20	;ip header size(20) + icmp header size(8)

END
