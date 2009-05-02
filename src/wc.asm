;Copyright (C) 1999 Dmitry Bakhvalov <dl@gazeta.ru>
;
;$Id: wc.asm,v 1.4 2001/08/28 06:31:55 konst Exp $
; 
;hackers' wc
;
;This version is 95% GNU compatable :) 
;It doesnt support --long options, doesnt have --version and --help.
;It doesnt print total field when multiply files are given in the command
;line.
;
;0.01: 20-Feb-2000	initial release
;0.02: 23-Aug-2000	reading from stdin fixed (TH)
;0.03: 25-Aug-2001	option without argument fixed (JH)
;
;syntax: wc [option] [file, file, file...]
;
;	If no file is given stdin is used.
;	Options are:
;		-l : print only the number of lines
;		-w : print only the number of words
;		-c : print only the number of bytes
;		Options are cummulative.
;		If no options are given - print the number of lines,
;		words and bytes.
;
;	returns -1 on error, 0 on success
; 
; If someone really feels like he needs more of the original GNU wc's
; options - just ask me or better yet add 'em yourself :)
;
; Send me any feedback,suggestions,additional code, etc.

		%include "system.inc"
		
		CODESEG
		
START:
		pop	eax			; get argc
		dec	eax
		jnz	has_arguments
		pop	ebx
		jmp	use_stdin
has_arguments:
		pop	eax			; get argv[0]
get_next_arg:		
		pop	ebx
		test	ebx,ebx
		jz	near no_more_args
		
		mov	esi,opts_table		; table
		mov	edi,_lines
		xor	ecx,ecx
		mov	cl,3
		mov	dl,100b
fetch_from_table:
		lodsw
		cmp	word [ebx],ax		; is it our option?
		jnz	try_next_option		; nope
		or	byte [flgs],dl		; set bitflag
		jmps	get_next_arg
		;pop	ebx			; get the next argument off the stack
try_next_option:
		shr	dl,1	
		xor	eax,eax			; clear counters
		stosd	
		loop	fetch_from_table
		
just_open_it:		
		xor	eax,eax
		cmp	byte [ebx],'-'		; user wants STDIN
		jz	use_stdin
		
		mov	edi,ebx			; save filename
		
		mov	byte [_opened_a_file], 1
		sys_open EMPTY,O_RDONLY
		test	eax,eax
		js	near error
		jmp	set_filehandle
use_stdin:
		mov	byte [_use_stdin], 1
set_filehandle:
		mov	ebp,eax
read_file:		
		sys_read ebp,buf,buf_size
		test	eax,eax
		js	near error
		jz	print_results
		
		mov	esi,ecx			; esi=ecx=buf
		mov	ecx,eax			; ecx=bites read

		xor	eax,eax
buf_is_not_empty:
		mov	ebx,_bytes
		lodsb				; get next char
		inc	dword [ebx]		; count this char
		sub	ebx,4			; ebx=_words
		
		cmp	al,' '
		jz	inside_a_word
		cmp	al,9
		jz	inside_a_word
		cmp	al,10
		jz	inside_a_word
		mov	ah,1			; set flag (inside a word)
		jmp	count_lines
inside_a_word:
		test	ah,ah			; inside a word?
		jz	count_lines		; nope
		inc	dword [ebx]		; count this word
		xor	ah,ah			; reset flag
count_lines:		
		sub	ebx,4			; ebx=_lines
		
		cmp	al,10			; is it a '\n' ?
		jnz	not_a_new_line
		inc	dword [ebx]		; count this new line
not_a_new_line:		
		dec	ecx			; 
		jnz	buf_is_not_empty
		jmp	read_file
		
print_results:
		push	edi			; save filename

		xor	ecx,ecx
		mov	bl,[flgs]
		mov	cl,3
		mov	dl,100b
		mov	esi,_lines
next_counter:
		push	ecx
		lodsd
		test	bl,bl
		jz	print_it_now
		test	bl,dl
		jz	skip_it
print_it_now:
		mov	edi,num_buf
		mov	ecx,edi
		call	bin_to_dec
		call	print
skip_it:		
		shr	dl,1
		pop	ecx
		loop	next_counter
		
		pop	ecx			; restore filename
		cmp	byte [_use_stdin], 1
		jz	print_newline
		call	print
print_newline:

		mov	ecx,cr			; print \n
		call	print

		jmp	get_next_arg	

no_more_args:
		cmp	byte [_opened_a_file], 0
		jne	true_exit
		mov	byte [_opened_a_file], 1
		xor	eax, eax
		jmp	use_stdin
true_exit:
		xor	ebx,ebx		
		jmp	do_exit
error:		
		xor	ebx,ebx
		dec	ebx
do_exit:
		sys_exit		

;
; -------------------------------- procedures ---------------------------------
;

; ecx=string to print
print:
		pushad
				
		mov	esi,ecx
		call	strlen
	
		; ecx already holds string, edx holds strlen
		sys_write STDOUT

		popad		
		ret

; esi=string
; edx=strlen
strlen:
		push	eax
		push	esi
		
		xor	eax,eax
		mov	edx,eax
		dec	edx
.do_strlen:
		inc	edx
		lodsb
		test	al,al
		jnz	.do_strlen
		
		pop	esi
		pop	eax
		ret

; eax=number	edi=buf to store string
; -
bin_to_dec:
		pushad
		
		xor	ecx,ecx		
		mov	ebx,ecx
		mov	bl,10
.div_again:		
		xor	edx,edx
		div	ebx
		add	dl,'0'
		push	edx
		inc	ecx
		test	eax,eax
		jnz	.div_again
.keep_popping:		
		pop	eax
		stosb
		loop	.keep_popping
		
		; put \t\x0
		mov	ax,0x009
		stosw
		
		popad
		ret	

		DATASEG

opts_table:
		dw	"-l"
		dw	"-w"
		dw	"-c"

flgs:		db	0	

cr:		db	10,0
		
		UDATASEG
				

_lines:		resd	1
_words:		resd	1
_bytes:		resd	1
_use_stdin:	resb	1
_opened_a_file:	resb	1

num_buf:	resb	16
buf:		resb	4096
buf_size	equ	$-buf

		END
