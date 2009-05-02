;Copyright (C) 1999 Bart Hanssens <antares@mail.dma.be>
;
;$Id: kill.asm,v 1.1.1.1 2000/01/26 21:19:32 konst Exp $
;
;hackers' kill	(util-linux kill replacement)
;
;0.01: 04-Jul-1999	initial release
; 
;syntax: kill signal pid
;	 kill -l
;
; TODO: add process name
;	add -s
;	add -p


;You can compile two versions - large & small.
;Large recognizes signal names, small doesnot (only numbers).

%include "system.inc"

;
;Compile large or small version?
;

%define LARGE_KILL
;%undef LARGE_KILL

CODESEG

arg_to_nr:
	push	ecx
	push	edi

	xor	eax,eax
	xor	ebx,ebx
	xor	ecx,ecx
	mov	edi,10

	mov	cl,[esi]
	cmp	cl,'-'
	jne	.digit
	inc	bh		; flag as negative number
	inc	esi
.next_digit:
	mov	cl,[esi]
.digit:
	sub	cl,'0'
	jb	.done
	cmp	cl,9
	ja	.done
	mul	edi
	add	eax,ecx
	inc	bl		; count number of digits
	inc	esi
	jmp short .next_digit
.done:
	or	bh,bh
	je	.exit
	neg	eax
.exit:
	pop	edi
	pop	ecx
	ret

%ifdef LARGE_KILL

%assign	MAX_NAME	6

;	strlen(name), signal, name

siglist	db	3, SIGHUP   ,'HUP'
	db	3, SIGINT   ,'INT'
	db	4, SIGQUIT  ,'QUIT'
	db	3, SIGILL   ,'ILL'
	db	4, SIGABRT  ,'ABRT'
	db	3, SIGFPE   ,'FPE'
	db	4, SIGKILL  ,'KILL'
	db	4, SIGSEGV  ,'SEGV'
	db	4, SIGALRM  ,'ALRM'
	db	4, SIGPIPE  ,'PIPE'
	db	4, SIGTERM  ,'TERM'
	db	4, SIGUSR1  ,'USR1'
	db	4, SIGUSR2  ,'USR2'
	db	4, SIGCHLD  ,'CHLD'
	db	4, SIGCONT  ,'CONT'
	db	4, SIGSTOP  ,'STOP'
	db	4, SIGTSTP  ,'TSTP'
	db	4, SIGTTIN  ,'TTIN'
	db	4, SIGTTOU  ,'TTOU'
	db	4, SIGTRAP  ,'TRAP'
	db	3, SIGIOT   ,'IOT'
	db	3, SIGBUS   ,'BUS'
	db	6, SIGSTKFLT,'STKFLT'
	db	3, SIGURG   ,'URG'
	db	2, SIGIO    ,'IO'
	db	4, SIGPOLL  ,'POLL'
;	db	3, SIGCLD   ,'CLD'	;mips only ?
	db	4, SIGXCPU  ,'XCPU'
	db	4, SIGXFSZ  ,'XFSZ'
	db	6, SIGVTALRM,'VTALRM'
	db	4, SIGPROF  ,'PROF'
	db	3, SIGPWR   ,'PWR'
	db	5, SIGWINCH ,'WINCH'
	db	6, SIGUNUSED,'UNUSED'
	db	0

lf	db	10
space	db	32

%endif


START:
	pop	edi
	dec	edi
%ifdef LARGE_KILL
	jz near	.exit
%else
	jz	.exit
%endif
	pop	esi

	pop	esi
	mov	bl,[esi]
	cmp	bl,'-'
	je	.args
	mov	ecx,SIGTERM	; first argument is pid, use default signal
%ifdef LARGE_KILL
	jmp	.kill_pid
%else
	jmp short .kill_pid
%endif
.args:

%ifdef LARGE_KILL
	inc	esi
	mov	bl,[esi]
	cmp	bl,'l'
	jne	.signal
	
	mov	edi,siglist	; show a list of signals
.show_sigs:
	cmp	byte [edi],0
	je	.show_done
	mov	esi,[edi]
	and	esi,0xf
	inc	edi
	inc	edi
	sys_write STDOUT, edi, esi
	sys_write STDOUT, space, 1
	add	edi,esi
	jmp short .show_sigs
.show_done:
	sys_write STDOUT, lf, 1
	jmp near .exit

.signal:
	dec	edi
	je near	.exit
	call	arg_to_nr
	or	bl,bl		; wasn't a number
	je	.sig_name
	mov	ecx,eax
	jmp short .sig_ok

.sig_name:
	xor	eax,eax		; arg might be a signal name
.store_name:
	mov	bl,[esi]
	or	bl,bl
	je	.stored
	mov	[signame+eax],bl
	cmp	al,MAX_NAME - 1
	je	.start_cmp
	inc	al
	inc	esi
	jmp short .store_name
.stored:	
	or	al,al
	je	.exit		; nothing to store

.start_cmp:
	xor	ebx,ebx
	xor	edx,edx
	dec	edx
	dec	edx
.prep_next_name:
	mov	cl,al
	xor	esi,esi
.next_name:
	inc	edx
	inc	edx
	add	dl,bh
	mov	bh,[siglist+edx]
	or	bh,bh
	je	.exit		; signal name not found
	cmp	bh,cl		; arg length = signal name length ?
	jne	.next_name
.cmp_name:
	mov	bl,[signame+esi]
	cmp	bl,[siglist+edx+2+esi]
	jne	.prep_next_name
	inc	esi
	loop	.cmp_name
.cmp_done:
	mov	cl,[siglist+edx+1]	; use signal number

.sig_ok:

%else

;
;small kill
;

	dec	edi
	je	.exit		; we've got a signal but no pid
	inc	esi
	mov	bl,[esi]
	call	arg_to_nr
	or	bl,bl		; was it a number ?
	je	.exit
	mov	ecx,eax
%endif

.next_pid:
	pop	esi

.kill_pid:
	call	arg_to_nr
	or	bl,bl
	jz	.exit
	sys_kill eax
	dec	edi
	jnz	.next_pid

.exit:
	sys_exit

%ifdef LARGE_KILL

UDATASEG

signame	resb	MAX_NAME

%endif

END
