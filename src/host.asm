;Copyright (C) 2001,2002 Rudolf Marek <marekr2@fel.cvut.cz>, <r.marek@sh.cvut.cz>, <ruik@atlas.cz>
;
;$Id: host.asm,v 1.2 2003/05/26 05:06:25 konst Exp $
;
;hacker's  host 
;
;syntax: host hostname [dns_server_ip]
;
;Supports /etc/resolv.conf when found
;
;See RFC1035 for futher info
;
;0.02: 20-May-2003	added "-t" option (Willy Tarreau <wtarreau@yahoo.fr>)
;0.01: 01-Mar-2002	initial release

%include "system.inc"

%assign ECONNREFUSED	0111
%assign IP_TOS  	1
%assign SOL_IP  	0
%assign BUFF_SIZE    	0512
%assign FIONBIO     	0x5421 
%assign DNS_PORT 	053
%assign TIMEOUT		60000
				     
CODESEG

 usage: 	db "Usage: host [ -t ms ] hostname [dns_server_ip]",__n
 usage_llen 	equ $ - usage
 refused: 	db "Connection refused to DNS server :(",__n
 refused_llen 	equ $ - refused

%assign  refused_len  refused_llen
%assign  usage_len  usage_llen

;code "ins pirated" a bit by ping.asm, telnet.asm, httpd.asm
START:
        pop 	ebx
	dec	ebx
	jnz 	.ok
.usage:
	sys_write STDOUT,usage,usage_len
	xor	eax,eax
.exit:
	or	eax,eax
	jz	.ok_exit
	cmp 	eax,-ECONNREFUSED
	jnz 	.ok_exit
	sys_write STDOUT,refused,refused_len 
.ok_exit:
	sys_close ebp
	sys_exit 0
.ok:
	mov	dword [timeout], TIMEOUT
	pop	eax					;arg 0 - program name
	pop	eax
	cmp	byte [eax], '-'				;-t
	jnz	.hostname
	sub	ebx,2
	jbe	.usage
	pop	esi					;timeout in ms
	push	ebx
	xor		ebx,ebx
	xor 		eax,eax
.next_digit:
	lodsb
	sub	al,'0'
	jb	.done
	cmp	al,9
	ja	.done
	imul	ebx,byte 10
	add	ebx,eax
	jmps	.next_digit
.done:
	mov	dword [timeout], ebx
	pop	ebx
	pop	eax					;next arg (hostname)
.hostname:
	mov	dword [hostname], eax
	dec	ebx
	jz	.find_server_ip
	pop	dword [server_ip]
.find_server_ip:
	mov	esi,[server_ip]
	or	esi,esi	
	jnz	.has_server
	call	find_server_ip				;result string in ESI
	or	esi,esi
	jnz	.has_server
	jmp	.exit					;no server, give up
.has_server:
	call	parse_request				;fill in a DNS request
	mov	edi,sockaddr_in
	call	ip2int					;fill in sin_addr.s_addr 
	mov	bl,DNS_PORT
	mov	dword[edi], AF_INET | (IPPROTO_IP << 16);fill in sin_family and sin_port
	mov 	byte [edi+3],bl
;	sys_socket	PF_INET, SOCK_STREAM, IPPROTO_IP		;create raw socket (TCP)
	sys_socket	PF_INET, SOCK_DGRAM, IPPROTO_IP			;create raw socket (UDP)
	test	eax,eax									
.ex_help:
	js	 near .exit

	mov	ebp, eax	;save socket descriptor
	push 	byte  0x10
	mov 	edi,esp
        sys_setsockopt eax,SOL_IP,IP_TOS,edi,4		
	test	eax,eax									
	pop 	eax
	js	.ex_help
	sys_connect 	ebp,sockaddr_in,16
	test	eax,eax									
	js	 .ex_help
	push 	byte  0x1
	mov 	edi,esp
	sys_setsockopt ebp,0x1,0xa,edi,4		
	test	eax,eax									
	pop 	eax
	js	 .ex_help
	push 	byte 1
	sys_ioctl ebp,FIONBIO,esp
	test	eax,eax									
	pop 	eax
	js	near .exit
;.send_query:
	xor	edx,edx
	mov	dx,[dns_q.size]
	xchg	dh,dl
;	inc	edx
;	inc	edx
;	sys_write ebp,dns_q,EMPTY		;in TCP, we send size + request
	sys_write ebp,dns_q+2,EMPTY		;in UDP, we only send the request

.fd_setup:
	mov 	dword [poll.fd1],ebp
	mov	ax,POLLIN|POLLPRI
	mov	word [poll.e1],ax
	mov	edx, dword [timeout]	; third arg is the timeout
	sys_poll poll,1
	test 	word [poll.re1],POLLIN|POLLPRI
	jnz 	.we_have_mail
	jmp 	.exit

;.TEST:	;int 3
;	sys_open d1,O_RDONLY
;	mov	ebx,eax
;	sys_read EMPTY,dns_q,BUFF_SIZE
;	sys_close
.we_have_mail:
	mov 	esi,dns_q
        sys_read ebp,esi,BUFF_SIZE
	or 	eax,eax
	jz 	.do_exit
	;we have DNS packet in esi
	mov	ax,[dns_q.qd]
	xchg	ah,al
	or	ax,ax
	jz	.do_not_have_qs ;we usally have such fieled
	mov	esi,dns_q.qname_b
.next:				;try to find end of our query
	lodsb	
	or 	al,al
	jnz	.next
	add	esi,4	
.do_not_have_qs:		;answer section follows
.next2:
	lodsb			;again host name or CNAME
	or 	al,al
	jnz	.next2
.next3:
	lodsb
	or 	al,al
	jz	.next3 		;Uncompressed name one byte more
	cmp	al,1		;ok it is IN - so we jump to IP grab
	jz	.ok_print
	cmp	al,5		; the domain is alias it is CNAME
	jnz	.do_exit
	add	esi,6		;skip a CNAME section
	xor	eax,eax
	mov	ax,[esi]
	xchg	ah,al	
	add 	esi,eax
	inc	esi
	inc 	esi
	jmps .next2		;next field - treat as another entry 

	;jmps .next
.ok_print:
	add	esi,7
	lodsb	
	cmp 	al,4		;IP should have 4 bytes
	jnz	.do_exit
	mov	eax,[esi] ;RESOLVED IP is HERE
	call	print_ip
.do_exit:
	jmp .exit




;function ip2int - converts IP number in dotted 4 notation pointed to by esi, to int32 in edx

ip2int:
	xor	eax,eax
	xor	edx,edx
	xor	ecx,ecx	
.cc:	
	xor	ebx,ebx
.c:	
	mov	al,[esi+edx]
	inc	edx
	sub	al,'0'
	jb	.next
	imul	ebx,byte 10
	add	ebx,eax
	jmp	short .c	
.next:
	mov	[edi+ecx+4],bl
	inc	ecx
	cmp	ecx, byte 4
	jne	.cc
	ret
;esi - user string

parse_request:
		pusha
		mov	esi,[hostname]
		mov 	edi,dns_q.qname_b
		push	edi
		inc	edi
.name_start:
		xor 	ecx,ecx
.name_loop:	lodsb
		or	al,al
		jz	.write_last
		cmp	al,'.'
		jz	.name_done
		inc 	ecx
		stosb
		jmps	.name_loop
.name_done:	pop	ebx	
		mov 	[ebx],cl
		push 	edi
		inc	edi
		jmps	.name_start
.write_last:	xor 	eax,eax
		stosb
		inc	eax
		xchg	al,ah
		stosw
		stosw
		pop	ebx
		mov 	[ebx],cl
		sub	edi,dns_q.id
		mov	edx,edi
		xchg	dh,dl
		mov	[dns_q.size],dx
		mov	word [dns_q.id],'RM'
		mov	word [dns_q.qd],0x100
		mov	word [dns_q.comm],1

		popa
		ret
;	mov 	eax,[arg1+4]

print_ip:
	mov 	edi,ipbuff+020
	mov 	esi,edi
	xchg 	ah,al	
	ror 	eax,16
	xchg 	ah,al
	call 	i2ip
	sub 	esi,edi
	inc 	edi
	sys_write STDOUT,edi,esi
	ret

i2ip:
	std
	;xchg ebx,eax
	;mov al,__n
	;stosb
	;xchg ebx,eax 
	mov 	byte [edi],__n
	dec 	edi
.next:	
	mov 	ebx,eax
	call 	.conv
	xchg 	eax,ebx
	mov 	al,'.'
	stosb
	shr 	eax,8
	jnz 	.next
	cld
	inc 	edi
	mov 	byte [edi],' '
	ret
.conv:
	mov 	cl,010 ;hmm hope somone wont use hex IP
.divide:
	xor 	ah,ah	
	div 	cl     ;ah=reminder
	xchg	ah,al
	add 	al,'0'
	stosb	
	xchg 	ah,al
	or 	al,al
	jnz 	.divide
	ret 
find_server_ip:
        sys_open	resolv,O_RDONLY
	test 	eax,eax
	js	.end
	mov	ebx,eax
	sys_read EMPTY,buf,0x200;dns_q.qname_b,512
        sys_close EMPTY
;        mov	al,'n' ;ames erve r
	mov	esi,ecx
.find_server:	    
	lodsb
	or	al,al
	jz	.end
	cmp	al,'n'
	jnz	.find_server
	cmp	dword [esi],'ames'
	jnz	.find_server
        add	esi,4
        cmp	dword [esi],'erve'
	jnz	.find_server
	add 	esi,4
        cmp 	byte [esi],"r"
	jnz	.find_server
	inc 	esi
.strip:	
        lodsb
        cmp 	al,' '
	jbe	.strip
	dec	esi
	push 	esi
.find_end:	    
	lodsb
	cmp 	al,'.'
	jnb	.find_end
	mov	byte [esi-1],0
	pop	esi
	ret
.end:
	xor	esi,esi
	ret
	
resolv		db	"/etc/resolv.conf", 0

UDATASEG

hostname	resd	1
server_ip	resd	1
timeout		resd	1

ipbuff resb 030

dns_q:
.size 	resw 1
.id	resw 1
.comm  	resw 1
.qd	resw 1
.an	resw 1
.ns	resw 1
.ar	resw 1
.qname_b  resb BUFF_SIZE

poll:
.fd1 resd 1
.e1  resw 1
.re1 resw 1

sockaddr_in:	resb 16	;sizeof struct sockaddr_in

buf	resb	0x200

END
