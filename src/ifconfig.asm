;Copyright (C) 2001 Jani Monoses <jani@astechnix.ro>
;
;$Id: ifconfig.asm,v 1.5 2004/07/17 17:44:02 konst Exp $
;
;hackers' ifconfig/route
;
;syntax: ifconfig interface [ip_address] [netmask net_address] 
;				[broadcast brd_address] [up] [down]
;
;	 
;	 route [ add | del ] [ -net | -host ] ip_address 
;				[netmask net_address] [gw gw_address] [dev interface] 
;
;tested on linux 2.4 with ethernet & loopback
;	   linux 2.2 with ethernet & loopback
;	   linux 2.0 with loopback
;
; 
;TODO ?:	set hw addresses (hw ether)
;		other flags (arp,promisc)

%define SHOW_STATUS

;route and interface flags

%assign	RTF_UP		1
%assign RTF_GATEWAY	2
%assign RTF_HOST	4

%assign	IFF_UP		1
%assign IFF_BROADCAST	2
%assign IFF_LOOPBACK	8
%assign IFF_RUNNING	0x40
%assign IFF_PROMISC	0x100
%assign SIOCGIFBRADDR	0x8918


%include "system.inc"

CODESEG

START:
	pop		ebp					;get argument count
	dec		ebp
	dec		ebp
%ifndef SHOW_STATUS
	jle		.exit1					;if argc <= 2 bail out
%endif

	sys_socket	AF_INET,SOCK_DGRAM,IPPROTO_IP		;subject to ioctls
	mov		dword [sockfd],eax			;save sock descr

	pop		esi					;program name

.findlast:							;ifconfig or route?	
	lodsb
	or		al,al
	jnz		.findlast
	cmp		byte[esi-2],'e'
	jz		near .route


;
;	ifconfig part
;
.ifconfig:


	pop		esi					;interface name
%ifdef SHOW_STATUS
	or		esi, esi
	jz near		.ifprint
%endif
	mov		edi,ifreq				
	_mov		ecx,16					;max name length
	repne		movsb					;put if name in ifreq

%ifdef SHOW_STATUS
	cmp		ebp, 0
	je near		.ifprints
%endif
.argloop:
	dec		ebp
	jl		.exit
	pop		esi

	cmp		byte[esi],"9"
	jle		.ipaddr

	cmp		byte[esi],"b"				; 'broadcast' 
	jnz		.netm

	pop		esi
	dec		ebp
	mov		edi,addr
	call		.ip2int
	mov		word[flags],AF_INET
	mov		ecx,SIOCSIFBRDADDR
	jmps		.ioctl

;ignore "hw ether" for now
;	cmp		byte[esi],"h"
;	jz		.ignore2	

.exit1:
	_mov		eax,1
	jmps		.exit
.netm:
	cmp		byte[esi],"n"
	jnz		.updown
	pop		esi
	dec		ebp	
	mov		edi,addr
	call		.ip2int
	mov		word[flags],AF_INET

	_mov		ecx,SIOCSIFNETMASK
.ioctl:
	call		.do_ioctl
	jmps		.argloop

;.ignore2:
;	pop		esi
;	dec		ebp
;	pop		esi
;	dec		ebp
;	jmps		.argloop	

.do_ioctl:
	mov		ebx, dword [sockfd]
	sys_ioctl	EMPTY,EMPTY,ifreq	
	ret
.exit:
	sys_exit	eax

.ipaddr:
	mov		edi,addr
	call		.ip2int
	mov		word[flags],AF_INET

	_mov		ecx,SIOCSIFADDR
	call		.do_ioctl


;"up" or "down"
.updown:
	_mov		ecx,SIOCGIFFLAGS			;get interface flags 
	call		.do_ioctl
	and		byte[flags],~IFF_UP
	cmp		byte[esi],"d"				;interface down 
	jz		.setf		
	or		byte[flags],IFF_UP	
.setf:
	_mov		ecx,SIOCSIFFLAGS			;set interface flags 
	jmps		.ioctl	 


;convert IP number pointed to by esi to dword pointed to by edi
;for invalid IP number the result is 0 (so that default == 0.0.0.0 for route)

.ip2int:
	xor		eax,eax
	xor		ecx,ecx	
.cc:	
	xor		edx,edx
.c:	
	lodsb
	sub		al,'0'
	jb		.next
	cmp		al,'a'-'0'
	jae		.next
	imul		edx,byte 10
	add		edx,eax
	jmp		short .c	
.next:
	mov		[edi+ecx],dl
	inc		ecx
	cmp		ecx, byte 4
	jne		.cc
	ret	

;
;	route part
;

.route:

	or		byte[route_flags], RTF_HOST 

	_mov		ebx,SIOCADDRT
	pop		esi
%ifdef SHOW_STATUS
	or		esi, esi
	jz near		.rtprint
%endif
	cmp		byte[esi],'a'			; 'add' or 'del' ?
	jz		.routeargs
	_mov		ebx,SIOCDELRT
.routeargs:
	dec		ebp
	jl		.doit				;if no more args proceed
	pop		esi
	cmp		word[esi], '-n'			; '-net'
	jnz		.l1
	and		byte[route_flags], ~RTF_HOST
.l1:
	cmp		word[esi], '-h'			; '-host'
	jz		.routeargs

	cmp		byte[esi], 'g'			; 'gw'
	jnz		.l2
	or		byte[route_flags], RTF_GATEWAY
	mov		edi, gw
	jmps 		.helper
.l2:
	cmp		byte[esi], 'n'			; 'netmask'
	jnz		.l3
	mov		edi, genmask
	jmps		.helper
.l3:
	cmp		word[esi+1],'ev'		; 'dev' 
	jnz		.l4
	pop		esi
	dec		ebp	
	mov		dword[dev],esi
	jmps		.routeargs
.l4:
	mov		edi,dst				; destination
	mov		word[edi], AF_INET
	_add		edi, 4
	cmp		byte[esi], 'd'			; 'default'
	jnz		.l5
	and		byte[route_flags], ~RTF_HOST
.l5:
	call		.ip2int
	jmps		.routeargs
	
.doit:	
	push		ebx
	pop		ecx
	mov		ebx, dword [sockfd]
	sys_ioctl	EMPTY,EMPTY,rtentry

	jmp		.exit 			

.helper:
	pop		esi
	dec		ebp	
	mov		word[edi], AF_INET
	_add		edi, 4
	jmps		.l5

%ifdef SHOW_STATUS

;
; ifconfig print part
;
.ifprint:
	_mov		ebp, 1
.ifpenm	mov		[flags], ebp
	mov		ecx, SIOCGIFNAME
	call		.do_ioctl
	or		eax, eax
	js	near	.exit
	push		ebp
	call		.ifprint1
	pop		ebp
	inc		ebp
	jmps		.ifpenm

; Print a single interface in ifreq
.ifprints:		; Outside entry
	push		dword	.exit
.ifprint1:
	mov		edi, rtio		; Write here
	mov		esi, ifreq		; Interface name
	call		.stxcpy
	mov		al, __t
	stosb
	_mov		ecx, SIOCGIFHWADDR	; Hardware address
	call		.do_ioctl
	; I can't determine hw address types from kernel source
	; (it is stored in sa.sa_family, but I can't interpret it)
	; so I just assume it is ethernet
	mov		esi, port
	lodsb
	call		.hexbyte
	lodsb
	call		.hexbyte
	lodsb
	call		.hexbyte
	lodsb
	call		.hexbyte
	lodsb
	call		.hexbyte
	lodsb
	call		.hexbyte
	mov		[edi - 1], byte ' '
	_mov		ecx, SIOCGIFFLAGS	; Flags
	call		.do_ioctl
	mov		ebx, [flags]
	test		bl, byte IFF_UP
	jz		.ifs1
	mov		esi, f_UP
	call		.stxcpy
.ifs1	test		bl, byte IFF_BROADCAST
	jz		.ifs2
	mov		esi, f_BR
	call		.stxcpy
.ifs2	test		bl, byte IFF_LOOPBACK
	jz		.ifs3
	mov		esi, f_LO
	call		.stxcpy
.ifs3	test		bl, byte IFF_RUNNING
	jz		.ifs4
	mov		esi, f_RU
	call		.stxcpy
.ifs4	test		bh, byte (IFF_PROMISC >> 8)
	jz		.ifs5
	mov		esi, f_PR
	call		.stxcpy
.ifs5:

	_mov		ecx, SIOCGIFADDR
	call		.do_ioctl
	mov		esi, f_inet
	call		.stxcpy
	mov		ebp, [addr]
	call		.writeipi
	dec		edi
	_mov		ecx, SIOCGIFNETMASK
	call		.do_ioctl
	mov		esi, f_mask
	call		.stxcpy
	mov		ebp, [addr]
	call		.writeipi
	dec		edi
	_mov		ecx, SIOCGIFBRADDR
	call		.do_ioctl
	mov		esi, f_broad
	call		.stxcpy
	mov		ebp, [addr]
	call		.writeipi
	mov		al, __n
	mov		[edi - 1], al
	stosb

	mov		edx, edi
	mov		ecx, rtio
	sub		edx, ecx
	sys_write	STDOUT
	ret

.stxcpy	lodsb
.sxint	stosb
	lodsb
	cmp		al, 0
	jne		.sxint
	ret

.hexbyte:	; Output a byte in al as hex
	push		eax
	shr		al, 4
	call		.hxnyb
	pop		eax
	call		.hxnyb
	mov		al, ':'
	stosb
	ret
.hxnyb	and		al, 15
	cmp		al, 10
	jb		.hxlo
	add		al, ('A' - 10) - '0'
.hxlo	add		al, '0'
	stosb
	ret


;
; route print part
; Print the entire routing table
.rtprint:
	sys_open	rttab, O_RDONLY
	mov		[sockfd], eax

	; Strip off header line!
	call		.getline

; The kernel routing table looks like this:
; Iface Dest Gateway Flags RefCnt Use Metric Mask MTU Window IRTT
; name  hex  hex     hex   n      n   n      hex  n   n      n
;
; We want to output this:
; Destination     Netmask         Gateway         Iface
; ddd.ddd.ddd.ddd ddd.ddd.ddd.ddd ddd.ddd.ddd.ddd name
	sys_write	STDOUT, rthdr, rthdr_len

.rt_print_loop:
	call		.getline

	; Read ifname until ws
	mov		edi, ifreq
.rt_i1	lodsb
	cmp		al, ' '
	jbe		.rt_ifend
	stosb
	jmps		.rt_i1

.rt_ifend:
	mov		al, __n
	stosb

	call		.readhexip	; Dest
	mov		[dst], ebp	; Output register is ebp
	call		.readhexip	; Gateway
	push		ebp

.rt_sk1:
	lodsb
	cmp		al, ' '
	jbe		.rt_sk1
.rt_sk1a:	; Skip flags
	lodsb
	cmp		al, ' '
	ja		.rt_sk1a

	; Check if this route was marked deleted
	dec		esi
	dec		esi
	lodsb
	cmp		al, 'A'
	jb		.rt_f1h
	dec		al
.rt_f1h	test		al, byte 1
	jz		.rt_print_loop		; Deleted!

	_mov		ecx, 3
.rt_sk3:	; Skip refcnt, use, metric
	lodsb
	cmp		al, ' '
	jbe		.rt_sk3
.rt_sk3a:
	lodsb
	cmp		al, ' '
	ja		.rt_sk3a
	loop		.rt_sk3

	call		.readhexip	; Mask
	push		ebp

	; All info is read, output it
	mov		edi, rtio
	mov		ebp, [dst]
	call		.writeip
	pop		ebp		; Mask
	call		.writeip
	pop		ebp
	call		.writeip
	mov		esi, ifreq
.rt_ifploop:
	lodsb
	stosb
	cmp		al, __n
	jne		.rt_ifploop
	mov		ecx, rtio
	mov		edx, edi
	sub		edx, ecx
	sys_write	STDOUT
	jmp		.rt_print_loop

.rtdone	sys_exit	0

; Read a hex ip from esi (and advance), write it to ebp in BIG ENDIAN
.readhexip:
	lodsb
	cmp		al, ' '
	jbe		.readhexip
	dec		esi
	xor		eax, eax
	xor		ebp, ebp
	_mov		ecx, 8
.rxi_l	lodsb
	cmp		al, 'A'
	jb		.rxi_d
	sub		al, ('A' - '0') - 10
.rxi_d	sub		al, '0'
	shl		ebp, 4
	or		ebp, eax
	loop		.rxi_l
	ret

; Read an ip from ebp in BIG ENDIAN and write it to edi
.writeipi:
	_mov		ecx, 4
.wxi_l	mov		eax, ebp
	shr		ebp, 8
	push		ecx
	and		eax, 255

;itoa is here
	xor		ecx, ecx
	_mov		ebx, 10
.itoa_l	xor		edx, edx
	div		ebx
	inc		ecx
	add		edx, byte '0'
	push		edx
	or		eax, eax
	jnz		.itoa_l
.itoa_p	pop		eax
	stosb
	loop		.itoa_p
;end itoa

	pop		ecx
	mov		al, '.'
	stosb
	loop		.wxi_l
; Clean up
	ret

.writeip:		; call .writeip and pad to 16 bytes
	push		edi
	call		.writeipi
	pop		ecx
	dec		edi
	sub		ecx, edi
	add		ecx, byte 16
	mov		al, ' '
.wxi_p	stosb
	loop	.wxi_p
	ret

.getline:		; Get a line into rtio
	mov		ebx, [sockfd]
	_mov		ecx, rtio
	mov		esi, ecx	; Reset input pointer
	_mov		edx, 1
.gt_lp:	sys_read
	or		eax, eax
	jna		.rtdone		; EOF!
	inc		ecx
	cmp		[ecx-1], byte __n
	jne		.gt_lp
	ret

rttab	db	'/proc/net/route', 0
rthdr	db	'Destination     Netmask         Gateway         Iface', __n
rthdr_len equ $ - rthdr

f_UP	db	'UP ', 0
f_BR	db	'BROADCAST ', 0
f_LO	db	'LOOPBACK ', 0
f_RU	db	'RUNNING ', 0
f_PR	db	'PROMISC ', 0
f_inet	db	__n, __t, 'inet addr:', 0
f_mask	db	' netmask:', 0
f_broad	db	' broadcast:', 0
%endif


UDATASEG
	sockfd		resd	1

;this corresponds to struct ifreq
	ifreq:		resb	16	;interface name
	flags:		resb	2	;flags | start of sockaddr_in
	port:		resb	2	;
	addr:		resb	4	;IP address
	unused:		resb	8	;padding in sockaddr_in

;this corresponds to struct rtentry
	rtentry:	resb	4
	dst:		resb	16	
	gw:		resb	16
	genmask:	resb	16
	route_flags:	resb	2
	unused2:	resb	14	;dword align while skipping some fields
	dev:		resb	4	;interface name
;	we don't care about the rest of it	

; And here is the output buffer for rt
	rtio:		resb 256	; Plenty (and won't overflow the pg)
END
