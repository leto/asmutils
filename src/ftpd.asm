;Copyright (C) 2002 Attila Monoses <ata@email.ro>
;                   Rudolf Marek <marekr2@cs.felk.cvut.cz>, <r.marek@sh.cvut.cz>
;$Id: ftpd.asm,v 1.5 2002/08/16 15:07:08 konst Exp $
;
;hackers' ftpd
;
;syntax :       ftpd config_path port
;
;example:       ftpd ftpd.conf 12345
;
;in root_directory must exist bin/ls
;(ftpd uses it for LIST request)
;
;works with console client,
;and also with mc & wincommander if root_directory/bin/ls = /bin/ls
;(the asmutils ls' output is different then the one distributed with linux
;and the visual clients like mc,wc can't parse it.
;the console client only outputs it for human view)
;
;does not support default data port (tcp20)
;tested clients don't use it but some might - obsolete
;
;must execute as root or made setuid (uses chroot)
;otherwise everything is shared
;
; Now supports PASV REST SIZE ABOR (RM)
;	       + some basic accounting see ftpd.conf for details
;
; Very good source of ftp-server-writing http://cr.yp.to/ftp.html
;
; This is still work-in-progress version, should work.
; please send me any bugs-(reports)-fixes/comments (RM)
;
; TODO:
;       get rid of root priv
;       if the user changes identity during one session, chroot will fail
;	       

%include "system.inc"
%assign POLLIN      0x0001   ; /* There is data to read */ 
%assign POLLPRI     0x0002   ; /* There is urgent data to read */ 
%assign POLLOUT     0x0004   ; /* Writing now will not block */ 
%assign POLLERR     0x0008   ; /* Error condition */ 
%assign POLLHUP     0x0010   ; /* Hung up */ 
%assign POLLNVAL    0x0020   ; /* Invalid request: fd not open */ 

;%define SLEEP


CODESEG

%define ALLOW_STORE  1
%define ALLOW_MODIFY 2

%define req_len 1024
%define buff_size 8192

%define LF 10
%define EOL 13,10

%define rep_150 1
%define rep_200 2
%define rep_215 3
%define rep_220 4
%define rep_221 5
%define rep_226 6
%define rep_230 7
%define rep_250 8
%define rep_257 9
%define rep_421 10
%define rep_502 11
%define rep_550 12
%define rep_LF 13
%define rep_CRLF 14
%define rep_350 15
%define rep_426 16
%define rep_227 17
%define rep_213 18 
%define rep_331 19
%define rep_530 20

setsockoptvals	dd 1

ls		db '/bin/ls',0
lsarg		db '-la',0
parent_dir	db '..',0

;___________________________________________________________________________________________
;               responses messages
;-------------------------------------------------------------------------------------------

rep_l db 21,23,16,19,34,24,20,20,20,5,31,30,35,1,2,56,42,5,4,36,20
;first byte is length of table

rep_1	db '150 Transfer starting',EOL
rep_2	db '200 Command ok',EOL
 rep_3	db '215 UNIX Type: L8',EOL
rep_4	db '220 Asmutils FTP server ready...',EOL
rep_5	db '221 Closing connection',EOL
rep_6	db '226 File action ok',EOL
rep_7	db '230 User logged in',EOL
rep_8	db '250 File action ok',EOL
rep_9	db '257 "'
rep_10	db '421 Error, closing connection',EOL
rep_11	db '502 Command not implemented.',EOL
rep_12	db '550 Request file action not taken',EOL
rep_13	db 10
rep_14	db 13,10
rep_15  db '350 Requested file action pending further information.',EOL
rep_16  db '426 Connection closed; transfer aborted.',EOL
rep_17  db '227 ='
rep_18  db '213 '
rep_19  db '331 User name okay, need password.',EOL
rep_20  db '530 Not logged in.',EOL
;___________________________________________________________________________________________

START:

    pop ebp
    cmp ebp,byte 3                              ;at least 2 args

    jb near .false_exit
;    jb .false_exit

    pop esi                                     ;skip program name
    pop dword[cfg_name]                             ;config name

    pop esi                                     ;port number

    sys_signal SIGCHLD,SIG_IGN                  ;avoid zombi

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
    sys_close STDOUT
    sys_close STDIN ;-> bad we might get descriptor with 0 -> this shouldnt happen (edi)
    sys_close STDERR

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
    push ebp
    call .account_read
;    sys_setuid 099
    pop ebp
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
    mov ebp,edi                                 ;ebp <- ctrl socket
    xor edi,edi
;    sys_close STDOUT
;    sys_close STDIN -> bad we might get descriptor with 0 -> this shouldnt happen (edi)
;    sys_close STDERR
    mov ecx,rep_220                             ;send wellcome message
    call .reply


;--------------------------------------------------------------------------------
; Main command "loop"
; If command received is processed
; If someone is connecting to PASV port is accepted and data socket is stored in edi
;----------------------------------------------------------------------------------
.get_command:
                       ;start looping for commands
    mov	    edx,060000 		       
    call    .fd_setup  ;out in EAX first 4 ASCII of command, 0 none command
    or 	    eax,eax
    jz 	   .get_command
    jmp    .check_if_logged ;Process the command
    
;-------------------------------
;sys_poll routine, monitors also PASV incomming connection
; Output:
;  EAX = no command
; or EAX = 4 chars of command
;------------------------------    

.fd_setup:  ;EDX = time to wait 
	mov 	eax,[pasv_socket]	; After PASV command do we have a listening socket ?
        mov     dword [tpoll.fd1],ebp 
	mov     dword [tpoll.fd2],eax   ; 0 = none
	xor 	ecx,ecx
	inc 	ecx
	or 	eax,eax
	jz	.have_one_to_listen
	inc	ecx
.have_one_to_listen:
	mov     ax,POLLIN|POLLPRI 
	mov      word [tpoll.e1],ax 
	mov      word [tpoll.e2],ax  
	
	sys_poll tpoll,EMPTY,EMPTY
	or 	eax,eax
	jz     .poll_ret
	dec 	ecx
	jz .test_one 	
	test    word [tpoll.re2],POLLIN|POLLPRI 
	jnz     .client_is_connecting ;Someone atempts o connect on PASV port
.test_one:
	test    word [tpoll.re1],POLLIN|POLLPRI 
	jnz     .we_have_mail 	;Someone sends smth via ctrl port
	xor eax,eax
.poll_ret: 
	ret
	
.client_is_connecting: ;Closes listening socket accept a data conection
    mov [arg2],byte 16
    lea esi,[pasv_socket]
    sys_accept [esi],arg1,arg2
    mov edi,eax
    sys_close [esi]
    xor eax,eax
    mov dword [esi],eax
    ;EAX should be zero
    ret

.we_have_mail:		;Lets read the ctrl connection
    sys_read ebp,req,req_len                    ;recv    
    dec eax
;    js near .get_command                             ;while request
    js  near .false_exit
    mov eax,[req]                               ;identify command for processing
    ret


.check_if_logged:
;pusha
;    sys_kill 0,019    
;    popa

 cmp byte [config_logged],0
 jnz .retr
;ALLOW only QUIT, SYST, HELP, and NOOP
    cmp eax,'USER'
    jz near .user
    cmp eax, 'PASS'
    jz near .pass
    cmp eax,'QUIT'
    jz near .quit
    cmp eax,'SYST'
    jz near .syst
    cmp eax,'NOOP'
    jz near .noop
    mov ecx,rep_530
    call .reply_get_command
    
 
;___________________________________________________________________________________________
;               RETR & STOR command
;-------------------------------------------------------------------------------------------
.retr:
    push edi                                    ;save data socket
    mov edi,operation
    mov byte[edi],1                             ;operation is RETR

    cmp eax,'RETR'                              ;is command RETR ?
    je .transfer
.stor:
    inc byte[edi]                               ;operation is STOR
    cmp eax,'STOR'                              ;is command STOR ?
    jne near .clear_seek                              ;if not, clear seek then jump to LIST
    test dword [config_flags],ALLOW_STORE
    jz  near .transfer_error
.transfer:

    call .req2asciiz

    pop edi                                     ;load data socket
    push edi                                    ;for close on error

    mov eax,O_RDWR
    test byte[operation],2                      ;if STOR
    jz .open_file
    or eax,O_CREAT|O_TRUNC

.open_file:
    sys_open esi,eax,S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP|S_IROTH            ;open file
;    or eax, byte 0
;    js .transfer_error
    test eax,eax
    js near .transfer_error

    mov esi,eax                                 ;file descriptor
    mov ecx,rep_150                             ;send start of transfer
    call .reply


    test byte[operation],2
    jz .transfer_file_seek
    xchg esi,edi                                ;in case of STOR
    jmps .transfer_file
.transfer_file_seek:
    mov eax,[seek]
    or 	eax,eax
    jz .transfer_file
    xchg eax,ecx
    sys_lseek esi,EMPTY,SEEK_SET
.transfer_file:
;    pusha
    _mov 	edx,0
    call .fd_setup
    cmp eax,'ABOR' ;TODO not to lost other than ABOR cmds
    jz .nic_moc
    cmp eax,0x4f4241f2 ;Dirty hack someone is using \362ABOR sequence too
.nic_moc:
;    popa
    jz .end_transfer_abort
    sys_read esi,buff,buff_size                 ;read a bunch
    or eax,byte 0
    je .end_transfer

    cmp byte[ftpd_TYPE],'A'                     ;is TYPE ASCII or binary?
    jne .binary_transfer
    call .ascii
    jmps .transfer_file                         ;and again
.binary_transfer:
%ifdef SLEEP
    pusha  ;Emulated 8kb/s transfer on localhost
    mov dword [sleep_n],1
    sys_nanosleep sleep_n,NULL
    popa
%endif
    sys_write edi,buff,eax                      ;...and write that bunch
    jmps .transfer_file                         ;and again

.end_transfer:
    sys_close esi                               ;close file
    sys_close edi                               ;close data connection = EOF
    xor edi,edi
    mov ecx,rep_226                             ;send ok
    call .reply_get_command
.end_transfer_abort:
    mov ecx,rep_426                             ;send ok
    call .reply
    jmps .end_transfer
.transfer_error:
    pop edi
    sys_close edi                               ;close data connection = EOF
    xor edi,edi
    mov ecx,rep_550                             ;send error
    call .reply_get_command
;___________________________________________________________________________________________



;___________________________________________________________________________________________
;               REST command
;-------------------------------------------------------------------------------------------
.clear_seek:
    pop	   edi
    mov    dword [seek],0
    cmp    eax,'REST'
    jnz    .list					;try LIST
    mov    esi,req
    add    esi,byte 5
    call   .ascii_to_num 
    mov    dword [seek],eax
    mov    ecx,rep_350                             ;send OK
    call   .reply_get_command
;___________________________________________________________________________________________
;               LIST command
;-------------------------------------------------------------------------------------------
.list:
    mov byte[operation],3                             ;operation is LIST
;    pop edi                                     ;redo stack and data socket

    cmp ax,'LI'                                 ;is command LIST?
    jne  near .port                              ;if not try PORT
    or edi,edi
    jnz .has_data_socket
    mov edx,059000
    call .fd_setup
.has_data_socket:
    lea  ecx, [sts] 
    sys_stat ls, EMPTY 
    
    test eax,eax
    jns .has_ls
    jmp .misc_common    
.has_ls:
    mov ecx,rep_150                             ;send start of transmition
    call .reply


    sys_fork                                    ;for ctrl & data
    or eax,eax
    jne  near .list_ctrl
    sys_pipe pipein                             ;pipe between ls & filter

    sys_fork                                    ;for execute & filter
    or eax,eax
    je  .execute_ls

    sys_close [pipeout]                         ;filter process doesn't write into the pipe

.filter:
    sys_read [pipein],buff,buff_size            ;read a bunch for filtering
    cmp eax,byte 0                              ;if none read
    jz .end_filter                              ;it means its all done
    push eax
%ifdef SLEEP
    pusha ;emulated 8kb/s tranfers on localhost
    mov dword [sleep_n],1
    sys_nanosleep sleep_n,NULL
    popa
%endif
;    pusha
    _mov 	edx,0
    call .fd_setup
    cmp eax,'ABOR' ;TODO not to lost other cmds
    jz .nic
    cmp eax,0x4f4241f2 ;TODO not to lost other cmds
.nic:
;    popa
    pop eax
    jz .filter_abort
    call .ascii
    jmps .filter

.end_filter:
    jmp .true_exit
.filter_abort:
    mov ecx,rep_426                             ;send closing DATA
    call .reply
    jmp .false_exit
.execute_ls:
    sys_close edi ;???
    sys_close [pipein]
    sys_dup2 [pipeout],STDOUT                   ;redirecting output of ls_process
    push edi                                    ;opt3
    mov edi,lsargs
    mov esi,ls                                  ;preparing for execution
    mov dword[edi],esi
    mov esi,lsarg
    mov dword[edi+4],esi

    mov ecx,8                                   ;mov dword[edi+8],0
    xor eax,eax                                 ;mov dword[edi+12],0
    repne lodsb

    cmp byte[req+4],13                          ;if CR is after LIST
    je .no_params                               ;then no arguments to LIST

    call .req2asciiz

    cmp byte[esi],'-'                           ;mc's syntax:  LIST -la /...
    jne .no_mc
    add esi,byte 4                              ;if mc jump over -la_
.no_mc:
    mov dword[lsargs+8],esi                     ;load path for real ls
.no_params:
    pop edi
    sys_execve ls,lsargs,0                      ;executing ls
    sys_exit 255
.list_ctrl:
.wait4another: ;This is not yet completed its better to wait until child exit
        sys_wait4 0xffffffff,rtn,WUNTRACED,NULL 
	test    eax,eax 
	js      .wait4another 
			        ;RTN struc 
				; 0-6 bit signal caught (0x7f is stopped)  
				; 7 core ? 
				;8-15 bit EXIT code 
				;if 0x7f -> 9-15 signal which caused the stop 
								
    sys_close edi
    xor edi,edi
    mov ecx,rep_250                             ;transfer successful
    call .reply_get_command

;___________________________________________________________________________________________



;___________________________________________________________________________________________
;               PORT command - DANGEROUS someone can steel your file...
;-------------------------------------------------------------------------------------------
.port:

    cmp ax,'PO'                                 ;is command PORT?
    jne  near .pasv                              	;if not try PASV

    mov esi,req
    add esi,byte 5

    xor ebx,ebx                                 ;preparing ebx for IP
    mov ecx,4

.p1:
    shl ebx,8
    call .str2int
    loop .p1                                    ;4 bytes in IP

    push ebx                                    ;changing endiannes
    pop bx
    xchg bh,bl
    shl ebx,16
    pop bx
    xchg bh,bl
    mov edi,binddata                            ;opt1
    mov dword[edi+4],ebx                        ;done with IP

    xor ebx,ebx                                 ;ebx for PORT & AF_INET
    call .str2int
    shl ebx,8
    call .str2int
    xchg bh,bl                                  ;changing endiannes
    shl ebx,16
    mov bl,AF_INET
    mov dword[edi],ebx                          ;done with PORT & AF_INET

    sys_socket PF_INET,SOCK_STREAM,IPPROTO_TCP  ;and let there be a socket...
    cmp eax,byte 0
    js .err_port
    push eax                                    ;save data socket
    sys_connect eax, edi,16                     ;make data connection
    cmp eax,byte 0
    js .err_port
    pop edi                                     ;edi <- data socket
    mov ecx,rep_200                             ;send ok
    call .reply_get_command

.err_port:
    mov ecx,rep_421                             ;send error message
    call .reply

    sys_shutdown ebp,2
    sys_close ebp
    jmp .false_exit

;___________________________________________________________________________________________
;               PASV command
;-------------------------------------------------------------------------------------------
.pasv_err_pop:
    pop eax
    pop eax
.pasv_err: ;Who knows what to send if PASV failed ?
    mov ecx,502
    call .reply_get_command

.pasv:
    cmp eax,'PASV'                             ;is command PASV?
    jne  near .type                              ;if not try TYPE
    xor    ebx,ebx ;let kernel choose the port
    mov    bl,AF_INET
    mov    edi,bindctrl                            ;opt2
    mov    [edi],ebx
    mov    dword[edi+4],0                          ;INADDR_ANY
    sys_socket PF_INET,SOCK_STREAM,IPPROTO_TCP  ;and let there be a socket...
    test eax,eax
    js .pasv_err
    mov esi,eax
    sys_setsockopt esi,SOL_SOCKET,SO_REUSEADDR,setsockoptvals,4
    test eax,eax
    js .pasv_err
    sys_bind esi,bindctrl,16                    ;bind_ctrl
    test eax,eax
    js .pasv_err
    push byte 16
    mov edx,esp
    sys_getsockname esi,bindctrl,EMPTY
    push word [bindctrl+2] ;PORT
    test eax,eax
    js near .pasv_err_pop
    sys_listen esi,1
    test eax,eax
    js near .pasv_err_pop
    mov [pasv_socket],esi
    sys_getsockname ebp,bindctrl,EMPTY
    test eax,eax
    js near .pasv_err_pop
    mov esi,bindctrl+4
    mov edi,buff
    mov ecx,rep_227                     ;start reply
    call .reply

    xor ecx,ecx
    mov cl,4
    
.ip_loop:
    xor eax,eax
    lodsb
    xor edx,edx
    call .int2str
    mov al,','
    stosb
    loop .ip_loop
    xor eax,eax
    pop ecx ;have the port in CX
    mov al,cl
    xor edx,edx
    call .int2str
    mov al,','
    stosb
    xor eax,eax    
    mov al,ch
    xor edx,edx
    call .int2str
    pop eax
    mov ax,0x0A0D
    stosw
;227 =h1,h2,h3,h4,p1,p2
    mov ecx,buff                             
    mov edx,edi
    sub edx,buff 
    call .send_custom_response

    
;___________________________________________________________________________________________



;___________________________________________________________________________________________
;               TYPE MODE STRU commands
;-------------------------------------------------------------------------------------------
.type:
    push edi                                    ;save in case it contains data socket
                                                ;these three commands may arise between
                                                ;PORT and transfere; must save data socket
    mov edi,ftpd_TYPE                           ;set destination to ftpd_TYPE
    cmp ax,'TY'                                 ;is command TYPE?
    je .tms_common

    inc edi                                     ;set destination to ftpd_MODE
    cmp ax,'MO'                                 ;is command MODE?
    je .tms_common

    inc edi                                     ;set destination to ftpd_STRU
    cmp eax,'STRU'                              ;is command STRU?
    jne .misc                                   ;if not try the rest

.tms_common:

    mov al,byte[req+5]                          ;requested transfer param
    mov esi,TMS_params                          ;supported 4 params
    mov ecx,4
.tms_check_param:
    cmp al,byte[esi]                            ;verify if supported
    je .tms_param_match
    inc esi
    loop .tms_check_param

    mov ecx,rep_502                             ;unknown parameter
    jmps .tms_reply_get_command

.tms_param_match:
    mov byte[edi],al                            ;set parameter
    mov ecx,rep_200                             ;reply ok

.tms_reply_get_command:
    pop edi                                     ;redo stack
    call .reply_get_command
;___________________________________________________________________________________________



.misc:
    cmp ax,'CD'
    je near .cdup

    push eax                                    ;save command
    call .req2asciiz
    mov ebx,esi                                 ;zero ended parameter
    pop eax                                     ;load command
;;;
    pop edi                                     ;restore data socket if there was any
    
    test dword [config_flags],ALLOW_MODIFY
    
    cmp ax,'MK'
    je near .mkd
    cmp ax,'RM'
    je  near .rmd
    cmp ax,'DE'
    je near .dele
    cmp ax,'CW'
    je .cwd
    cmp eax,'SIZE'
    je  .size
    jmp .small
;___________________________________________________________________________________________
;               SIZE command
;-------------------------------------------------------------------------------------------
; ebx hold param
.size:

    push    edi
    lea     ecx, [sts] 
    sys_stat EMPTY, EMPTY
    test    eax,eax
    js 	    near .misc_common
    mov     edi,buff
    cld
    mov     ecx,rep_213
    call    .reply
    mov	    eax, [sts.st_size]
    xor     edx,edx
    call    .int2str
    mov     ax,0x0A0D
    stosw
    mov     ecx,buff                             
    mov     edx,edi
    sub     edx,buff
    pop	    edi
    call    .send_custom_response

;___________________________________________________________________________________________
;               CWD CDUP command
;-------------------------------------------------------------------------------------------
.cdup:
    mov ebx,parent_dir                          ;cdup = cd ..
.cwd:
    sys_chdir                                   ;try to chdir
    jmps .misc_common
;___________________________________________________________________________________________



;___________________________________________________________________________________________
;               MKD command
;-------------------------------------------------------------------------------------------
.mkd:
    test dword [config_flags],ALLOW_MODIFY
    jz .deny
    mov ecx,S_IRWXU|S_IRWXG|S_IRWXO
    sys_mkdir                                   ;try to mkdir
    jmps .misc_common
;___________________________________________________________________________________________


;___________________________________________________________________________________________
;               DELE command
;-------------------------------------------------------------------------------------------
.dele:
    test dword dword [config_flags],ALLOW_MODIFY
    jz .deny
    sys_unlink                                  ;try to unlink
    jmps .misc_common

;___________________________________________________________________________________________
;               RMD command
;-------------------------------------------------------------------------------------------
.rmd:
    test dword [config_flags],ALLOW_MODIFY
    jz .deny
    sys_rmdir                                   ;try to rmdir
    jmps .misc_common
;___________________________________________________________________________________________


    
.deny: ;send 550 or 530 wgen deny the service ???
    jmps .misc_error
    
.misc_common:
    or eax, byte 0
    jnz .misc_error

    mov ecx,rep_250                             ;success
    jmps .misc_reply_get_command

.misc_error:
    mov ecx,rep_550                             ;or not
.misc_reply_get_command:
    call .reply_get_command
;___________________________________________________________________________________________



;___________________________________________________________________________________________
;               USER command
;-------------------------------------------------------------------------------------------
.user:
;    sys_chdir  [root]
;    sys_chroot [root]
    call .req2asciiz
    call .find_user_in_config ;OUT EAX return code, IN ESI username ASCIIZ
    xchg  eax,ecx
    jmps .misc_reply_get_command


;___________________________________________________________________________________________
;               PASS command
;-------------------------------------------------------------------------------------------
.pass:
;pusha
;    sys_kill 0,019    
;    popa

    call .req2asciiz
    call .setup_user_config ;OUT EAX return code, IN ESI pass ASCIIZ
    xchg  eax,ecx
    jmps .misc_reply_get_command
;___________________________________________________________________________________________



;___________________________________________________________________________________________
;               SYST command
;-------------------------------------------------------------------------------------------
.syst:
    mov ecx,rep_215
    jmps .misc_reply_get_command
;___________________________________________________________________________________________



;___________________________________________________________________________________________
;               NOOP command
;-------------------------------------------------------------------------------------------
.noop:
    mov ecx,rep_200
    jmps .misc_reply_get_command
;___________________________________________________________________________________________

;___________________________________________________________________________________________
;               ABOR command
;-------------------------------------------------------------------------------------------
.abor:
    mov ecx,rep_226
    jmps .misc_reply_get_command
;___________________________________________________________________________________________


.small:
;    pop edi                                     ;restore data socket if there was any

    cmp ax,'US'
    je .user
    cmp eax,'PASS'
    je .pass
    
    cmp ax,'SY'
    je  .syst
    cmp ax,'NO'
    je .noop
    cmp ax,'QU'
    je .quit
    cmp ax,'PW'
    je .pwd
    cmp eax,'ABOR'
    jz .abor
    cmp eax,0x4f4241f2 ;ABOR with \362
    jz .abor

;___________________________________________________________________________________________
;               unknown command
;-------------------------------------------------------------------------------------------
    mov ecx,rep_502
    call .reply_get_command
;___________________________________________________________________________________________



;___________________________________________________________________________________________
;               QUIT command
;-------------------------------------------------------------------------------------------
.quit:
    mov ecx,rep_221
    call .reply

    jmp .true_exit
;___________________________________________________________________________________________



;___________________________________________________________________________________________
;               PWD command
;-------------------------------------------------------------------------------------------
.pwd:
    mov ecx,rep_257                     ;start reply
    call .reply

    sys_getcwd buff,buff_size

    mov esi,buff
    xor ecx,ecx

.pwd_getend:
    lodsb
    inc ecx
    test al,al
    jnz .pwd_getend                     ;replace trailing 0

    dec esi                             ;with
    mov dword[esi],658722               ; \"\r\n
    inc ecx
    inc ecx
    sys_write ebp,buff,ecx              ;end reply

    jmp .get_command
;___________________________________________________________________________________________



;___________________________________________________________________________________________
;               function string to int
;-------------------------------------------------------------------------------------------
.str2int:
    xor eax,eax
    lodsb
    sub al,'0'
    jb .l2

    mov dh,bh
    xor bh,bh
    imul bx,byte 10
    or bh,dh

    add ebx,eax
    jmp .str2int
.l2 :
    ret
;___________________________________________________________________________________________

.int2str:
        ;; Print an integer as a decimal string
        ;; REQUIRES: integer(dividend) in eax,
        ;;      edx = 0 before calling (holds remainder),
        ;;      string destination in edi
        ;; MODIFIES: edi

        push    eax
        push    ebx
        push    ecx
        push    edx
        or      eax, eax
        jnz     .keep_recursing
        ;; special case of zero
        or      edx, edx
        jz      .write_remainder
        jmps    .break_recursion

.keep_recursing:
        mov     edx, 0
        mov     ebx, 10
        div     ebx

        call    .int2str

.write_remainder:
        mov     eax, edx
        add     eax, '0'
        stosb

.break_recursion:
        pop     edx
        pop     ecx
        pop     ebx
        pop     eax
        ret
;--------------------------------------- 
; esi = string 
; eax = number  
.ascii_to_num: 
    push    esi 
    push    ebx
    xor     eax,eax                 ; zero out regs 
    xor     ebx,ebx 
 
.next_digit: 
    lodsb                           ; load byte from esi 
    sub     al,'0'                  ; '0' is first number in ascii 
    jb 	    .done
    imul    ebx,10 
    add     ebx,eax 
    jmps     .next_digit 
.done: 
    xchg    ebx,eax 
    pop     ebx
    pop     esi 
    ret 
																					
;___________________________________________________________________________________________
;               function ASCII  ( edi buff eax )
;in case of incoming data cuts out the CR just before LF
;in case of outgoing data inserts a CR before every LF
;-------------------------------------------------------------------------------------------
.ascii:
    pusha

    mov ebp,edi                                 ;destination
    mov edi,buff                                ;source for scan
    mov ecx,eax                                 ;length of string to scan

.scan:
    cld
    mov al,LF                                   ;looking for LF
    mov esi,edi                                 ;scanned the string from ...
    repne scasb                                 ;scan
    sub edi,esi                                 ;scanned length

    cmp byte[edi+esi-1],LF                      ;even if its a trailing LF
    je .found_LF

    call .send_ascii                            ;write it all forward to the client

.return_ascii:
    popa
    ret

.found_LF:
    xor eax,eax
    inc eax
    push ecx                                    ;these were for outgoing
    mov ecx,rep_CRLF
    cmp byte[operation],2                       ;is it STOR (incoming) ?
    jne .no_stor

    inc eax                                     ;diffs of incoming ascii
    mov ecx,rep_LF                              ;from outgoing ascii

.no_stor:
    sub edi,eax                                 ;if found go back to point to it

    call .send_ascii                            ;send the line
    call .reply                                 ;and LF or CRLF
    pop ecx
    cmp ecx, byte 0
    je .return_ascii                            ;in case of trailing LF

    add edi,eax
    add edi,esi                                 ;go back to found LF
    jmp .scan                                   ;next line from same bunch
;___________________________________________________________________________________________



;___________________________________________________________________________________________
;               function req2asciiz
;put end of string after request
;and return first parameter in esi
;-------------------------------------------------------------------------------------------
.req2asciiz:
    push edi
    mov ecx,req_len                             ;cover the request
    mov edi,req                                 ;take request
    mov al,32                                   ;find first argument
    repne scasb
    push edi                                    ;save argument
    mov al, 13                                  ;look for CR
    repne scasb                                 ;lookin'...
    dec edi
    mov byte[edi],0                             ;replace CR with EOStr
    pop esi 
    pop edi                                    ;load argument
    ret
;___________________________________________________________________________________________



;___________________________________________________________________________________________
;               function reply
;replacement for all kinds of sys_write
;-------------------------------------------------------------------------------------------

.send_ascii:
    pusha
    mov ecx,esi
    mov edx,edi
    jmps .common_sys_write
.send_custom_response:
    inc byte[rgc]
    pusha
;    mov ecx,esi
;    mov edx,edi
    jmps .common_sys_write
    

.reply_get_command:
    inc byte[rgc]
.reply:
    pusha

    xor eax,eax

    mov esi,rep_l                               ;reply-length table
    mov edx,esi                                 ;0th reply offset

.reply_select:                                  ;to get the offset
    lodsb                                       ;of required reply
    add edx,eax                                 ;add the length of each reply
    loop .reply_select                          ;placed before it

    mov cl,byte[esi]                            ;rep_len
    xchg ecx,edx                                ;prepare for sys_write
.common_sys_write:
    mov ebx,ebp
    sys_write

    popa
    dec byte[rgc]
    jz .and_get_command

    inc byte[rgc]
    ret
.and_get_command:
    pop eax
    pop eax
    jmp .get_command
;___________________________________________________________________________________________
;read_config
;-------------------------------------------------------------------------------------------
; 
; ;username       password     flag           homedir
; anonymous      *            2            /home/ftp/anonymous
; EOF

.find_new_line:    
    lodsb
    cmp al,0xA
    jnz .find_new_line
    ret

.skip_blank:
    lodsb
    cmp al,' '
    jz .skip_blank
    cmp al,9
    jz .skip_blank
    dec esi
    ret

.EOF: db "EOF",0

.find_user_in_config: ;OUT EAX return code, IN ESI username ASCIIZ

    push edi
    xchg edi,esi
    mov esi,[config_ptr]
    ;EDI = username ASCIZ ESI=config file

.analyze_next_line:
    call .skip_blank
    cmp al,';'
    jz .run_new_line
    push edi
    push esi
    mov edi,.EOF
    call .string_compare
    pop esi
    pop edi
    or ecx,ecx
    jz .not_found_such_user
.analyze_line:
    push edi
    push esi
    call .string_compare    
    or ecx,ecx
    jz .parse_rest_of_line
    pop esi
    pop edi
.run_new_line:
    call .find_new_line
    jmps .analyze_next_line
    
.not_found_such_user:
    xor eax,eax
    mov [config_ptr_line],eax
    mov eax,rep_331
    pop edi
    ret

.parse_rest_of_line:
    pop eax 
    pop edi
    mov [config_ptr_line],esi
    mov eax,rep_331
    pop edi
    ret
    


.setup_user_config:
;pusha
;    sys_kill 0,019    
;popa
    mov byte [config_logged],0
    push edi
    xchg esi,edi
    mov esi,[config_ptr_line]
    or esi,esi
    jz .bad_pass
    ;ESI config line
    ;EDI ASCIIZ password
    call .skip_blank
    push edi
    push esi
    cmp byte [esi],'*'
    jz .pass_match
    call .string_compare    
    or ecx,ecx
    jz .pass_match
    ;dont
    pop esi
    pop edi
.bad_pass:
    mov eax,rep_530
    pop edi
    ret
.pass_match:
    pop eax
    pop edi
    inc esi
    call .skip_blank
    call .ascii_to_num
    mov [config_flags],eax
    ;ESI is not set after the flag Number ;fix this
    inc esi ;WE assume that flag has only 1 char
    call .skip_blank
    push esi
.dummy_loop2:
    lodsb
    cmp al,0x21
    jnb .dummy_loop2
    dec esi
    mov byte [esi],0
    pop esi
    sys_chdir esi
    test eax,eax
    js .bad_pass
    sys_chroot esi
    test eax,eax
    js .bad_pass
    mov byte [config_logged],1

    mov eax,rep_230
    pop edi
    ret
    
.account_read:
    sys_open [cfg_name],O_RDONLY
    test eax,eax
    js near .false_exit
    mov ebx,eax
    sys_fstat EMPTY,sts
    push ebx
    sys_mmap 0,dword [sts.st_size],PROT_READ|PROT_WRITE,MAP_PRIVATE,ebx,0
    test eax,eax
    js near .false_exit
    mov [config_ptr],eax
    pop ebx
    sys_close EMPTY
    ret


;**************************************************************************** 
;* string_compare *********************************************************** 
;**************************************************************************** 
;* esi=>  pointer to string 1 
;* edi=>  pointer to string 2 
;* <=ecx  == 0 (string are equal), != 0 (strings are not equal) 
;* <=esi  pointer to string 1 + position of first nonequal character 
;* <=edi  pointer to string 2 + position of first nonequal character 
;**************************************************************************** 
.string_compare: 
        push    edx 
	push    edi 
	call    .string_length 
	mov     edx,ecx 
	mov     edi,esi 
	call    .string_length 
	cmp     ecx,edx 
	jae     .length_ok 
	mov     ecx,edx 
.length_ok: 
	pop     edi 
	cld 
	repe    cmpsb 
	pop     edx 
	ret 
    
;**************************************************************************** 
;* string_length ************************************************************ 
;**************************************************************************** 
;* edi=>  pointer to string 
;* <=ecx  string length (including trailing \0) 
;* <=edi  pointer to string + string length 
;**************************************************************************** 
.string_length: 
	xor     ecx,ecx 
.next_char:
	inc    ecx
	cmp     byte [edi],0x21
	inc     edi
	jnb .next_char
;	dec     ecx 
;	cld 
;        repne   scasb 
;	neg     ecx 
	ret 
									
DATASEG

    ftpd_DPORT dw 20                            ;data port ; default 20
    ftpd_TYPE db 'I'                            ;image type
    ftpd_MODE db 'S'                            ;stream mode
    ftpd_STRU db 'F'                            ;file structure

    TMS_params db 'A','I','S','F'               ;transmition parameters implemented
                                                ;ascii, image, stream, file
; username      group   password                u m M um  l  mhds ip            home


UDATASEG
;		mov	eax, [DATAOFF(sts.st_size)]
small_buff resb 1
sts:
%ifdef __BSD__
B_STRUC Stat,.st_ino,.st_mode,.st_nlink,.st_uid,.st_gid,.st_rdev,.st_mtime,.st_size,.st_blocks
%else
B_STRUC Stat,.st_ino,.st_mode,.st_nlink,.st_uid,.st_gid,.st_rdev,.st_size,.st_blocks,.st_mtime
%endif
%ifdef SLEEP
sleep_n resd 4
%endif

config_ptr resd 1
config_ptr_line resd 1
config_logged resb 1
config_flags resd 1

rtn resd 1
    pasv_socket resd 1
    seek resd 1
    rgc resb 1                                  ;ReplayGetCommand

    arg1 resb 0xff
    arg2 resb 0xff

    bindctrl resd 2
    binddata resd 2

    lsargs resd 6

    pipein resd 1
    pipeout resd 1

    cfg_name resd 1

    operation resb 1                            ;RETR | STOR | LIST

    buff resb buff_size
    req resb 1024
    tpoll: 
    .fd1 resd 1 
    .e1  resw 1 
    .re1 resw 1 
    .fd2 resd 1 
    .e2  resw 1 
    .re2 resw 1 
    
END

;sample ftpd.conf: remove (one) leading ';' on each line and save as ftpd.conf

;-------- cut --------

;; flag OR 1 =>  right to (APPE, STOR, STOU)
;; flag OR 2 =>  right to (APPE, CHMOD, DELE, MKD, RMD, RNFR, RNTO)
;;
;;use EOF to ensure the end of file...
;;
;; TODO: set default umask
;;
;;username      password     flag           homedir 
;ruik           asmrulez     3            /home/ftp/anonymous
;anonymous      *            0            /home/ftp/anonymous 
;konst          asmruleztoo  2            /home/ftp/anonymous
;EOF

;-------- cut --------
