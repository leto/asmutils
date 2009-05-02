;Copyright (C) 2002 Michal Medvecky <m.medvecky@sh.cvut.cz>
;
;$Id: pop3d.asm,v 1.1 2002/08/14 16:56:29 konst Exp $
;
;pop3 server
;
;syntax: pop3d /spool/dir/ port
;
;basic net operations taken from httpd.asm
;
;Version 0.1 - 2002-Jan-01
;
;Nowadays, server accepts any username and any password,
;and works if mailbox exists in the spooldir.
;
;What needs to be implemented, is:
;1) we've already read username and pass on specified adresses
;2) we need to open /etc/passwd and grep line with "USERNAME:" 
;3) if it does not exist, fail (-ERR unauthorized)
;4) if it does, get salt from the passwd string (we've got from /etc/passwd), 
;   call crypt(*pass, *salt), compare result with string from /etc/passwd
;   and return either unauthorized and close connection, or OK and continue.

%include "system.inc"

CODESEG

;ok's
ident	db	"+OK asmutils pop3 server ready",__n
lenident        equ     $ - ident
mailseparator	db	0xa,0xa,0x46,0x72,0x6f,0x6d
l_m_sep         equ	$ - mailseparator
s_ok	db	"+OK", __n
l_s_ok	equ	$ - s_ok
s_ok_non	db	"+OK "
l_s_ok_non	equ	$ - s_ok_non
s_octets		db	" octets", __n
l_s_octets		equ	$ - s_octets
s_ok_user	db	"+OK User name accepted, password please",__n
l_s_ok_user	equ	$ - s_ok_user
s_bye		db	"+OK Sayonara!",__n
l_s_bye		equ	$ - s_bye
s_mbox_open	db	"+OK Mailbox open, "
l_s_mbox_open	equ	$ - s_mbox_open
s_messages	db	" messages", __n
l_s_messages	equ	$ - s_messages
s_not_implemented	db	"-ERR not implemented.",__n
l_s_not_implemented	equ	$ - s_not_implemented
s_nice_try	db	"Hmm, nice try!",__n
l_s_nice_try	equ	$ - s_nice_try
s_dot		db	".",__n
l_s_dot		equ	$ - s_dot
cr	db	__n
ten	dd	10
space		db	" "

;errors
errnoparm       db      "Usage: pop3d spooldir port",__n
len_errnoparm   equ     $-errnoparm
erruserfirst	db	"-ERR USER first", __n	;stolen from qmail :)
len_erruserfirst	equ	$-erruserfirst
errfilenotfound	db	"-ERR mailbox not found", __n
len_errfilenotfound	equ	$-errfilenotfound
err_cmd_min4	db	"-ERR COMMAND must be at least 4 characters long", __n
len_err_cmd_min4	equ	$-err_cmd_min4
err_nosuchemail		db	"-ERR No such mail message.",__n
l_err_nosuchemail	equ	$-err_nosuchemail
err_no_parm	db	"-ERR parameter missing", __n
l_err_no_parm	equ	$ - err_no_parm
err_wrong_parm	db	"-ERR parameter containing wrong characters", __n
l_err_wrong_parm	equ	$ - err_wrong_parm
err_slash	db	"Error: missing trailing slash at the end of maildir", __n
l_err_slash	equ	$ - err_slash
err_portinuse	db	"Error: could not bind() to || listen on selected port - server already running?", __n
l_err_portinuse	equ	$ - err_portinuse

;commands
c_user		db	"USER"
c_pass		db	"PASS"
c_stat		db	"STAT"
c_retr		db	"RETR"
c_dele		db	"DELE"
c_list		db	"LIST"
c_quit		db	"QUIT"

;other
integers	db	"0123456789"

convert_intn:
	call	convert_int
	sys_write	[comm_sock], cr, 1
	ret
convert_int:
	pusha
        mov edi,numend
.nextdigit:
        xor edx,edx
        div dword [ten]
        add dl,0x30
        mov [edi],dl
        dec edi
	or eax,eax 
        jne .nextdigit
        mov edx,numend
        sub edx,edi     ;message length
        inc edi
        mov ecx,edi     ;message to write
        mov ebx,[comm_sock]       ;file descriptor (stdout)
        mov eax,4       ;system call number (sys_write)
	sys_write	EMPTY, EMPTY, EMPTY
	popa	
	ret

kill_forked:
	_mov	eax, 1
	sys_exit
fatal_err:
	_mov	eax, 2
	sys_exit

sendheader:
	pusha
	sys_write [comm_sock],ident,lenident
	popa
	ret

parsecmd:					; scans for command
	xor eax,eax
	mov esi,filebuf
 	mov edi,command
	mov ecx, 0x100 		;maximum length of command

.nav1:  lodsb
	cmp al,' '
	jz .nav2
        cmp al,0xa
	jz .nav3
	stosb			;save to [command]
	dec ecx
	jnz .nav1
; if 1st parameter is over 256bytes, error
.nav3:
	mov eax, esi
	sub eax, filebuf
	dec eax
	dec eax
	mov [cmd_len], eax
	jmp .navEND
.nav2:  mov eax,esi
        sub eax,filebuf
	dec eax
	mov [cmd_len],eax
	mov ebx,esi
	mov edi,parm
	_mov ecx,0x100

.nav4:  lodsb 
	cmp al,' '
	jz .nav5
	cmp al,0xa
	jz .nav6
	stosb
	dec ecx
	jnz .nav4

;2nd parameter longer than 256b - error
	
	jmp .navEND
.nav6:  dec esi
.nav5:	sub esi,ebx
	dec esi
	mov [parm_len],esi

.navEND: 
; 	end of parsing
	cmp	[cmd_len], byte 4
	jge	.analyze_cmd
	sys_write	[comm_sock], err_cmd_min4, len_err_cmd_min4
	jmp	.cmd_done			
.analyze_cmd:
        cmp     [authorized], byte 1    ; if authorized -> don't test if it's USER cmd
        je      near .is_authorized     ; if authorized, don't test to USER/PASS command

.is_user:
        mov     ecx, [cmd_len]  ;repeat maximum of cmd_len times
	mov	edi, command
 	mov	esi, c_user
	repe 	cmpsb
	or ecx,ecx
	jne	.is_pass	; it is the c_user command
	mov	[user_issued], byte 1
	mov	esi, parm
	mov	edi, username
 	mov 	ecx, [parm_len]
	rep	movsb
	mov	[edi], byte 0
	sys_write	[comm_sock], s_ok, l_s_ok
	jmp 	.cmd_done
.is_pass:	
	cmp	[user_issued], byte 0
	jne	.isp_ui
	sys_write	[comm_sock], erruserfirst, len_erruserfirst
	jmp 	.cmd_done
.isp_ui:
	mov	edi, command
	mov	esi, c_pass
	mov	ecx, [cmd_len]
	repe	cmpsb
	cmp	ecx, 0
	jne	near	.is_stat
	mov	esi, parm
	mov	edi, password
	mov	ecx, [parm_len]
	rep	movsb
	inc	edi
	mov	[edi], byte 0
	mov	[authorized], byte 1	;TODO - authorization!!!! anyone would
					;like to implement crypt()?
	mov	ebx, finalpath
	mov	ecx, [maildir]
.back:	
	mov	al, [ecx]
	mov	byte [ebx], al
	inc	ebx
	inc	ecx
	cmp	byte [ecx], 0
	jne	.back
	mov	ecx, username
.back2:
	mov	al, byte [ecx]
	mov	byte [ebx], al
	cmp	byte [ebx], 0
	je	near .hops
	inc	ebx
	inc	ecx
	jmp 	.back2

.hops:        
	mov     [stat_count_only], byte 1
	mov	[is_list], byte 0
        call    .stat_open              ;ask STAT for number of emails :0)
        sys_write       [comm_sock], s_mbox_open, l_s_mbox_open
        push    eax
        mov     eax, [mailnum]
        call    convert_int
        pop     eax
        mov     [stat_count_only], byte 0
        sys_write       [comm_sock], s_messages, l_s_messages
	jmp	.cmd_done

.is_authorized:
.is_stat:
	mov	edi, command
	mov	esi, c_stat
	mov	ecx, [cmd_len]
	rep	cmpsb
	or ecx,ecx
	jne 	near .is_list
.stat_open:
	xor	edx, edx
	sys_open	finalpath, O_RDONLY
	mov     [mbox_fd], eax
	test	eax, eax
	jns	.open_ok
	sys_write	[comm_sock], errfilenotfound, len_errfilenotfound
	jmp	.cmd_done
.open_ok:
	xor eax,eax
	mov	[mailnum], eax
	mov	[mailsize],eax
	mov     edi, mailseparator
	mov     esi, mailseparator ;mov esi,edi
        add     esi, l_m_sep
.read:	
	pusha
	sys_read	[mbox_fd], filebuf, 0xFFFF
	mov     [tmp2], eax
	or eax,eax
	je	near	.count_done
	popa
	mov	edx, filebuf
	mov	ecx, filebuf 
	mov     ebx, filebuf
	add	edx, dword [tmp2]

.again:
	mov	al, [ecx]
	cmp	al, [edi]
	jne	.x1
	inc	edi
	cmp	edi, esi 
	jne	.x2
	inc 	dword [mailnum]
	cmp	[is_list], byte 0
	je	.x1
; LIST 
	pusha
	mov	eax, [mailnum]
	call	convert_int
	sys_write	[comm_sock], space, 1
	mov	eax, [mailsize]
	call	convert_intn
	popa
	mov	[mailsize], dword 0

.x1:	
	mov	edi, mailseparator
	mov     ecx,ebx
	inc	dword	[mailsize]
	inc 	ebx
.x2:	inc 	ecx
	cmp	ecx, edx
	je	near .read
	jmp	.again
	
.count_done:
	popa
	inc	dword	[mailnum]	;TODO - if 0 mails, then error :(
	
	cmp	[is_list], byte 0
	je	.count_done1

        mov     eax, [mailnum]	
        call    convert_int
        sys_write       [comm_sock], space, 1
        mov     eax, [mailsize]
        call    convert_intn
	sys_write	[comm_sock], s_dot, l_s_dot
	mov	[is_list], byte 0
	jmp	.count_done_all

.count_done1:
	cmp	[stat_count_only], byte 0
	je	.stat_out
	mov	[stat_count_only], byte 0
	ret
.stat_out:
	sys_write	[comm_sock], s_ok_non, l_s_ok_non
	mov	eax, [mailnum]
	call	convert_int
	sys_write	[comm_sock], space, 1
	mov	eax, [mailsize]
	call	convert_intn
.count_done_all:
	sys_close	[mbox_fd]
	jmp	.cmd_done

.is_list:
        mov     edi, command
        mov     esi, c_list
        mov     ecx, [cmd_len]
        rep     cmpsb
	or ecx,ecx
        jne .is_quit
	mov	[is_list], byte 1
	call	.stat_open
	jmp	.cmd_done

.is_quit:	
	mov	edi, command
	mov	esi, c_quit
	mov	ecx, [cmd_len]
	rep	cmpsb
	or ecx,ecx
	jne .is_retr
	sys_write	[comm_sock], s_bye, l_s_bye
	sys_close	[comm_sock]
	sys_exit	0
.is_retr:
	mov	edi, command
	mov	esi, c_retr
	mov	ecx, [cmd_len]
	rep	cmpsb
	or ecx,ecx
	jne	near .is_dele
.dele_loop:
	cmp	[parm_len], dword 0
	jg	.retr_x
	sys_write	[comm_sock], err_no_parm, l_err_no_parm
	jmp	.cmd_done

.retr_x cmp     [parm_len], dword 10
        jl      .retr_imp
        sys_write       [comm_sock], s_nice_try, l_s_nice_try
  
.retr_imp:
	;RETR implementation
        ;convert parm into integer
        mov     edx, 1
        xor     ecx, ecx
        mov     edi, parm
        add     edi, [parm_len]
.conv_cycle:
        dec     edi
        xor     eax,eax
        mov     al, byte [edi]
        sub     eax, byte '0'
	cmp	eax, 9
	jg	.retr_wrong_parm
	cmp	eax, 0
	jl	.retr_wrong_parm
        imul    eax, edx
        add     ecx, eax
        imul    edx, byte 10
        cmp     edi, parm
        jne     .conv_cycle
        ; number of the e-mail in ecx
        mov     [req_mailnum], dword ecx

        mov     [first_ofs], dword 0
        mov     [second_ofs], dword 0
	jmp	.retr_parm_ok
	;wrong params
.retr_wrong_parm:
	sys_write	[comm_sock], err_wrong_parm, l_err_wrong_parm
	jmp	.cmd_done

;	count number of emails
.retr_parm_ok:
	mov	[stat_count_only], byte 1
	call	.stat_open
	mov	eax, [mailnum]
	inc	eax
        cmp     [req_mailnum], dword 1
        jl      .retr_nosuchmail
	cmp	[req_mailnum], eax
	jl	.retr_openfile
.retr_nosuchmail:
	sys_write	[comm_sock], err_nosuchemail, l_err_nosuchemail
	jmp	.cmd_done
.retr_openfile:
;	RETR - open file
        xor     edx, edx

	mov	eax, [req_mailnum]
	call	convert_intn
        xor     edx, edx

        sys_open        finalpath, O_RDONLY
        mov     [mbox_fd], eax
        test    eax, eax
        jns     .retr_open_ok
        sys_write       [comm_sock], errfilenotfound, len_errfilenotfound
        jmp     .cmd_done

.retr_open_ok:
        mov     [mailnum], dword 1
        mov     edi, mailseparator
        mov     esi, mailseparator
        add     esi, l_m_sep
	mov	[demanded_ofs], dword 0
	xor eax,eax
        mov     dword [matched],eax
	mov	[first_ofs], eax
	mov	[second_ofs], eax
	mov	[demanded_ofs], eax
.retr_read:
        pusha
        sys_read        [mbox_fd], filebuf, 0xFFFF
        mov     [lastread], eax
	or eax,eax
        je      near	.retr_EOF
        popa
        mov     edx, filebuf
        mov     ecx, filebuf
        mov     ebx, filebuf
        add     edx, dword [lastread]
	xor	ebp, ebp

	cmp	[req_mailnum], dword 1
	jne	.retr_again
	_mov	[first_ofs], dword 1
	inc	dword [req_mailnum]

.retr_again:
        mov     al, [ecx]
        cmp     al, [edi]
        jne     near .retr_x1
        inc     edi
        cmp     edi, esi
        jne     near .retr_x2

        inc     dword [mailnum]
	mov	eax, [mailnum]
	cmp	eax, dword [req_mailnum]
	jne	.retr_not

        mov     ebp, ecx
        sub     ebp, dword l_m_sep
        sub     ebp, dword filebuf
        add     [demanded_ofs], dword ebp

	cmp	[first_ofs], dword 0
	jne	.retr_2nd
	mov	eax, [demanded_ofs]
	mov	[first_ofs], eax
	inc	dword	[req_mailnum]
	jmp	.retr_not
.retr_2nd:
        add     [first_ofs], dword 3
	mov	eax, [demanded_ofs]
	mov	[second_ofs], eax
	add	[second_ofs], dword 2
	jmp	.retr_sendit
.retr_not:
	sub	[demanded_ofs], dword ebp
.retr_x1:    
        mov     edi, mailseparator      
        mov     ecx,ebx
        inc     ebx
.retr_x2: 
	inc     ecx
        cmp     ecx, edx
        jne     near .retr_again
	push	eax
	mov	eax, [lastread]
	add	[demanded_ofs], eax
	pop 	eax
	jmp	.retr_read
.retr_EOF:
	popa
	mov	eax, [demanded_ofs]
	mov	[second_ofs], eax
	add	[first_ofs], dword 3
.retr_sendit:
	; is it DELE?
	cmp	[first_ofs], dword 4
	jne	.nnot4
	mov	[first_ofs], dword 0
.nnot4:
        cmp     [first_ofs], dword 4
        jne     .not4
        mov     [first_ofs], dword 0
.not4:
        mov     eax, dword [second_ofs]
        sub     eax, dword [first_ofs]
        mov     [mail_len], eax
        cmp     [isdele], byte 1
	jne     near .retr_really_sendit

	; DELE implementation
	pusha
        sys_write       [comm_sock], s_ok, l_s_ok
        sys_close       [mbox_fd]
	sys_open        finalpath, O_RDWR
	mov             [mbox_fd], eax
.del_loop:
	; reopen file for read-write
	sys_lseek	[mbox_fd], [second_ofs], SEEK_SET
	sys_read	[mbox_fd], filebuf, 0xFFFF
	cmp	eax, 0
	je	.dele_done
	mov	[tmp2], eax
	sys_lseek	[mbox_fd], [first_ofs], SEEK_SET
	sys_write	[mbox_fd], filebuf, [tmp2]
	mov	eax,[tmp2]
	add	[second_ofs], eax
	add	[first_ofs], eax
	jmp	.del_loop
.dele_done:
	popa
	sys_ftruncate	[mbox_fd], [first_ofs]
	sys_close	[mbox_fd]
	mov	[isdele], byte 0
	jmp	.cmd_done
	
.retr_really_sendit:
	;write email to socket
	sys_write	[comm_sock], s_ok_non, l_s_ok_non
	mov	eax, [mail_len]
	call	convert_int
	sys_write	[comm_sock], s_octets, l_s_octets
	
	sys_lseek	[mbox_fd], [first_ofs], SEEK_SET
	mov		[written], dword 0
.retr_fread:
	cmp		[mail_len], dword 0xFFFF
	jg		.retr_fread_2
	mov		edx, [mail_len]
	jmp		.retr_fread_3
.retr_fread_2:
	mov		edx, dword 0xFFFF
.retr_fread_3:
	sys_read	[mbox_fd], filebuf, EMPTY
	mov		[wasread], eax
	add		[written], dword eax
	sys_write	[comm_sock], filebuf, [wasread]
	mov		eax, [written]
	cmp		eax, [mail_len]
	jne		.retr_fread
	sys_close	[mbox_fd]
	sys_write	[comm_sock], s_dot, l_s_dot
	jmp	.cmd_done	;end of RETR

.is_dele:
        mov     edi, command 
        mov     esi, c_dele
        mov     ecx, [cmd_len]
        rep     cmpsb
        ;cmp     ecx, 0
	or ecx,ecx
        jne .not_implemented
	mov	[isdele], byte 1
	jmp	.dele_loop

.not_implemented:
	sys_write	[comm_sock], s_not_implemented, l_s_not_implemented
.cmd_done:		; commands executed and finished!
	ret

setsockoptvals	dd	1

START:
	pop	esi
	cmp	esi,byte 3		; 3 arguments must be there
	jnz	near false_exit		; !3 arguments - die

	pop	esi 			; our own name

	pop	dword [maildir]		; fetch directory where mailboxes are kept
	pop	esi			; port number 
        ; check for trailing slash at the end of maildir
	mov 	[authorized], byte 0
	mov	[user_issued], byte 0
.next_digit:				; convert port number string into integer
	lodsb
	sub	al,'0'
	jb	.done
	cmp	al,9
	ja	.done
	imul	ebx,byte 10
	add	ebx,eax
	jmps	.next_digit
.done:
	xchg	bh,bl		;now save port number into bindsock struct
	shl	ebx,16
	mov	bl,AF_INET	;if (AF_INET > 0xff) mov bx,AF_INET
	mov	[bindsockstruct],ebx

        mov     eax, [maildir]
.slashloop:
        inc     eax
        cmp     [eax], byte 0
        jne     .slashloop
        dec     eax
        cmp     [eax], byte '/'
        je      .slash_ok
        sys_write       STDOUT, err_slash, l_err_slash
        jmp     real_exit
.slash_ok:


	sys_socket PF_INET,SOCK_STREAM,IPPROTO_TCP
	mov	ebp,eax		;socket descriptor
	test	eax,eax
	js	false_exit

	sys_setsockopt ebp,SOL_SOCKET,SO_REUSEADDR,setsockoptvals,4
	or	eax,eax
	jz	do_bind

false_exit:
	sys_write STDOUT, errnoparm, len_errnoparm
	_mov	ebx,1
	jmp	real_exit
bind_error:	
	sys_write STDOUT, err_portinuse, l_err_portinuse
	_mov	ebx, 1
real_exit:
	sys_exit

do_bind:
	sys_bind ebp,bindsockstruct,16	;bind ( s, struct sockaddr *bindsockstruct, 16 );
	or	eax,eax
	jnz	bind_error		;bind error

;listen ( s, 0xff )

	sys_listen ebp,0xff
	or	eax,eax
	jnz	false_exit

	sys_fork	;fork after everything is done and exit main process
	or	eax,eax
	jz	acceptloop

true_exit:
	_mov	ebx,0
	jmps	real_exit

acceptloop:

;accept ( s, struct sockaddr *arg1, int *arg2 )

	mov	dword [arg2],16		;sizeof (struct sockaddr_in)
	sys_accept ebp,arg1,arg2
	test	eax,eax
	js	acceptloop
	mov	edi,eax ; our descriptor

;wait4 ( pid, status, options, rusage )

	sys_wait4	0xffffffff,NULL,WNOHANG,NULL
	sys_wait4

;there must be 2 wait4 calls! Without them zombies can stay on the system

	sys_fork	;we now fork, child goes his own way, daddy goes back to accept
	or	eax,eax
	jz	.forward
	sys_close edi
	jmp	acceptloop
.forward:
	mov	[comm_sock], edi		; store socket number 
        call    sendheader              ; send pop3 identification
mainloop:
        sys_read [comm_sock],filebuf,0xfff	;wait for command
	call	parsecmd
	jmp mainloop
	sys_close

endrequest:
	jmp	true_exit
DATASEG

stat_count_only db      0
is_list         db      0
isdele		db	0
matched		db	0

UDATASEG

; maybe some variables are redundant, if you have time, check and remove them :-)
arg1	resb	0xff
arg2	resb	0xff
maildir resb	0x04
finalpath	resb	0x1010	;path to spool + / + mbox_name
filebuf		resb	0xFFFF	;filebuf for reading mbox
command		resb	0xA	;POP3 command
parm		resb	0xA	;parameter of command
username	resb	0xFF	;username
password	resb	0xFF	;password
authorized      resb      1               ;0-unauthorized(default); 1-authorized
user_issued     resb      1               ;0-no 1-yes - user has to issue USER first 
integer		resb	10	;for returning integers
cmd_len		resd	1	
wasread		resd	1
written		resd	1
mbox_fd		resd	1
parm_len	resd	1
comm_sock	resd	1
bindsockstruct	resd	4
number		resd	1
numstr		resb	10
numend		resb	1
mailnum		resd	1
req_mailnum	resd	1	
first_ofs	resd	1
second_ofs	resd	1
mail_len	resd	1
demanded_ofs	resd	1
mailsize	resd	1
mail2get	resd	1
divisor		resd	1
tmp		resd	1
lastread	resd	1
tmp1		resd	1
tmp2		resd	1
dword_out	resd	1

END
