;Copyright (C) 2001,2002 Rudolf Marek <marekr2@fel.cvut.cz>, <r.marek@sh.cvut.cz>, <ruik@atlas.cz>
;
;$Id: telnet.asm,v 1.2 2002/02/20 15:30:32 konst Exp $
;
;hacker's telnet
;
;syntax: telnet IP [port]
;
; Version 0.01 xx-Feb-2002	very dumb version, but works (somehow) 
;
; Notes:
;
; Dear Hacker !
; I know this program isn't perfect, but it works for me. I hope
; You will have same luck. If you want to improve it here is your chance.
;
; When connection is estabilished the server/client have to debate on
; options to use.
;
;rfc854.txt  rfc856.txt	rfc858.txt  rfc860.txt
;rfc855.txt  rfc857.txt	rfc859.txt  rfc861.txt
;
; It offen commemorates the market place. One will say I will give you this
; other side agree/disagree with it and so on. Big problem is how to say
; to other side without big parser to shut up and give login:
; Strategy used here is to say won't to all options (exept the ECHO)
; So other side won't bother us with so-called 'subnegotiation'
; I'm suspecting the telnet server to send IAC strings not only
; at the begining of recv data but also somewhere between. This IAC
; are ignored for now.
;
; Have fun !

%include "system.inc"

%assign POLLIN      0x0001   ; /* There is data to read */
%assign POLLPRI     0x0002   ; /* There is urgent data to read */
%assign POLLOUT     0x0004   ; /* Writing now will not block */
%assign POLLERR     0x0008   ; /* Error condition */
%assign POLLHUP     0x0010   ; /* Hung up */
%assign POLLNVAL    0x0020   ; /* Invalid request: fd not open */
%assign ECONNREFUSED	0111
				     
%assign	IAC	0xff		;/* interpret as command: */
%assign	DONT	0xfe		;/* you are not to use option */
%assign	DO	0xfd		;/* please, you use option */
%assign	WONT	0xfc		;/* I won't use option */
%assign	WILL	0xfb		;/* I will use option */
%assign	SB	0xfa		;/* interpret as subnegotiation */
%assign	GA	0xf9		;/* you may reverse the line */
%assign	EL	0xf8		;/* erase the current line */
%assign	EC	0xf7		;/* erase the current character */
%assign	AYT	0xf6		;/* are you there */
%assign	AO	0xf5		;/* abort output--but let prog finish */
%assign	IP	0xf4		;/* interrupt process--permanently */
%assign	BREAK	0xf3		;/* break */
%assign	DM	0xf2		;/* data mark--for connect. cleaning */
%assign	NOP	0xf1		;/* nop */
%assign	SE	0xf0		;/* end sub negotiation */
%assign EOR     0xef             ;/* end of record (transparent mode) */
%assign	ABORT	0xee		;/* Abort process */
%assign	SUSP	0xed		;/* Suspend process */
%assign	xEOF	0xec		;/* End of file: EOF is already used... */
%assign SYNCH	0242		;/* for telfunc calls */
%assign _BINARY	00	;/* 8-bit data path */
%assign _ECHO	01	;/* echo */
%assign	_RCP	02	;/* prepare to reconnect */
%assign	_SGA	03	;/* suppress go ahead */
%assign	_NAMS	04	;/* approximate message size */
%assign	_STATUS	05	;/* give status */
%assign	_TM	06	;/* timing mark */
%assign	_RCTE	07	;/* remote controlled transmission and echo */
%assign _NAOL 	08	;/* negotiate about output line width */
%assign _NAOP 	09	;* negotiate about output page size */
%assign _NAOCRD	010	;* negotiate about CR disposition */
%assign _NAOHTS	011	;/* negotiate about horizontal tabstops */
%assign _NAOHTD	012	;/* negotiate about horizontal tab disposition */
%assign _NAOFFD	013	;/* negotiate about formfeed disposition */
%assign _NAOVTS	014	;/* negotiate about vertical tab stops */
%assign _NAOVTD	015	;/* negotiate about vertical tab disposition */
%assign _NAOLFD	016	;/* negotiate about output LF disposition */
%assign _XASCII	017	;/* extended ascii character set */
%assign	_LOGOUT	018	;/* force logout */
%assign	_BM	019	;/* byte macro */
%assign	_DET	020	;/* data entry terminal */
%assign	_SUPDUP	021	;/* supdup protocol */
%assign	_SUPDUPOUTPUT 022	;/* supdup output */
%assign	_SNDLOC	023	;/* send location */
%assign	_TTYPE	024	;/* terminal type */
%assign	_EOR	025	;/* end or record */
%assign	_TUID	026	;/* TACACS user identification */
%assign	_OUTMRK	027	;/* output marking */
%assign	_TTYLOC	028	;/* terminal location number */
%assign	_3270REGIME 029	;/* 3270 regime */
%assign	_X3PAD	030	;/* X.3 PAD */
%assign	_NAWS	031	;/* window size */
%assign	_TSPEED	032	;/* terminal speed */
%assign	_LFLOW	033	;/* remote flow control */
%assign _LINEMODE	034	;/* Linemode option */
%assign _XDISPLOC	035	;/* X Display Location */
%assign _OLD_ENVIRON 036	;/* Old - Environment variables */
%assign	_AUTHENTICATION 037;/* Authenticate */
%assign	_ENCRYPT	038	;/* Encryption option */
%assign _NEW_ENVIRON 039	;/* New - Environment variables */
%assign	_EXOPL	0255	;/* extended-options-list */


CODESEG

;
%assign IP_TOS  	1
%assign SOL_IP  	0
%assign BUFF_SIZE    01024
%assign FIONBIO     0x5421 


 connected 	db "Connected :) escape charter is NYI",__n
 connected_len 	equ $ - connected
 usage: 	db "Usage: telnet IP [port]",__n
 usage_llen 	equ $ - usage
 refused: 	db "Connection refused :(",__n
 refused_llen 	equ $ - refused

%assign  refused_len  refused_llen
%assign  usage_len  usage_llen
;code "inspirated" a bit by ping.asm
START:
	call 	tty_init
	pop 		ebx
	dec 		ebx
	jnz 		.ok
	sys_write STDOUT,usage,usage_len
	xor		eax,eax
.exit:

	or	eax,eax
	jz	.ok_exit
	cmp eax,-ECONNREFUSED
	jnz .ok_exit
	sys_write STDOUT,refused,refused_len 
.ok_exit:
	call tty_restore
	sys_close ebp
	sys_exit 0


.ok:
	pop		ebx					;arg 0 - program name
	pop		esi					;arg 1 - IP number
		
	mov		edi, sockaddr_in
	call		.ip2int					;fill in sin_addr.s_addr 
	pop		esi
	mov		bl,023
	or 		esi,esi
	jz 		.done
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
	
	mov		dword[edi], AF_INET | (IPPROTO_IP << 16);fill in sin_family and sin_port
	mov 		byte [edi+3],bl
	sys_socket	PF_INET, SOCK_STREAM, IPPROTO_IP		;create raw socket
	test		eax,eax									
.ex_help:
	js near		.exit

	mov		ebp, eax	;save socket descriptor
	push byte       0x10
	mov edi,esp
        sys_setsockopt eax,SOL_IP,IP_TOS,edi,4		
	test		eax,eax									
	pop eax
	js		 .ex_help
	sys_connect 	ebp,sockaddr_in,16
	test		eax,eax									
	js		 .ex_help
	push byte       0x1
	mov edi,esp
	sys_setsockopt ebp,0x1,0xa,edi,4		
	test		eax,eax									
	pop eax
	js		 .ex_help
;	push byte 1
;	sys_ioctl ebp,FIONBIO,esp
;	test		eax,eax									
;	pop eax
;	js		near .exit
	sys_write STDOUT,connected,connected_len
.fd_setup:
	mov 	dword [tpoll.fd1],ebp
	mov	ax,POLLIN|POLLPRI
	mov	 word [tpoll.e1],ax
	mov 	dword [tpoll.fd2],STDIN
	mov 	 word [tpoll.e2],ax
	
	sys_poll tpoll,2,060000
	test 	word [tpoll.re1],POLLIN|POLLPRI
	jnz 	.we_have_mail
	test 	word [tpoll.re2],POLLIN|POLLPRI
	jnz 	.user_is_writing
	jmps .fd_setup


.user_is_writing:
	sys_read STDIN,buffer,BUFF_SIZE
	sys_write ebp,buffer,eax
	jmp	.fd_setup
.we_have_mail:
	mov 	esi,buffer
        sys_read ebp,esi,BUFF_SIZE
	or 	eax,eax
	jz 	near .exit
	mov	edx,eax
	mov 	edi,esi
	add 	edi,eax
	cmp byte [esi],IAC
	jz .command
	sys_write STDOUT,esi,eax 
	jmp .fd_setup

.blank: lodsb
.command:
	cmp 	esi,edi
	jz 	.send_cmds_back
	lodsb
	cmp 	al,IAC
	jnz 	.cmd_end
	lodsb 	;Command ??
	cmp 	al,DONT
	jz 	.blank
	cmp 	al,WILL
	jz 	.blank
	cmp 	al,WONT
	jz 	.blank
	cmp 	al,DO
	jnz 	.command
	lodsb ;command 
	cmp 	al,ECHO
	mov 	al,WONT
	jnz 	.isnt_echo
.is_echo:
	mov 	al,WILL
	.isnt_echo:
	mov 	byte [esi-2],al
	jmps .command
.send_cmds_back:
	sys_write ebp,buffer,edx
	jmp .fd_setup
.cmd_end:
	push 	esi
	push 	edx
	sub 	esi,buffer
	push 	esi
	dec 	esi
	sys_write ebp,buffer,esi ;to send
	pop 	ebx
	pop 	edx
	pop 	esi
	sub 	edx,ebx
;TODO: check after printable text for COMMANDS
	sys_write STDOUT,esi,edx 
	jmp .fd_setup




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

tty_init:
	mov	edx, termattrs
	sys_ioctl STDIN, TCGETS
	mov	eax,[termattrs.c_lflag]
	push 	eax
	and	eax, ~(ECHO|ICANON)
	mov	[termattrs.c_lflag], eax
	sys_ioctl STDIN, TCSETS
	pop	dword [termattrs.c_lflag]
	ret


tty_restore:
	sys_ioctl STDIN, TCSETS,termattrs
	ret

UDATASEG

tpoll:
.fd1 resd 1
.e1  resw 1
.re1 resw 1
.fd2 resd 1
.e2  resw 1
.re2 resw 1
sockaddr_in:	resb 16	;sizeof struct sockaddr_in

termattrs B_STRUC termios,.c_lflag
buffer  resb BUFF_SIZE

END
