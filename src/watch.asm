;Copyright (C) 2001 Rudolf Marek <marekr2@fel.cvut.cz>,<ruik@atlas.cz>
;
;$Id: watch.asm,v 1.2 2001/09/24 16:49:19 konst Exp $
;
;hackers' watch
;
;syntax: watch -n [sec] --interval=[sec] filename_to_execute  its_args
;
;0.01: 16-Sep-2001	initial release
;
;NOTE: welcome to a stack-magic world :)

%include "system.inc"

%assign DEFAULT_SLEEP 2

CODESEG


START:
	pop 	esi
    	pop 	esi
	pop 	eax
	or 	eax,eax
	jz near	.help
	xchg 	eax,ebp
	sys_write STDOUT,erase_screen,4
	xchg 	ebp,ebx
    	cmp 	word [ebx],'-n'
	jz	near .interval_change
	cmp 	dword [ebx],'--in'
	jz	near .separate_interval
;	xor 	ebp,ebp ;put there a default 
;	inc 	ebp
;	inc 	ebp
	push 	byte DEFAULT_SLEEP
	pop  	ebp
.args_done:
	push 	ebx
	mov 	ecx,esp
	mov 	esi,esp
.find_env:
	lodsd
	or 	eax,eax
	jnz .find_env
	 ;esi start of env ecx start of args, ebx filename
	push 	ebx
	push 	ecx
	push 	esi
.fork_it:
	pop 	edx
	pop 	ecx
	pop 	ebx
	sys_fork
	test 	eax,eax
	jnz .wait
	sys_execve EMPTY,EMPTY,EMPTY
	jmp	.error
.wait:	
	push 	ebx
	push 	ecx
	push 	edx
	sys_wait4 0xffffffff,NULL,NULL,NULL    ;Wait utill child die ...
	mov edi,esp
	push 	byte 0
	push 	ebp
	mov 	esi,esp
	push 	byte 0
	push 	byte 0
	mov 	ecx,esp
	sys_nanosleep esi,EMPTY               
	mov 	esp,edi
	sys_write STDOUT,erase_screen,4 
	jmp .fork_it

.interval_change:
	pop 	esi
	call .atoi
	pop 	ebx
	jmp	.args_done
.separate_interval:
	xchg 	ebx,esi
.find_eq:
	lodsb
	or 	al,al
	jz .error
	cmp 	al,'='
	jnz .find_eq
	call .atoi
	pop 	ebx
	jmp	.args_done
	
.help:  sys_write STDOUT,help,help_len
	jmps .exit
.error: sys_write STDOUT,error,error_len
.exit:  sys_exit 255

.atoi:	; 'borrowed' from mknod.asm, which has (had?) been borrowed from jonathan leto's chown :-))
	xor	eax,eax
	xor	ebp,ebp
.next:
	lodsb			; argument is in esi 
	test	al,al
	jz	.done
	sub	al,'0'
	imul	ebp,10
	add	ebp,eax
	jmps	.next		
.done:
	ret			; return value is in ebp

erase_screen db 0x1b,"[2J"
help db "watch [args] exec_name exec_args - exec a program periodically, showing output",__n
     db "fullscreen. By default, the prog. is run every 2 sec; use -n or --interval=",__n
     db "to specify a different interval.",__n
help_len equ $-help
error db "Execve failed ...",__n
error_len equ $-error

END
