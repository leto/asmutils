;Copyright (C) 2000-2003 Alexandr Gorlov <ct@mail.ru>
;			 Karsten Scheibler <karsten.scheibler@bigfoot.de>
;			 Rudolf Marek <marekr2@fel.cvut.cz>
;       		 Joshua Hudson <joshudson@hotmail.com>
;       		 Thomas Ogrisegg <tom@rhadamanthys.org>
;       		 Konstantin Boldyshev <konst@linuxassembly.org>
;       		 Nick Kurshev <nickols_k@mail.ru>
;
;$Id: sh.asm,v 1.24 2003/06/07 06:32:15 nickols_k Exp $
;
;hackers' shell
;
;syntax: sh [filename]
;
; Command syntax:
;	[[relative]/path/to/]program [argument ...]
;
; Conditional syntax:
;	command
;	{&& | ||} command
;	...
; Now you can enjoy basic redirection support !
;
; ls|grep asm|grep s>>list 
;
;or just:
;
;  ls|sort
;  cat<my_input
;  cat sh.asm > my_output
;  cat sh.asm>>my_appended_output  (spaces between > | < aren't mandatory)
;  
; And wildcard extending !
;
; echo asm??ils*.*.* rulez
;
; Job control:
;
; ctrl+z works as expected, shell will return the job id.
; via fg id, bg id you can put job for/back-ground
; jobs - will list jobs
;
; Comments:
;
; Parser skips everything after '#' character when it is not quoted,
; so you can use usual #!path/to/asmutils/shell construction in scripts.
;
; Note: 
;	if shell receives SIGTRAP it means it has run out of some
;	resources, array size mostly. I don't know if it is good idea (tm)
;	to handle such situation by signal handler (RM)
;
;
;0.01: 07-Oct-2000	initial release (AG, KS)
;0.02: 26-Jul-2001      added char-oriented commandline, tab-filename filling,
;			partial export support, 
;			partial CTRL+C handling (RM)
;0.03: 16-Sep-2001      added history handling (runtime hist), 
;			improved signal handling (RM)
;0.04: 30-Jan-2002	added and/or internals and scripting (JH)
;0.05: 10-Feb-2002      added pipe mania & redir support, 
;			shell inherits parent's env if any (RM)
;0.06  16-Feb-2002	added wildcard extending (RM),
;                     	added $environment variable handling
;                     	and some control-characters (TO)
;0.07  23-Feb-2002	added ctrl+z handling, fg, bg, jobs 
;			internal commands, some bugfixes (RM)
;0.08  01-Mar-2002	'#' comments, improved scripting, misc fixes,
;			cleanup, WRITE_* macros (KB)
;0.09  08-Mar-2002	added clear internal (KB)
;0.10  26-Sep-2002	Fixed tab-filling (RM)
;0.11  11-Feb-2003	Improved Jobs, added umask (merged another tree) (JH)
;0.12  06-Jun-2003	added: help, enable, pushd, popd, dirs (NK)

%include "system.inc"

%define HISTORY ;%undef HISTORY saves 192 bytes + dynamic memory for cmdlines
%define TTYINIT

%ifdef	__LINUX__
%define SPGRP
%endif

;****************************************************************************
;****************************************************************************
;*
;* PART 1: assign's
;*
;****************************************************************************
;****************************************************************************

%assign CMDLINE_BUFFER1_SIZE		0x001000
%assign CMDLINE_BUFFER2_SIZE		0x010000	;so much ?
%assign CMDLINE_PROGRAM_PATH_SIZE	0x001000
%assign CMDLINE_MAX_ARGUMENTS		(CMDLINE_BUFFER1_SIZE / 2)
%assign CMDLINE_MAX_ENVIRONMENT		50
%assign MAX_PID				10 ;how many background processes we can handle
%assign PATH_MAX			0x1000 ;; according on <linux/limits.h>

%assign ENTER 		0x0a
%assign BACKSPACE 	0x08
%assign DEL 		0x7f
%assign TABULATOR 	0x09
%assign ESC 		0x1b
%assign CTRL_D          0x04
%assign CTRL_L          0x0c

%assign FILE_BUF_SIZE	0x200

;
;macros
;

%macro	WRITE_CHARS 0-2
%if %0>0
	_mov	eax,%1
%if %0>1
	_mov	ecx,%2
%endif
%endif
	call	write_chars
%endmacro

%macro	WRITE_STRING 0-1
%if %0>0
	_mov	eax,%1
%endif
	call	write_string
%endmacro

%macro	WRITE_ERROR 0-1
%if %0>0
	_mov	eax,%1
%endif
	call	write_error
%endmacro

CODESEG

;****************************************************************************
;****************************************************************************
;*
;* PART 2: start code
;*
;****************************************************************************
;****************************************************************************

START:
	mov	dword [cur_dir],0x2F2E	;"./"
	pop 	esi			;dont want argc
	pop 	edi			;prg name
	call    environ_initialize
	pop	ebp			;shell_script
	call	environ_inherit		;copy parent's env to our struc
	mov 	edi,ebp
	or	edi,edi
	jz	.interactive_shell
	;-----------------
	;open shell script
	;-----------------
	sys_open edi,O_RDONLY
	or	eax,eax
	jnz	.script_opened
	
	WRITE_ERROR text.scerror
	sys_exit 2

.script_opened:
	mov	[script_fd],eax
	mov	dword [cmdline.prompt],text.prompt_ptrace
	jmp	conspired_to_run

.interactive_shell:
	mov	byte [interactive],1	;interactive flag

	WRITE_STRING text.welcome	;write welcome message
	mov	[script_fd],edi		;edi = 0, STDIN
	call	tty_initialize		;initialize terminal
	;---------------------------
	;Experimental error handling
	;---------------------------
%ifdef __LINUX__
	mov 	edi,signal_struc.handler
	mov 	dword [edi],SIG_IGN
	sys_sigaction SIGTTOU,signal_struc,NULL
	mov 	dword [edi],SIG_IGN
	sys_sigaction SIGTTIN,EMPTY,EMPTY
	mov 	dword [edi],break_hndl			
; C7870000000014900408       mov dword [edi+0x0], 0x8049014
; WHY ^^^^^^^^		NASM version 0.98
; I don't understand ... could you tell me ? (RM)
	sys_sigaction SIGINT,EMPTY,EMPTY
	mov	dword [edi],ctrl_z
	sys_sigaction SIGTSTP,EMPTY,EMPTY
	sys_getpid
	mov	[cur_pid],eax
	sys_setpgid eax,0
	mov	edx,cur_pid
	sys_ioctl STDERR,TIOCSPGRP
%else
	sys_signal SIGINT,break_hndl
	sys_signal SIGTSTP,ctrl_z
%endif
	;------------------------------
	;get UID and select prompt type
	;------------------------------
select_prompt:
	sys_getuid
	mov	ebx,text.prompt_user
	test	eax,eax
	jnz	.not_root
	mov	ebx,text.prompt_root
.not_root:
	mov	[cmdline.prompt],ebx
	;----------------------------
	;set values for cmdline_parse
	;----------------------------
conspired_to_run:
	xor	eax,eax
	mov	[cmdline.flags],eax
	mov	[cmdline.argument_count],eax
	mov	[cmdline.buffer2_offset],eax
	mov	[cmdline.buffer1_offset],eax
	mov	[cmdline.arguments_offset],eax
	;---------------------------------
	;output shell prompt and read line
	;---------------------------------
get_cmdline:		
	mov	eax,[cmdline.prompt]
	jmps	.normal_prompt
.incomplete_prompt:
	mov	eax,text.prompt_incomplete
.normal_prompt:
	WRITE_STRING

	call	cmdline_get
	test	eax,eax
	jz	get_cmdline
%ifdef HISTORY		
	xchg 	eax,edx			;save the length of str in buff
	mov 	ecx,[history_start]	;load the counter located some
	or 	ecx,ecx			;where in stack
	jnz	.next_entry
	push 	byte 0			;count of lines in history
	mov 	[history_start],esp	;write the pos of this counter
	mov 	ecx,esp			;also from this pos will be
.next_entry:				;saving ptrs to strings
	inc 	dword [ecx]       
	mov 	eax,[ecx]
	mov 	[history_cur],eax	;update last history
	sys_brk 0			;get top of heap
	push 	eax			;store cur addres
	mov 	edi,eax
	add 	eax,edx
	;dec  eax ;dont copy 00, change 0A->00
	sys_brk eax			;extend heap
	mov 	esi,cmdline.buffer1
	mov 	ecx,edx
	rep	movsb			;copy str to free mem
	dec 	edi
	mov 	byte [edi],0		;delete 0A
	xchg 	eax,edx
%endif
	;-------------
	;parse cmdline
	;-------------
	call	cmdline_parse
	test	eax, eax
	jz	near get_cmdline
	js	near get_cmdline.incomplete_prompt	;this is somewhat broken
	;---------------
	;execute cmdline
	;---------------
;	call	check_casualties ;our lovely child(ern) may be 0xDEAD
	call	cmdline_execute
	;----------------
	;get next cmdline
	;----------------
	jmp	get_cmdline

;****************************************************************************
;****************************************************************************
;*
;* PART 3: sub routines
;*
;****************************************************************************
;****************************************************************************
;SHELL="
;enviroment setup

environ_initialize:
	sys_brk 0
	mov 	[cmdline.environment],eax
	mov 	dword [environ_count],1
	mov 	edx,eax
	xchg 	ebx,eax
	mov 	esi,edi
	call	string_length
	add 	ebx,ecx
	add 	ebx,byte 08 ;better more
	sys_brk EMPTY
	xchg 	edx,edi
	mov 	dword [edi],'SHEL'
	mov 	dword [edi+4],'L=" '
	add 	edi,byte 7
.next_char:
	lodsb 
	stosb
	or 	al,al
	jnz .next_char
	dec 	edi
	mov 	al,'"'
	stosb 
	xor 	al,al
	stosb 
	ret

environ_inherit:
	pop	ebx		;EIP
	or 	ebp,ebp
	jz	.ok_next_is_env
.pop_next:			;get rid of rest args
	pop 	eax
	or	eax,eax
	jnz   	.pop_next
	push 	eax
.ok_next_is_env:	
	pop	eax
	or	eax,eax
	jz	.env_done
	mov 	edx,[environ_count]
	mov 	[cmdline.environment+edx*4],eax
	inc 	edx
	cmp 	edx,CMDLINE_MAX_ENVIRONMENT
	mov 	[environ_count],edx
	jnz	.ok_next_is_env
	;int 3 ;too much environ...
.env_done:		
	jmp	ebx

;****************************************************************************
;****************************************************************************
;*
;* PART 3.1: string sub routines
;*
;****************************************************************************
;****************************************************************************

;****************************************************************************
;* string_length ************************************************************
;****************************************************************************
;* edi=>  pointer to string
;* <=ecx  string length (including trailing \0)
;* <=edi  pointer to string + string length
;****************************************************************************
string_length:
	push	eax
	xor	ecx,ecx
	xor	eax,eax
	dec	ecx
	cld
	repne	scasb
	neg	ecx
	pop	eax
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
string_compare:
	push	edx
	push	edi
	call	string_length
	mov	edx,ecx
	mov	edi,esi
	call	string_length
	cmp	ecx,edx
	jae	.length_ok
	mov	ecx,edx
.length_ok:
	pop	edi
	cld
	repe	cmpsb
	pop	edx
	ret

;****************************************************************************
;****************************************************************************
;*
;* PART 3.2: sub routines terminal handling
;*
;****************************************************************************
;****************************************************************************

;****************************************************************************
;* tty_initialize ***********************************************************
;****************************************************************************
tty_initialize:
	cmp	dword [script_fd],STDIN
	jne	.bye
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;TODO: set STDIN options (blocking, echo, icanon etc ...) only on linux ?
;      set signal handlers
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	mov	dword [backspace],0x20082008
%ifdef TTYINIT
	mov	edx,termattrs
	sys_ioctl STDIN,TCGETS
	mov	eax,[termattrs.c_lflag]
	push 	eax
	and	eax,~(ICANON|ECHO)
	mov	[termattrs.c_lflag],eax
	sys_ioctl STDIN, TCSETS
	pop	dword [termattrs.c_lflag]
%else
	sys_fcntl STDIN,F_GETFL
	and	eax,~(O_NONBLOCK)	;don't work
	sys_fcntl STDIN,F_SETFL,eax
%endif
.bye:
	ret

;****************************************************************************
;* tty_restore **************************************************************
;****************************************************************************
tty_restore:
%ifdef TTYINIT
	cmp	dword [script_fd],STDIN
	jne	.bye
 	sys_ioctl STDIN,TCSETS,termattrs
%endif	    
.bye:
	ret

;****************************************************************************
;****************************************************************************
;*
;* PART 3.3: sub routines for parsing command line
;*
;****************************************************************************
;****************************************************************************

;****************************************************************************
;* cmdline_get **************************************************************
;****************************************************************************
;* <=eax  characters read (including trailing \n)
;****************************************************************************
; This code is xterm & linux console compatible. It means VT100 and DEC 
; maybe.

;>AL out
%ifdef TTYINIT
get_char:
	sys_read [script_fd],getchar,1
	test	eax,eax
	js	near cmd_exit
	jz	near cmd_exit
	mov 	al,[ecx]
	ret
%endif

;IN EDI buffer 
;OUT filled with null term str with\n
cmdline_get:
%ifdef TTYINIT
	mov 	edi,cmdline.buffer1 
	mov 	word [edi],0
.do_nothing_loop:
	call 	get_char
	cmp 	al,TABULATOR
	jz	near .tab_pressed 
	cmp 	al,ESC
	jz	near .esc_seq_start
	cmp     al,BACKSPACE
	jz	near .back_space
	cmp     al,DEL
	jz	near .back_space
        cmp     al,CTRL_D
	jz	near cmd_exit
        cmp     al,CTRL_L
        jz	near .clear
	WRITE_CHARS getchar,1
	mov 	al,[getchar]
	cmp 	al,ENTER
	jz 	.enter
	xor 	ah,ah		;write in on console
	cmp 	byte [edi],ah
	jz 	.ok_have_end	;test if insert or append
	push	edi		;insert
.loop:
	xchg 	al,[edi]
	inc 	edi
	or 	al,al
	jnz	.loop
	mov 	byte [edi],ah
	pop 	edi
	inc 	edi
	WRITE_CHARS insert_char,4
	WRITE_CHARS edi,1
	WRITE_CHARS backspace,1
.big_fat_jump:
	jmp	.do_nothing_loop
.ok_have_end:
 	mov 	[edi],ax
	inc 	edi	
	jmps	.big_fat_jump
.enter: 
	cmp 	byte [edi],0	;go at the end of str and put \n
	jz	.append
	inc 	edi
	jmps	.enter
.append:
	mov	word [edi],0x000a
	xchg 	edi,eax
	sub 	eax,cmdline.buffer1-1
	mov 	ebx,eax
	dec 	ebx
	jnz	.ok_end
	xor 	eax,eax		;if EAX==1 =>eax=0 
.ok_end:
	ret			;bye bye ...

.clear:
	call	cmd_clear
        jmp	get_cmdline

.back_space:	
	cmp 	edi,cmdline.buffer1    ;check outer limits
	jz	near .beep
	cmp 	byte [edi],0	       
	jz	.at_the_end		;simple case we if are at the end
	push 	edi     
.loop1:	
	mov 	al,[edi]		;no ...
	inc 	edi
	mov 	[edi-2],al
	or 	al,al
	jnz	.loop1
	pop 	edi
	WRITE_CHARS delete_one_char,5
	dec 	edi
	mov 	al,[edi]
	mov 	byte [cur_move_tmp+1],al
	WRITE_CHARS cur_move_tmp+1,2
.big_fat_jump2:
	jmp	.do_nothing_loop		
.at_the_end:
	dec 	edi
	mov    	byte [edi],0
	mov 	byte [cur_move_tmp+1],' '
	WRITE_CHARS cur_move_tmp,3
	jmps	.big_fat_jump2	
.esc_seq_start:
	sys_read [script_fd],getchar+1,2	;have control code in buffer 
	cmp 	word [ecx],'[D'
	jz	.cursor_left	
	cmp 	word [ecx],'[C'
%ifndef HISTORY
	jnz	.big_fat_jump2		
%else
	jz	.cursor_right
	mov 	edx,history_cur
	cmp 	word [ecx],'[A'
	jz	.cursor_up	
	cmp 	word [ecx],'[B'
	jz	.cursor_down
	jmps	.big_fat_jump2		
.cursor_down:
	inc 	dword [edx]		;choose which line of hist to display
	jmps	.do_history
.cursor_up:	
	cmp 	dword [edx],0
	jz	.beep
	dec 	dword [edx]	
	jmps	.do_history
.cursor_right:
%endif
	cmp 	byte [edi],0		;check outer limits
	jz	.beep
	WRITE_CHARS edi,1		;reprint the charter
	inc 	edi
	jmp	.big_fat_jump2
.beep:	
	WRITE_CHARS beep,1		;beeeeeeeeeep
	jmps	.big_fat_jump3
.cursor_left:
	cmp 	edi,cmdline.buffer1	;check outer limits
	jz	.beep
	dec 	edi
	WRITE_CHARS backspace,1		;cursor one left
.big_fat_jump3:			
	jmp	.do_nothing_loop

%ifdef HISTORY
.do_history:
	mov 	ebx,[history_start]
	or 	ebx,ebx		;first use and want history ??
	jz	.beep
	mov 	ecx,[edx]
	cmp 	ecx,[ebx]
	jb	.bound_ok
	dec 	dword [edx]	;stupid, try to thing about better solution
	jmps	.beep
.bound_ok:
	inc 	ecx		;count the adress of pointer to cmdline
	shl 	ecx,2
	sub 	ebx,ecx
	mov 	edi,[ebx]	;offset of command line, reading fm stack
	mov 	esi,edi 
	call	string_length
	mov 	edi,cmdline.buffer1
	dec 	ecx
	mov 	ebp,ecx
	dec 	ebp		;save length to ebp
	rep	movsb
	dec	edi
	WRITE_CHARS erase_line,5
	WRITE_STRING [cmdline.prompt]
	WRITE_CHARS cmdline.buffer1, ebp
	jmp	.big_fat_jump3
%endif
.last_slash:
	or 	edx,edx
	jnz 	.got_last
	mov 	edx,edi
	jmps	.got_last
.tab_pressed:			;we want hint which file to write
	push 	edi
	xchg 	esi,edi
	mov 	edi,cmdline.buffer1
	mov 	eax,edi
		
	mov 	byte [file_name],0
	mov 	byte [first_time],0
	mov 	[write_after_slash],edi ;here we start ...
	call	string_length
	mov 	ebx,cur_dir
	xor 	edx,edx
	;Please note: following lines could be written more clearly
	;this seems as more reg magic move around and it is so.
	;If you have a better solution to cover all cases
	;here's your chance!
.find_space:
	dec 	edi 		;now we are at the end of str
	cmp 	edi,eax		;we will find from end of str till
	jz	.not_found	;start the first space
	cmp 	byte [edi],'/'  ;and first slash
	jz	.last_slash
.got_last:
	cmp 	byte [edi],' '
	jnz	.find_space
	inc 	edi
	mov 	ebx,edi
	;edi points to a start of the possible directory
	;edx  -----------last slash
	or 	edx,edx
	jnz	.have_slash    
.not_found:
	cmp	byte [eax],'/'   ;is the first slash ?
	jnz	.really_not_found
			
	or 	edx,edx
	jnz	.have_more_slash
	mov 	edx,eax
.have_more_slash:
	mov 	ebx,eax
	jmps	.have_slash
.really_not_found:
	cmp 	byte [eax],'.'
	jnz	.last_chance_failed
	or 	edx,edx
	jnz	.have_slash
.last_chance_failed:
	mov 	ebx,cur_dir
	mov 	edx,ebx
	inc 	edx
	mov 	[write_after_slash],edi
	jmps	.lets_rock 
.have_slash:
	inc 	edx
	mov 	[write_after_slash],edx
	dec 	edx
.lets_rock:
;	int 3
;	nop

%ifdef TTYINIT			;linux dep part
        sys_stat EMPTY,stat_buf 
	test    eax,eax 
	js      .is_not_complete_file
	movzx   eax,word [stat_buf.st_mode] 
	and     eax,40000q 
	jnz     .is_not_complete_file
	WRITE_CHARS beep,1		;beeeeeeeeeep	
	pop 	edi
	jmp	.do_nothing_loop
%endif

.is_not_complete_file:
	xor 	al,al
	xchg 	byte [edx],al
	xchg 	ebp,eax
			
.try_again:
	;have_a_look if posible to open another directory
	;in write_after_slash is right piece of filename
	cmp 	ebx,edx ;we have a cd /bi 
	jnz	.havent
	mov 	ebx,cur_dir
	inc 	ebx
.havent:		
	sys_open EMPTY,O_DIRECTORY|O_RDONLY
	or 	eax,eax
	jns	.ok
	mov 	ebx,cur_dir 
	jmps	.try_again
.ok:
	xchg 	ebp,eax
	xchg 	byte [edx],al
	xchg 	esi,edi
.find_next:
	sys_getdents ebp,file_buf,FILE_BUF_SIZE
	or 	eax,eax
	jz	near .finish_lookup	;no entries left
	add 	eax,ecx 		;set the buffer limit {offset] 	    
	xor 	edx,edx    
	push	byte 0			;mark last entry
.compare_next:
	add 	ecx,edx
	mov 	edx,ecx
	mov 	esi,[write_after_slash]
	cmp 	eax,ecx
	;jb .print_what_find
	;jz .print_what_find
	jna	.print_what_found
	add	edx,byte dirent.d_name
	push 	edx		;put candidate on the list
	push 	ecx
	xchg 	edx,edi
	call	string_compare	;cmp fm last slash! look if he have parcial match
	dec 	esi
	pop 	ecx
	cmp 	edx,esi     
	xchg 	edx,edi
	jz	.same		;yes we have
	pop	edx		;throw this filename away 
;	jmps .not_same
.same:
;	int 3
;.not_same:
	movzx 	edx,word [ecx+8] ;get the size of this entry
	jmps	.compare_next
	
.print_what_found:	

	pop 	esi		;look at the last and second last
	or 	esi,esi		;if 1st 0 -nothing found
	jz 	.find_next	;if 2nd 0 only one found in buffer
	
	push 	esi
	cmp dword [esp+4],0
	jnz	near .have_more
	
	
	;here we can have only one but dont know about the rest
	;not yet processed
	;copy this filename to some_buffer
	cmp 	byte [file_name],0
	jnz	near .have_more
	xchg 	ebx,edi
	mov 	edi,file_name
.copy_loop3:
	lodsb
	stosb
	or 	al,al
	jnz	.copy_loop3 
	xchg 	ebx,edi
	pop eax ;throw 0 away
	pop eax
	jmp	.find_next

.we_have_really_one:
.we_have_really_one2:		;we have one suitable candidate in buffer ESI

	WRITE_CHARS erase_line,5
	mov 	edi,[write_after_slash]
.next_char:			;append the string back to commandline
	lodsb
	stosb
	or 	al,al
	jnz	.next_char

%ifdef TTYINIT			;linux dep part
	mov 	esi,edi
;	int 3
	std
.find_space2:
	lodsb
	cmp	esi,cmdline.buffer1
	jz	.try_it
	cmp	al,' '
	jnz	.find_space2
	inc	esi
	inc	esi
.try_it:		
	cld
	sys_stat esi,stat_buf
	test    eax,eax
	js  	.is_not_dir	
	movzx   eax,word [stat_buf.st_mode]
	mov     ebx,40000q
	and     eax,ebx   
	cmp     eax,ebx
	jnz	.is_not_dir
	dec 	edi			
	mov 	word [edi],0x002f
	inc 	edi
	inc 	edi
%endif
.is_not_dir:      
	pop 	eax
	dec 	edi
	push 	edi
	jmps	.skip
.we_have_not_printed_last:
	push	byte 0
	push	esi
	jmps	.have_more
    
.finish_lookup:		;restore promt
	mov	esi,file_name
	cmp 	byte [esi],0
	jz 	.finish_loopup_stage2

	cmp 	byte [first_time],0
	jz	near .we_have_really_one
.finish_loopup_stage2:
	cmp 	byte [esi],0
	jnz 	.we_have_not_printed_last	
	
	mov 	esi,file_equal
	cmp 	byte [esi],0
	jnz	near .we_have_really_one  ;which is loaded in file_name
;	int 3
	
.skip:			;we have something same for all files...
	WRITE_CHARS erase_line,5
	WRITE_STRING [cmdline.prompt]
	WRITE_STRING cmdline.buffer1
	sys_close ebp
	pop 	edi
	jmp	.do_nothing_loop
;.have_more2:
;	mov byte [file_name],0x1  ;This servers to situation when more possibolities
				  ;were printed but in another batch (getdents) is only
				  ;one file left. 
.find_next_and_delete_file_name:
	mov byte [file_name],0
	jmp .find_next

.have_more:
    	cmp 	byte [first_time],0
	jnz	.dont_need_cr
;	int 3
;	mov 	ecx,esi
	mov 	eax,file_name

	cmp 	byte [eax],0
	jz	.ok_file_name_not_used	
;	int 3
	push    eax  ;save file_name on the stack and print it
.ok_file_name_not_used:
	;** ;write equal filename... to this will will compare
	mov esi,[esp]
	xchg 	ebx,edi
	mov 	ecx,esi
	mov 	edi,file_equal

.copy_next:
	lodsb 
	stosb
	or 	al,al
	jnz	.copy_next
	xchg 	ecx,esi
	xchg 	ebx,edi
			
	;quick & dirty hack to begin on new line
	dec 	esi
	mov [esp],esi
	mov 	byte [esi],__n
	
.dont_need_cr:
	inc 	byte [first_time]
;	push 	edx
;	push 	esi
.pop_next:			;we print a list of candidates here
	pop 	edx
	or 	edx,edx
	jz   .find_next_and_delete_file_name
			
	mov 	esi,file_equal	;**ESI can be used
	mov 	ebx,edx
	cmp 	byte [ebx],__n
	jz	.compare_next2
	dec 	ebx
.compare_next2:
	inc 	ebx
	lodsb
	cmp 	al,[ebx]
	jz	.compare_next2
	dec 	esi
	mov 	byte [esi],0 ;truncate the file name to the same begining

	xchg 	edi,esi
	
	mov 	edi,edx
	call	string_length
	
	dec 	edi
	dec 	ecx
	mov 	byte [edi],__n	;append a newline
	xchg 	edi,esi
	WRITE_CHARS edx
	jmps	.pop_next 
%else
 	sys_read [script_fd],cmdline.buffer1,(CMDLINE_BUFFER1_SIZE - 1)
	test	eax,eax
	jns	.end
	xor	eax,eax
.end:
	mov	byte [cmdline.buffer1 + eax],0
	ret
%endif	;TTYINIT

;****************************************************************************
;* cmdline_parse ************************************************************
;****************************************************************************
;* eax=>  number of characters in cmdline
;* <=eax  number of parameters (0 = none, 0ffffffffh = line incomplete)
;****************************************************************************
;!!!!!!!!!!!!!!!!!!!!!!
;TODO: ' \  2>  ` $
;!!!!!!!!!!!!!!!!!!!!!!

cmdline_parse_flags:
.seperator:		equ	001h
.quota1:		equ	002h
.quota2:		equ	004h
.redir_stdin:		equ	008h
.redir_stdout:		equ	010h
.redir_append:          equ     020h			

cmdline_parse:
cmdline_parse_restart:
	mov	esi,cmdline.buffer1
	add	esi,[cmdline.buffer1_offset]	;we need this when piping

	mov	ebx,[cmdline.flags]		;this is used when incomplete cmd line
	mov	ecx,eax
	mov	edx,[cmdline.argument_count]
	mov	edi,cmdline.buffer2
	mov	ebp,[cmdline.arguments_offset]
	add	edi,[cmdline.buffer2_offset]

.next_character:
	lodsb
	test	al,al
	jz	near .end
	test	ebx,cmdline_parse_flags.seperator ;are we in argument or between?
	jnz	.check_seperator
        cmp	al,'#'
	je	near .end
        cmp	al,'$'
	je  	near .get_env			
	cmp	al,__t			;between
	je	near .skip_character
	cmp	al,__n
	je	near .end
	cmp	al,' '
	je	near .skip_character
	push    dword .skip_character	;used by redir where to return
	cmp	al,'>'
	je	near .redir_stdout
	cmp	al,'<'
	je	near .redir_stdin
	pop     dword [esp-4]
	cmp	al,'?'
	je	near .wild_ext
	cmp	al,'*'
	je	near .wild_ext
	cmp	al,'|'
	jne	.normal
	cmp	byte [esi],'|'
	je	.normal
	cmp	byte [esi-2],'|'	;dangerous!!!
	jne	near .pipe
.normal:
	mov	[cmdline.arguments + 4 * ebp],edi	;time to create new arg
	inc	ebp					;we have more args from now
	inc	edx
	or	ebx,cmdline_parse_flags.seperator	;set in separator flag
.check_seperator:
	cmp	al,'"'			;handle correctly the " between " " nothing to parse
	jne	.not_quota1
	xor	ebx,cmdline_parse_flags.quota1
	jmps	.skip_character
.not_quota1:
	test	ebx,cmdline_parse_flags.quota1 
	jnz	.copy_character
	cmp	al,__t			;are we at the end of arg?
	je	.seperate
	cmp	al,__n
	je	.end

	push    dword .seperate
	cmp	al,'>'
	je	.redir_stdout
	cmp	al,'<'
	je	.redir_stdin
	pop     dword [esp-4]
	cmp	al,'?'
	je	near .wild_ext
	cmp	al,'*'
	je	near .wild_ext
	cmp	al,'|'
	jne	.normal2
	cmp	byte [esi],'|'
	je	.normal2
	cmp	byte [esi-2],'|'	;dangerous!!!
	jne	near .pipe
.normal2:
	cmp	al,' '
	jne	.copy_character
.seperate:
	xor	eax,eax
	and	ebx,~cmdline_parse_flags.seperator	;arg end here lets see 
.copy_character:
	stosb						;if we have more...
.skip_character:
	dec	ecx
	jnz	near .next_character
.end:
	test	ebx,cmdline_parse_flags.quota1
	jnz	near .incomplete			;save all int. val and 
;TODO: both redirections at once
;signal uncomplete cmdline
	xor	eax,eax
	stosb
	test	ebx,cmdline_parse_flags.redir_stdout	;get ready for redirs
	jnz	.redir_stdout_doit
	test	ebx,cmdline_parse_flags.redir_stdin
	jnz	.redir_stdin_doit
	jmps	.time_to_end
.redir_stdin:
	or	ebx,cmdline_parse_flags.redir_stdin 
;	jmps	.skip_character
	ret
.redir_stdout:		
	mov 	eax,ebx
	or	ebx,cmdline_parse_flags.redir_stdout
	cmp 	eax,ebx		;was redir already set ?? (second >) if so set append 
	jnz 	.return_back
.set_append:
	or 	ebx,cmdline_parse_flags.redir_append
;	jmps	.skip_character
.return_back:
	ret

.redir_stdin_doit:
	dec	ebp
	dec	edx
	sys_open [cmdline.arguments + 4 * ebp],O_RDONLY|O_LARGEFILE
	mov	[cmdline.redir_stdin],eax
	jmps	.time_to_end
.redir_stdout_doit:
	dec	ebp
	dec	edx
	mov	ecx,O_WRONLY|O_CREAT|O_LARGEFILE
	test	ebx,cmdline_parse_flags.redir_append
	jz	.trunc
	or 	ecx,O_APPEND
	jmps	.ok_open		
.trunc:
	or 	ecx,O_TRUNC
.ok_open:
	sys_open [cmdline.arguments + 4 * ebp],EMPTY,S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH
	mov	[cmdline.redir_stdout],eax
	jmps	.time_to_end

.time_to_end:		;when cmdline is whole done reset int struc to defaults
	xor	eax,eax
	mov	[cmdline.arguments + 4 * ebp],eax
	mov	[cmdline.flags],eax
	mov	[cmdline.argument_count],eax
	mov	[cmdline.buffer2_offset],eax
	mov	[cmdline.buffer1_offset],eax
	mov	[cmdline.arguments_offset],eax
	mov	eax,edx
	ret
			
.incomplete:
	xor	eax,eax	;time to save all internals
	mov	[cmdline.buffer1_offset],eax
	dec	eax
	mov	[cmdline.flags],ebx
	sub	edi,cmdline.buffer2
	mov	[cmdline.argument_count],edx
	mov	[cmdline.buffer2_offset],edi
	mov	[cmdline.arguments_offset],ebp
	ret
.get_env:		
        push	edi
        push	ecx
        push	edx
        push	esi
        mov	edi,esi
        mov	esi,cmdline.environment
        mov	ecx,[edi]
        mov	edx,ecx
.env_loop:
        lodsd
        or	eax,eax
        jz	.Lnope
        cmp	byte [eax],dl
        jnz	.env_loop
        push	esi
        push	edi
        mov	esi,eax
        repz	cmpsb
;	cmp	byte [esi-1], '='
;	jz	.Lout_first
	cmp	byte [edi-1],' '
    	jna	.Lout_first	
			
;	pop esi	;bug
	pop	edi
	pop	esi
        jmps	.env_loop
.Lout_first:
        pop	edx
	pop	edx
.Lout:
        mov	[cmdline.arguments + ebp*4],esi
        inc	ebp
        mov	esi,edi
        pop	edx
        pop	edx
        inc	edx
        jmp	.Lnext
.Lnope:
        pop	esi
.Lnope_loop:
        lodsb
        or	al, al
        jz	.Lyet_another_label
        cmp	al,' '
        jg	.Lnope_loop	;ja ? (RM)
.Lyet_another_label:
        pop	edx
.Lnext:
        pop	ecx
        pop	edi
        jmp	.next_character
.pipe:
	push 	ecx	;how many chars left ??? Decrease by one ?
	push    edx	;size
	xor	eax,eax
	stosb
	call    .time_to_end 	
;	mov	[cmdline.arguments + 4 * ebp],eax
;	mov	[cmdline.flags],eax
;	mov	[cmdline.argument_count],eax
;	mov	[cmdline.buffer2_offset],eax
;	mov	[cmdline.arguments_offset],eax
;	mov	eax,edx
;	push	eax
	sub	esi,cmdline.buffer1
	mov	[cmdline.buffer1_offset],esi
	sys_pipe pipe_pair		;create pipe		
        mov 	eax,[pipe_pair.write]
        mov	[cmdline.redir_stdout],eax
	pop	eax
	mov 	byte [pbackground],1
	call	cmdline_execute		;both redir_'s are set to 0 there
        mov 	eax,[pipe_pair.read]
        mov	[cmdline.redir_stdin],eax
	pop     eax			;chars left
	jmp     cmdline_parse_restart
			
;EAX wild card type
;EBX flags
;ECX chars to end
;EDX ARGC
;ESI buffer ptr to next char
;EDI writing arg into buffer2
;EBP index into args array
.wild_ext:
	mov	byte [file_name],0	;stupid
			
	test	ebx,cmdline_parse_flags.seperator	;are we in argument
	jz	.not_in					;or between ?
	and	ebx,~cmdline_parse_flags.seperator	;arg end here lets see
			
	push 	eax
	push 	ecx
	push	esi
	push 	edi
	std
	mov	esi,edi
	mov	edi,[cmdline.arguments-4 + 4 * ebp]   
.find_next_slash:
	cmp	esi,edi
	jz	.slash_not_found
	lodsb
	cmp 	al,'/'
	jnz	.find_next_slash
	;ESI last byte to copy EDI start
	cld
	mov	ecx,esi
	sub 	ecx,edi
	inc	ecx	
	mov 	esi,edi
	mov	edi,file_name  
	rep	movsb  
	xor	al,al
	stosb 		;we have a dir to explore there
	jmps	.copy_to_eq
.slash_not_found:
	dec	esi
.copy_to_eq:
	cld
	inc 	esi
	mov 	edi,file_equal
	pop	ecx
	push 	ecx
	sub	ecx,esi
	rep	movsb
	mov	[cmdline.arguments + 4 * ebp],edi ;unused pos   
	xor	al,al
	stosb
	pop	edi
	pop	esi
	pop	ecx
	pop	eax
	dec 	edx   	;remove this arg from array
	dec	ebp
	mov	edi,[cmdline.arguments + 4 * ebp]   
	pusha
	push 	ebp
	mov	edi,[cmdline.arguments+4 + 4 * ebp]   
	mov 	ebp,esp			
	mov 	ebx,file_name
	cmp	byte [ebx],0
	jnz	.dir_open
	mov	ebx,cur_dir
	jmps	.dir_open
.not_in:		
;    	mov byte [file_equal],0
	pusha
	nop		;I think there are buggy CPUs...
	push 	ebp
	mov 	ebp,esp			
	mov 	edi,file_equal
	;we begin with the wild card => use cur dir
	mov 	ebx,cur_dir
	;ESI next char 	
	;EDI next pos in file_equal
.dir_open:
	stosb		;save the wild card
	push 	eax	;save the wild card (first)
.copy_rest_wild:
	lodsb
	cmp 	al,__n
	jz 	.copy_done
	cmp 	al,__t
	jz 	.copy_done
	cmp 	al,' '
	jz 	.copy_done
	stosb
	dec 	dword [ebp+(7*4)]	;how many chars to end update (ECX)
	jmps	.copy_rest_wild
.copy_done:		
	dec	esi
	mov 	[ebp+(2*4)],esi		;last esi for parser
	mov 	[ebp+(8*4)],eax		;write last separator for parser
	xor 	al,al			;(EAX)
	stosb
	;now we have filled filename_equal with wildcard mask and directory
	;in which will be searched is ready in ebx
	;whuff ...
			
	sys_open EMPTY,O_DIRECTORY|O_RDONLY	;NON_BLOCK  too ?
	mov	ebx,eax
	or 	eax,eax
	jns	.ok
	pop 	eax
	pop	ebp
	popa				;TODO copy everything back
	jmp	.next_character
.ok:
	sys_getdents EMPTY,file_buf,FILE_BUF_SIZE
	or	eax,eax
	jz	.finish_lookup		;no entries left
	add 	eax,ecx 		;set the buffer limit {offset] 	    
	xor 	edx,edx    
.compare_next:
	add 	ecx,edx
	mov 	edx,ecx
	mov 	esi,file_equal
	cmp 	eax,ecx
	jna	.ok
	add	edx,byte dirent.d_name
	push 	edx			;put candidate on the list
	push 	ecx
	xchg 	edx,edi
	call	string_compare		;cmp fm last slash! look if he have parcial match
	dec 	edi
	dec	esi 
	pop 	ecx
	pop 	edx			;filename
			
;	pop	eax
;	push	eax
	push 	eax
	mov	eax,[esp+4]
			
	cmp	[esi],al
	jnz	.next_entry		;differs before wild
	call 	.match_rest
;	or	eax,eax
	jnz	.next_entry		;ZF=0 bad ZF=1 ok
%ifdef	EXCLUDE_DOTS
	cmp	byte [edx],'.'
	jnz	.not_dot
	cmp	byte [edx+1],0
	jz	.next_entry
	cmp	word [edx+1],2eh
	jz	.next_entry
.not_dot:
%endif
	;ok put candidate as arg
;	dword [cmdline.arguments + 4 * ebp],edi
	mov 	edi,[ebp+(1*4)]		;OLD EDI
	inc 	dword [ebp+(6*4)]	;(EDX)
	mov 	esi,[ebp+(4*3)]		;(EBP)
	mov	[cmdline.arguments + 4 * esi],edi
	inc	esi
	mov 	[ebp+(4*3)],esi		;(EBP++)
	mov	esi,edx
.copy_loop:
	lodsb
	stosb
	or 	al,al
	jnz	.copy_loop
	;go to next entry
	mov	[ebp+(1*4)],edi		;OLD EDI
.next_entry:
	movzx	edx,word [ecx+8]	;get the size of this entry
	pop	eax
	jmps	.compare_next
.finish_lookup:		
	pop	eax			;throw away wild
	sys_close
	pop	ebp
	popa
	nop
	jmp	.next_character
			
;*****************************************************
;Match rest 
;Input: ESI - somewhere in mask string
;       EDI - somewhere in offered filename
;Output ZF==1 "identical"
;       ZF==0 ee
;****************************************************

.match_rest:		
	push	eax  
	push 	edx
	inc	esi 
.cmp_next_char:	
	cmp	al,'*'
	jnz	.not_ast
	call	.find_part_match
	jz	.cmp_next
	jmps	.done_cmp
.not_ast:
	cmp	al,'?'
	jnz	.not_q
	inc	edi
	lodsb
	jmps	.cmp_next_char
.not_q:
	mov	byte ah,[edi]
	or	eax,eax
	jz 	.done_cmp
	cmp	ah,al
	jz	.cmp_next
.done_cmp:
	pop 	edx
	pop	eax
	ret
.cmp_next:
	lodsb
	inc	edi
	jmps	.cmp_next_char
.find_part_match:
	lodsb	;next symbol in mask
	or	al,al
	jz	.find_part_match_done_total
	;ok now we have to find AL somewhere in EDI
	cmp	al,'*'
	jz	.find_part_match
	;TODO check also for '?' ???
.find_part_next:
	mov	ah,[edi]
	cmp 	al,ah
	jnz	.find_part_match_next
	ret
.find_part_match_next:
	or	ah,ah
	jz	.find_part_end
	inc	edi
	jmps	.find_part_next
.find_part_end:
	inc	ah		;ZF = 0
.find_part_match_done_total:
	pop	edx		;EIP
	pop	edx
	pop	eax
	ret

;****************************************************************************
;* serve_casualties  ********************************************************
;****************************************************************************
;It will only make cleanup in our job control handling
serve_casualties:
	cmp 	byte [rtn],0x7F ;stopped ?
	jnz 	.terminated	
	xor	ebx,ebx
	call 	find_pid
	or	edi,edi
	jnz	.ok_got_it
	int 3
.ok_got_it:
	mov	[edi],eax
	sub	edi,pid_array
	mov 	eax,edi
	shr 	eax,2
	mov	ah,010
	add 	al,'0'
	mov	[b_id],ax
	WRITE_STRING text.stopped
	WRITE_CHARS b_id,2
.terminated:
	mov	ebx,eax
	call 	find_pid
	or	edi,edi
	jz	.ret
	xor	eax,eax
	mov 	[edi],eax
.ret:
	ret


;****************************************************************************
;* cmdline_execute **********************************************************
;****************************************************************************
cmdline_execute:
execute_builtin:
	mov	ebx, builtin_cmds.table
.next:
	mov	edi,[cmdline.arguments]
	mov	esi,[ebx+builtin_cmds_s.name]
	test	esi,esi
	jz	.end
	call	string_compare
	test	ecx,ecx
	jz	.do_exec
	add	ebx,builtin_cmds_s_size
	jmp	.next
.do_exec:
	mov	eax, [ebx+builtin_cmds_s.flags]
	test	eax, eax
	jz	.end
	jmp	[ebx+builtin_cmds_s.cmd]
.end:
	;----    |
	;fork    |
	;----   /|\
	;      | | |
	call  tty_restore
	sys_fork
	test	eax,eax
	jnz	near .wait
%ifdef SPGRP
	cmp	byte [interactive],0
	jz	.cont
	sys_getpid
	mov 	edx,cur_pid
	mov 	[edx],eax
	sys_setpgid eax,0
	sys_ioctl STDERR,TIOCSPGRP
	mov	dword [signal_struc.handler], SIG_DFL
	sys_sigaction SIGINT,signal_struc,NULL
	sys_sigaction SIGTSTP
.cont:
%endif
	;--------------------------------------------------
	;try to execute directly if the name contains a '/'
	;--------------------------------------------------
.execute_extern:	
	xor 	eax,eax
	cmp	eax,[cmdline.redir_stdout]
	jz	.no_stdout_redir
	sys_dup2 [cmdline.redir_stdout],STDOUT
	sys_close
.no_stdout_redir:
	xor	eax,eax
	cmp	eax,[cmdline.redir_stdin]
	jz	.no_stdin_redir
	sys_dup2 [cmdline.redir_stdin],STDIN
	sys_close
.no_stdin_redir:
	mov	edi,[cmdline.arguments]
	call	string_length
	mov	edi,[cmdline.arguments]
	mov	 al,'/'
	repne	scasb
	test	ecx,ecx
	jz	.scan_paths
			
	sys_execve [cmdline.arguments],cmdline.arguments,cmdline.environment
	jmp	.error
	;-------------------------------------
	;walk through paths and try to execute
	;-------------------------------------
	;TODO: grab paths from ENV ?
.scan_paths:
	_mov	ebp,5
	mov	esi,builtin_cmds.paths
.next_path:
	mov	edi,cmdline.program_path
.copy_loop1:
	lodsb
	stosb
	test	al,al
	jnz	.copy_loop1
	dec	edi
	mov	al,'/'
	push	esi
	stosb
	mov	esi,[cmdline.arguments]
.copy_loop2:
	lodsb
	stosb
	test	al,al
	jnz	.copy_loop2
	pop	esi
	sys_execve cmdline.program_path,cmdline.arguments,cmdline.environment
	dec	ebp
	jnz	.next_path
	;--------------------------------------------------
	;if all tries to execute the command failed, output
	;this message and exit
	;--------------------------------------------------
.error:
	WRITE_ERROR [cmdline.arguments]
	WRITE_ERROR text.cmd_not_found
	sys_exit 1
.wait:			
	mov 	[pid],eax
	mov	ebx,[cmdline.redir_stdin]
	mov	ecx,[cmdline.redir_stdout]
	or	ebx,ebx
	jz	.no_close_in
	sys_close
.no_close_in:
	cmp	ecx,byte 1	;FIX ME: I'm suspecting this is obsolote
	jz	.no_close_out
	or	ecx,ecx  
	jz	.no_close_out
	sys_close ecx
.no_close_out:
wait_here:			;sys_exit 0			
	xor 	eax,eax
	mov	[cmdline.redir_stdin],eax
	mov	[cmdline.redir_stdout],eax	
	mov	eax,[pid]
	cmp	byte [pbackground],0
	jnz 	.nowait
;	xor	ebx,ebx		;Code updated to support
;	dec	ebx		;background processes
;	_mov	ecx,rtn		;JH
;	_mov 	edx,WUNTRACED
;	xor	esi, esi
.wait4another:
	sys_wait4 0xffffffff,rtn,WUNTRACED,NULL
	test	eax,eax
	js	.wait4another
	;RTN struc
	; 0-6 bit signal caught (0x7f is stopped) 
	; 7 core ?
	;8-15 bit EXIT code
	;if 0x7f -> 9-15 signal which caused the stop
	cmp	[pid], eax
	jz	.is_our_child	
	call	serve_casualties
	jmps 	.wait4another
.is_our_child:			
	mov	dword [pid],0
	cmp	byte [interactive],0
	jz	.not_stopped
	cmp 	byte [rtn],0x7F ;stopped ?
	jnz 	.not_stopped
.nowait:
	xor	ebx,ebx
	call 	find_pid
	or	edi,edi
	jnz	.ok_have_place
	int 3
.ok_have_place:
	mov 	[edi],eax
	sub	edi,pid_array
	mov	eax,edi
	shr	eax,2
	add	al,'0'
	mov	ah,010
	mov	[b_id],ax
	cmp 	byte [pbackground],0
	jnz	.not_stopped
	WRITE_STRING text.stopped
	WRITE_CHARS b_id,2
.not_stopped:
	call	tty_restore
%ifdef SPGRP
	sys_getpid
	mov	[cur_pid],eax
	sys_setpgid eax,0
	mov	edx,cur_pid
	sys_ioctl STDERR,TIOCSPGRP
%endif
	mov	byte [pbackground],0 
	jmp	tty_initialize

;***************************************************************************
; find_pid 
; EBX = pid (can use 0 to find empty pos)
; EDI = ptr to it or NULL
;***************************************************************************

find_pid:
	push	eax
	push	esi
	mov 	esi,pid_array
.find_loop:
	cmp	esi,pid_array+(4*MAX_PID)
	jae 	.not_found
	lodsd
	cmp	eax,ebx
	jnz	.find_loop
.got_it:
	mov 	edi,esi	
	sub	edi,byte 4
.end:
	pop	esi
	pop	eax
	ret
.not_found:
	xor	edi,edi
	jmps	.end

;***************************************************************************
; write_string
; eax = string offset (zero terminated)
;***************************************************************************
write_string:
	pusha
	mov	edi,eax
	call	string_length
	dec	ecx
	dec	ecx
	call	write_chars
	popa
	ret

;***************************************************************************
; write_chars
; eax = buffer offset
; ecx = character count
;***************************************************************************
write_chars:
	cmp	byte [interactive],0
	jz	.ret
	sys_write STDOUT,eax,ecx
.ret:
	ret

;***************************************************************************
; write_error
; eax = string offset (zero terminated)
;***************************************************************************
write_error:
	pusha
	mov	edi,eax
	call	string_length
	dec	ecx
	dec	ecx
	sys_write STDERR,eax,ecx
	popa
	ret

;****************************************************************************
;****************************************************************************
;*
;* PART 4: built in commands
;*
;****************************************************************************
;****************************************************************************

;****************************************************************************
;* cmd_export ***************************************************************
;****************************************************************************
;TODO: var redefinition/del
cmd_export:
	mov 	edx,[environ_count]
	mov	edi,[cmdline.arguments + 4]
	or 	edi,edi
	jz	.export_print
	mov 	ebp,edi
	call	string_length
;	dec ecx
	sys_brk 0
	mov 	esi,eax
	add 	eax,ecx
	xchg 	eax,ebx
	sys_brk
	xchg 	ebp,edi
	xchg 	esi,edi
	mov	[cmdline.environment+edx*4],edi
	inc 	edx
	cmp 	edx,CMDLINE_MAX_ENVIRONMENT
	mov 	[environ_count],edx
	jnz	.write_var
	int 3
.write_var:
	lodsb
	stosb
	or 	al,al
	jnz .write_var
.done:
	ret

;taken from env.asm
.export_print:
	xor 	ebp,ebp
	dec 	ebp
.env:
	inc 	ebp
	mov	esi,[cmdline.environment + ebp * 4]
	test	esi,esi
	jz	.done
	mov	edx,esi
	xor	ecx,ecx
	dec	ecx
.slen:
	inc	ecx
	lodsb
	or	al,al
	jnz	.slen
	dec 	esi
	mov	byte [esi],__n
	inc 	ecx
	WRITE_CHARS edx

	mov	byte [esi],0
	jmps	.env

;****************************************************************************
;* cmd_and, cmd_or **********************************************************
;****************************************************************************
cmd_and:		
	cmp	dword [rtn],0
	jne	cmd_and_nogo
;stupid hack to call executor
cmd_and_go:
	mov	esi,cmdline.arguments
	mov	edi,esi
	xor	eax,eax
	cmp 	[esi+4],eax	;someone is trying to kill us...
	jz	cmd_and_nogo
.copyloop:
	add	edi,byte 4 
	mov	eax,[edi]
	mov	[esi],eax
	add	esi,byte 4
	or	eax,eax
	jnz	.copyloop

	call	cmdline_execute	;execute the program
cmd_and_nogo:
	ret

cmd_or:
	cmp	dword [rtn],0
	jne	cmd_and_go
	ret

;****************************************************************************
;* cmd_colon ****************************************************************
;****************************************************************************

cmd_colon:
	xor	eax,eax
	mov	[rtn],eax
	ret

;****************************************************************************
;* cmd_exit *****************************************************************
;****************************************************************************
cmd_exit:
	call	tty_restore
	WRITE_STRING text.logout
	sys_exit [rtn]	;last exit code

;****************************************************************************
;* cmd_cd *******************************************************************
;****************************************************************************
cmd_cd:
	mov	ebx,[cmdline.arguments + 4]
.has_arg:
	sys_chdir
	test	eax,eax
	jns	.end
	WRITE_ERROR text.cd_failed
.end:
	ret

;****************************************************************************
;* cmd_fg  ******************************************************************
;****************************************************************************
cmd_fg:			
	mov	eax,[cmdline.arguments + 4]
	xor	ecx,ecx
	xor	ebx,ebx			
	or 	eax,eax
	jz	.take_first
	mov	cl,[eax]
	sub 	cl,'0'
	cmp 	cl,MAX_PID+1
	jae	near bad_record
.take_first:
	xchg	ebx,[pid_array+ecx*4]
	or	ebx,ebx
	jz	near bad_record
	push	ebx
	call	tty_restore
	pop	ebx
	mov	[pid],ebx
%ifdef SPGRP
;	sys_getpid
;	mov [cur_pid],ebx
	sys_setpgid EMPTY,ebx
	mov	edx,pid
	sys_ioctl STDERR,TIOCSPGRP
%endif
	sys_kill [pid],SIGCONT
	test	eax,eax
	jns	.ok
	call	no_such_pid
	jmps	.terminated			
.ok:
.wait4another:
	sys_wait4 0xffffffff,rtn,WUNTRACED,NULL
	test	eax,eax
	js	.wait4another
	cmp	[pid],eax
	jz	.is_our_child	
	call	serve_casualties
	jmps	.wait4another
.is_our_child:
	call	serve_casualties
.terminated:
%ifdef SPGRP
	sys_getpid
	mov	[cur_pid],eax
	sys_setpgid eax,0
	mov	edx,cur_pid
	sys_ioctl STDERR,TIOCSPGRP
%endif
	call	tty_initialize
	xor	eax,eax
	mov	[pid],eax
	ret

bad_record:
	mov	eax,text.nosuchjob
write_record:
	WRITE_STRING
	ret
			
no_such_pid:
	mov	eax,text.nosuchpid
	jmps	write_record
			
;****************************************************************************
;* cmd_bg *******************************************************************
;****************************************************************************

cmd_bg:
	mov	eax,[cmdline.arguments + 4]
	xor	ecx,ecx
	xor	ebx,ebx			
	or 	eax,eax
	jz	.take_first
	mov	cl,[eax]
	sub 	cl,'0'
	cmp 	cl,MAX_PID+1
	jae	bad_record

.take_first:
;	xchg	ebx,[pid_array+ecx*4]
	lea 	edi,[pid_array+ecx*4]
	mov	ebx,[edi]
	or	ebx,ebx
	jz	bad_record
;	call	tty_restore
%ifdef SPGRP
	sys_setpgid EMPTY,0 ;FIXME 
%endif
	sys_kill EMPTY,SIGCONT	
	test	eax,eax
	jns	.ok
	xor 	eax,eax
	mov	[edi],eax
	call	no_such_pid
.ok:
	ret

;****************************************************************************
;* cmd_umask
;****************************************************************************
cmd_umask:
	mov     esi, [cmdline.arguments + 4]
        or      esi, esi
        jz      .echo
        xor     eax, eax
        xor     ebx, ebx
.set:
        lodsb
        sub     al, '0'
        js      .doit
        cmp     al, 8
        ja      .ret
        shl     ebx, 3
        add     ebx, eax
        jmps    .set
.doit:
        sys_umask
.ret:
        ret
.echo:
        sys_umask
        xchg    eax, ebx
        sys_umask
        mov     edi, b_id
        push    edi
        xchg    eax, ebx
        xor     ecx, ecx
        _mov    ebx, 8
.div:
        xor     edx, edx
        div     ebx
        add     dl, '0'
        inc     ecx
        push    edx
        or      eax, eax
        jnz     .div
        mov     dl, '0'
        inc     ecx
        push    edx
.loop:
        pop     eax
        stosb
        loop    .loop
        mov     al, 10
        stosb
        pop     eax
        mov     ecx, edi
        sub     ecx, eax
        WRITE_CHARS
        ret

;****************************************************************************
;* cmd_jobs *****************************************************************
;****************************************************************************
%if 0
cmd_jobs:			
	mov 	esi,pid_array
.find_loop:
	cmp	esi,pid_array+(4*MAX_PID)
	jz 	.end
	lodsd
	or 	eax,eax
	jz	.find_loop
.got_it:			
	mov 	eax,esi
	sub	eax,pid_array+4
	shr	eax,2
	mov	ah,010
	add 	al,'0'
	mov	[b_id],ax
	WRITE_CHARS b_id,2
	jmps	.find_loop
.end:
	ret
%endif

cmd_jobs:
        mov     esi,pid_array
.find_loop:
        cmp     esi,pid_array+(4*MAX_PID)
        ;jz     .end
        jz      cmd_bg.ok
        lodsd
        or      eax,eax
        jz      .find_loop
.got_it:
        push    eax
        mov     eax,esi
        sub     eax,pid_array+4
        shr     eax,2
        add     eax,'0: '
        mov     edi, b_id
        stosd
        dec     edi
        xor     ecx, ecx
        _mov    ebx, 10
        pop     eax
        push    edi
.div:
        xor     edx, edx
        div     ebx
        inc     ecx
        add     dl, '0'
        push    edx
        or      eax, eax
        jnz     .div
.poploop:
        pop     eax
        stosb
        loop    .poploop
        xchg    eax, ebx        ; Add a newline
        stosb                   ; in two bytes
        pop     eax
%if __OPTIMIZE__=__O_SPEED__
        sub     eax, byte 3
%else
        dec     eax
        dec     eax
        dec     eax
%endif
        sub     edi, eax
        mov     ecx, edi
        WRITE_CHARS
        jmps    .find_loop
;

break_hndl:
%ifndef __LINUX__ 
	sys_signal SIGINT,break_hndl
%endif
%ifdef	DEBUG
	WRITE_STRING text.break
%endif
	mov	ebx,[pid]
	test	ebx,ebx
	jnz	.not_us
	WRITE_STRING text.suicide
	ret
.not_us:	
	sys_kill EMPTY,SIGTERM
	ret
ctrl_z:
%ifndef SPGRP
	sys_signal SIGTSTP,ctrl_z
%endif
	mov	ebx,[pid]
	test	ebx,ebx
	jnz	.not_us
	WRITE_STRING text.stop
	ret
.not_us:
	sys_kill EMPTY,SIGSTOP
	ret

cmd_clear:
	WRITE_STRING .cls
	ret

.cls	db	0x1b,"[H",0x1b,"[J",0

;****************************************************************************
; cmd_enable:
; Implements the following behaviour:
; enable -n         -    disables all builtin commands
; enable -n cmd     -    disables builtin 'cmd'
; enable -a	    -    enables all builtin commands
; enable cmd        -    enables given builtin 'cmd'
; Note! You may not disable 'enable' cmd except fixing sources
;****************************************************************************
cmd_enable:
	mov	ebx,[cmdline.arguments + 4]
	xor	eax, eax
	cmp	word [ebx], '-n'
	je	.disable_it
	cmp	word [ebx], '-a'
	je	.all_cmds
	inc	eax
	jmp	.proceed
.all_cmds:
	inc	eax
	xor	ebx, ebx
	jmp	.proceed
.disable_it:
	mov	ebx,[cmdline.arguments+8]
	jmp	.proceed
	
.proceed:
; ebx - cmd name (0 - for all)
; eax - flags to be set

	mov	edx,builtin_cmds.table
.next:
	mov	edi,[edx+builtin_cmds_s.name]
	mov	esi,[edx+builtin_cmds_s.flags] ;; PPro optimization ;)
	test	edi,edi
	jz	.end
	cmp	esi, -1 ;; don't disable 'enable'
	je	.skip
	test	ebx, ebx
	jz	.do_it   ;; for all
	mov	edi, ebx
	mov	esi,[edx+builtin_cmds_s.name]
	push	eax
	call	string_compare
	pop	eax
	test	ecx, ecx
	jne	.skip
.do_it:
	mov	[edx+builtin_cmds_s.flags], eax
.skip:
	add	edx,builtin_cmds_s_size
	jmp	.next
.end:
	ret

;****************************************************************************
;* cmd_help *****************************************************************
;****************************************************************************
cmd_help:
	WRITE_STRING text.hlp_prompt
	mov	ebx, builtin_cmds.table
.next:
	mov	esi,[ebx+builtin_cmds_s.name]
	test	esi,esi
	jz	.end
	mov	eax,[ebx+builtin_cmds_s.flags]
	test	eax, eax
	jnz	.pr_normal
	WRITE_STRING text.cmd_disabled
.pr_normal:
	WRITE_STRING esi
	WRITE_STRING text.space
	add	ebx,builtin_cmds_s_size
	jmp	.next
.end:
	WRITE_STRING text.eol
	ret

;****************************************************************************
;* cmd_pushd ****************************************************************
;* Note: currently doesn't support <noargs> and +/-n
;****************************************************************************
cmd_pushd:
	mov	eax, [pushd_top]
	mov	ebx, [cmdline.arguments + 4] ;; PPro optimization ;)
	cmp	eax, 4095
	jae	.end
	shl	eax, 12 ;; == mul eax, 4096
	test	ebx, ebx
	jz	.end
	lea	edi, [pushd_mem+eax]
	sys_getcwd edi,PATH_MAX
	inc	dword [pushd_top]
	jmp	near cmd_cd
.end:
	ret

;****************************************************************************
;* cmd_popd *****************************************************************
;* Note: currently doesn't support +/-n
;****************************************************************************
cmd_popd:
	mov	eax, [pushd_top]
	test	eax, eax
	jz	.end
	dec	eax
	mov	[pushd_top], eax
	shl	eax, 12 ;; == mul eax, 4096
	lea	ebx, [pushd_mem+eax]
	jmp	near cmd_cd.has_arg
.end:
	ret

;****************************************************************************
;* cmd_dirs *****************************************************************
;* Note: currently doesn't support +/-n -l
;****************************************************************************
cmd_dirs:
	mov	eax, [pushd_top]
	test	eax, eax
	jz	.end
	xor	ecx, ecx
.loop:
	mov	eax, ecx
	shl	eax, 12
	lea	ebx, [pushd_mem+eax]
	WRITE_STRING ebx
	mov	ebx, text.eol
	WRITE_STRING ebx
	inc	ecx
	cmp	ecx, [pushd_top]
	jb	.loop
.end:
	ret
;****************************************************************************
;****************************************************************************
;*
;* PART 5: read only data
;*
;****************************************************************************
;****************************************************************************

text:
.welcome:			db	"asmutils shell"
.eol				db	__n, EOL
.prompt_user:			db	"$ ", EOL
.prompt_root:			db	"# ", EOL
.prompt_ptrace:			db	"+ ", EOL
.prompt_incomplete:		db	"> ", EOL
.cmd_not_found:			db	": command not found", __n, EOL
.suicide:			db	__n,"Suicide is painless...", EOL
.stop:				db	__n,"You say STOP and I say go...", EOL
.cd_failed:			db	"can't change directory", __n, EOL
.logout:			db	"logout", __n, EOL
.scerror:			db	"can't open script", __n, EOL
.stopped:			db 	"Stopped id: ", EOL
.nosuchjob			db	"No such job", __n, EOL
.nosuchpid			db	"Child is 0xDEAD. I'm sorry", __n, EOL
.hlp_prompt			db	"These shell commands are defined internally",__n,"A star (*) next to a name means that the command is disabled",__n,__n,EOL
%ifdef DEBUG
.break:				db	__n,">>SIGINT received<<,sending SIGTERM", __n, EOL
%endif
.space				db	' ', EOL
.cmd_disabled			db	"*",EOL

STRUC builtin_cmds_s
.name:		resd	1
.cmd:		resd	1
.flags:		resd	1
ENDSTRUC

builtin_cmds:
		align	4
.table:
		dd	.exit,		cmd_exit,	1
		dd	.logout,	cmd_exit,	1
		dd	.cd,		cmd_cd,		1
		dd	.pushd,		cmd_pushd,	1
		dd	.popd,		cmd_popd,	1
		dd	.dirs,		cmd_dirs,	1
		dd      .enable,	cmd_enable,	-1 ;; 'enable' can't be disabled
		dd      .export,	cmd_export,	1
		dd	.and,		cmd_and,	1
		dd	.or,		cmd_or,		1
		dd	.colon,		cmd_colon,	1
		dd	.fg,		cmd_fg,		1
		dd	.bg,		cmd_bg,		1
		dd	.jobs,		cmd_jobs,	1
		dd	.clear,		cmd_clear,	1
		dd	.umask,		cmd_umask,	1
		dd	.help,		cmd_help,	1
		dd	0,		0,		0

.and		db	"&&", 0
.or		db	"||", 0
.colon		db	":", 0
.exit		db	"exit", 0
.logout		db	"logout", 0
.cd		db	"cd", 0
.pushd		db	"pushd", 0
.popd		db	"popd", 0
.dirs		db	"dirs", 0
.enable		db      "enable", 0
.export		db      "export", 0
.fg		db	"fg", 0
.bg		db 	"bg", 0
.jobs		db	"jobs", 0
.clear		db	"clear", 0
.umask		db	"umask", 0
.help		db	"help", 0
;TODO:
; ==============================================================
; variables
; = (variable=value)
;===============================================================
; alias, bind, break, builtin, case, command,
; continue, declare, eval, exec, fc, function
; for, getopts, hash, history, if, kill, let, local,
; read, readonly, return, set, shift, source,
; suspend, times, trap, type, typeset, ulimit, umask, unalias,
; unset, until, wait, while
;===============================================================
; test ??? 
;===============================================================
.paths		db	"/bin", 0
		db	"/sbin", 0
		db	"/usr/bin", 0
		db	"/usr/sbin", 0
		db	"/usr/local/bin", 0
		db	"/usr/local/sbin", 0

erase_line      db	0x1b,"[2K",0xd
insert_char 	db	0x1b,"[1@]"
delete_one_char db	0x8,0x1b,"[1P"
beep   		db	0x07
pushd_top	dd	0

;****************************************************************************
;****************************************************************************
;*
;* PART 6: uninitialized data
;*
;****************************************************************************
;****************************************************************************

UDATASEG

signal_struc:
.handler	resd	1
.mask		resd	32
.flags		resd	1
.restorer	resd	1 ;obsolote

cmdline:
.buffer1		CHAR	CMDLINE_BUFFER1_SIZE
.buffer2		CHAR	CMDLINE_BUFFER2_SIZE
.program_path		CHAR	CMDLINE_PROGRAM_PATH_SIZE
			alignb	4
.prompt			ULONG	1
.arguments		ULONG	CMDLINE_MAX_ARGUMENTS
.environment		ULONG	CMDLINE_MAX_ENVIRONMENT
.flags			ULONG	1
.argument_count		ULONG	1
.buffer2_offset		ULONG	1
.buffer1_offset		ULONG	1
.arguments_offset	ULONG	1
.redir_stdin		ULONG   1
.redir_stdout    	ULONG   1

pipe_pair:
.read			ULONG	1
.write			ULONG	1

stat_buf B_STRUC Stat,.st_mode

%ifdef TTYINIT
termattrs B_STRUC termios,.c_lflag
getchar_buff		resb	3
getchar			resb	3
%endif

%ifdef HISTORY
history_cur		resd	1
history_start		resd	1
%endif

backspace:
cur_move_tmp		resd	1	;db 0x08,' ',0x08
cur_dir			resd	1

environ_count		resd	1

file_buf		resb	FILE_BUF_SIZE
write_after_slash	resd	1
first_chance		resb	1
file_name		resb	255
file_equal		resb	255
first_time		resb	1	;stupid

b_id			resw	10
pbackground		resb	1
interactive		resb	1	;interactive/script
pid			resd	1	;curr running child
pid_array		resd	MAX_PID
rtn			resd	1	;return code
script_fd		resd	1	;script handle
cur_pid			resd	1

pushd_mem:		resb	PATH_MAX*4096

END
