;Copyright (C) 1999 Dmitry Bakhvalov <dl@gazeta.ru>
;
;$Id: strings.asm,v 1.3 2000/04/07 18:36:01 konst Exp $
;
;hackers' strings
;
;0.01: 18-Oct-1999	initial release
;0.02: 19-Oct-1999	size optimizations
;
;syntax: strings [option] [file, file, file...]
;        The only supported option by now is -n.
;	 See strings manpage to find out more about this cool option :)
;
;	If no file is given stdin is used.
;
;	returns -1 on error, 0 on success
; 
; If someone really feels like he needs more of the original GNU strings'
; options - just ask me or better yet add 'em yourself :)
;
; Send me any feedback,suggestions,additional code, etc.
;

		%include "system.inc"
		
		CODESEG
		
START:
		pop	eax			; get argc
		dec	eax
		jz	set_filehandle		; read from stdin (eax=0)
		
		pop	eax			; get argv[0]
get_next_arg:		
		pop	ebx
		test	ebx,ebx
		jz	near no_more_args
		
		cmp	word [ebx],"-n"
		jnz	just_open_it
		
		pop	esi
		call	ascii_to_bin
		mov	[n],eax
		
		jmp	get_next_arg
			
		
just_open_it:		
		sys_open EMPTY,O_RDONLY
		test	eax,eax
		js	near error
		
set_filehandle:
		mov	ebp,eax
read_file:		
		sys_read ebp,buf,buf_size
		test	eax,eax
		js	near error
		jz	get_next_arg
		
		mov	esi,ecx			; esi=ecx=buf
		mov	ecx,eax			; ecx=bites read
		xor	edx,edx			; edx will hold a number of
						; printable chars
		xor	eax,eax
		
next_char:
		lodsb
		cmp	al,' '
		jl	not_an_ascii
		cmp	al,'~'
		jg	not_an_ascii
		test	ah,ah
		jnz	inc_counter
		inc	ah
		mov	[pointer],esi
inc_counter:		
		inc	edx
		loop	next_char
		jmp	read_file
not_an_ascii:
		test	ah,ah
		jz	near count_this_char
		cmp	edx,[n]
		jl	reset_flags

		push	ecx			; save counter
		
		mov	ecx,[pointer]
		dec	ecx
		sys_write STDOUT
		
		sys_write STDOUT, cr, 1
		
		pop	ecx			; restore counter
reset_flags:
		xor	eax,eax			; reset ascii flag (ah)
		xor	edx,edx			; reset ascii counter
count_this_char:		
		dec	ecx
		jnz	near next_char
		jmp	read_file
		
error:
		xor	ebx,ebx
		dec	ebx
		jmp	do_exit
no_more_args:
		xor	ebx,ebx		
do_exit:
		sys_exit	


; esi = string 
; eax = bin number
ascii_to_bin:
		xor	eax,eax
		xor	ebx,ebx
.next_digit:		
		lodsb
		test	al,al
		jz	.done
		sub	al,'0'
		imul	ebx,10
		add	ebx,eax
		jmp	.next_digit
.done:		
		xchg	ebx,eax
		ret

		DATASEG

cr:		db 10		
n:		dd  4
		
		UDATASEG

pointer:	resd	1		
buf:		resb	4096
buf_size	equ	$-buf		

		END
		