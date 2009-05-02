;Copyright (C) 2002 Rudolf Marek <marekr2@fel.cvut.cz>, <r.marek@sh.cvut.cz>, <ruik@atlas.cz>
;
;$Id: telnetd.asm,v 1.1 2002/09/09 15:53:35 konst Exp $
;
;hacker's telnetd
;
;syntax: telnet [port]
;
; Version 0.01 19-Aug-2002	very dumb version, but works good only
;				with my telnet cmd. Also is good idea (tm)
;				to use only asmutils sh as default
;

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

setsockoptvals  dd 1 

 usage: 	db "Usage: telnetd [port]",__n
 usage_llen 	equ $ - usage
%assign  usage_len  usage_llen
;code "inspirated" a bit by ping.asm

START:
    pop ebp
    cmp ebp,byte 2                              ;at least 2 args

    jb near .false_exit

    pop esi                                     ;skip program name
    pop esi                                     ;port number

;    sys_signal SIGCHLD,SIG_IGN                  ;avoid zombi

    xor eax,eax
    xor ebx,ebx

.n1:
    lodsb                                       ;bx <- port
    sub al,'0'
    jb .n2
    imul ebx,byte 10
    add ebx,eax
    jmps .n1

.n2:
    xchg bh,bl                                  ;bindsockstruct <- portl,porth,0,AF_INET
    shl ebx,16
    mov bl,AF_INET
    mov edi,bindctrl                            ;opt2
    mov [edi],ebx
    mov dword[edi+4],0                          ;INADDR_ANY

.begin:
    sys_socket PF_INET,SOCK_STREAM,IPPROTO_TCP  ;and let there be a socket...
    test eax,eax
    js .false_exit
    mov ebp,eax                                 ;ebp <- meet socket descriptor

    sys_setsockopt ebp,SOL_SOCKET,SO_REUSEADDR,setsockoptvals,4
    or eax,eax
    jz .do_bind

.false_exit:                                    ;exit_stuff
    xor ebx,ebx
    inc ebx
.real_exit:
    sys_exit

.do_bind:
    sys_bind ebp,bindctrl,16                    ;bind_ctrl
    or eax,eax
    jnz .false_exit

    sys_listen ebp,5                            ;at most five clients
    or eax,eax
    jnz .false_exit

    sys_fork                                    ;into background
    or eax,eax
    jz .acceptloop

.true_exit:                                     ;exit_stuff
    xor ebx,ebx
    jmps .real_exit

.acceptloop:                                    ;start looping for connections
    mov [arg2],byte 16
    sys_accept ebp,arg1,arg2
;TODO: test if PASV IP = this IP
    test eax,eax
    js .acceptloop

    mov edi,eax                                 ;edi <- ctrl socket descriptor
    sys_fork                                    ;new child
    or eax,eax
    jz .child
    jmps .acceptloop                             ;next pliz

;___________________________________________________________________________________________
;               CHILD   ebp(ctrl)       edi(data)
;-------------------------------------------------------------------------------------------
.child:
    mov ebp,edi
    sys_pipe pipein1                             ;pipe between ls & filter
    sys_pipe pipein2                             ;pipe between ls & filter
;    sys_pipe pipein3                             ;pipe between ls & filter

    sys_fork                                    ;for execute & filter
    or eax,eax
    je  near .execute

.filter:

.fd_setup:
	mov 	dword [tpoll.fd1],ebp
	mov	ax,POLLIN|POLLPRI
	mov	 word [tpoll.e1],ax
	mov 	 word [tpoll.e2],ax
;mov 	 word [tpoll.e3],ax
	mov 	eax,[pipein2]
	mov 	dword [tpoll.fd2],eax
;	mov 	eax,[pipein3]
;	mov 	dword [tpoll.fd3],eax
	
	sys_poll tpoll,2,060000
	test 	word [tpoll.re1],POLLIN|POLLPRI
	jnz 	.we_have_mail
	test 	word [tpoll.re2],POLLIN|POLLPRI
	jnz 	.user_stdout
;	test 	word [tpoll.re3],POLLIN|POLLPRI
;	jnz 	.user_stderr
	
	
	jmps .fd_setup

.we_have_mail:
    sys_read ebp,buff,BUFF_SIZE            ;read a bunch for filtering
    cmp eax,byte 0                              ;if none read
    jz .end_filter                              ;it means its all done
    sys_write [pipeout1],buff,eax
    jmps .fd_setup


.user_stdout:
    sys_read [pipein2],buff,BUFF_SIZE            ;read a bunch for filtering
    cmp eax,byte 0                              ;if none read
    jz .end_filter                              ;it means its all done
    sys_write ebp,buff,eax
    jmp .fd_setup
    
.user_stderr:
    
    
    
.end_filter:
    jmp .true_exit
;.filter_abort:
;    jmp .false_exit
    
.execute:
;    sys_close [pipein]
    sys_dup2 [pipein1],STDIN                   ;redirecting output of ls_process
    sys_dup2 [pipeout2],STDOUT                   ;redirecting output of ls_process
    sys_dup2 [pipeout2],STDERR                  ;redirecting output of ls_process
    
.no_params:
    sys_execve command,argv,NULL                      ;executing ls
    sys_exit 255
    

;.list_ctrl:
;.wait4another: ;This is not yet completed its better to wait until child exit
;        sys_wait4 0xffffffff,rtn,WUNTRACED,NULL 
;	test    eax,eax 
;	js      .wait4another 
;			        ;RTN struc 






command db "/bin/sh",0
argv dd command
     dd 0
UDATASEG

tpoll:
.fd1 resd 1
.e1  resw 1
.re1 resw 1
.fd2 resd 1
.e2  resw 1
.re2 resw 1

rtn resd 1
bindctrl resd 2 
binddata resd 2 
	 
	     
pipein1 resd 1 
pipeout1 resd 1 
		     
pipein2 resd 1 
pipeout2 resd 1 

sockaddr_in:	resb 16	;sizeof struct sockaddr_in

buff  resb BUFF_SIZE
arg1 resb 0xff 
arg2 resb 0xff 
       
END
