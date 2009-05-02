;Copyright (C) 1999 Dmitry Bakhvalov <dl@gazeta.ru>
;
;$Id: ps.asm,v 1.4 2000/09/03 16:13:54 konst Exp $
;
;hackers' ps
;
;0.01: 28-Oct-1999	initial release
;
;syntax: ps
; 	 No options are supported yet (and probably wont be) :)
;
;Always returns 0
; 
; Please keep in mind that this is a hackers' ps, in other words it is
; in no way a replacement for standard GNU ps. Still it's usefull to find
; out what processes are running in your system (In case you want to kill some:)
;
; Hint: If you are surprised with TTY field, than substruct 1024 from its value
; 	to get the real tty number. If the field is 0 than the process doesnt
; 	have a tty :)
;
;	RSS field is measured in pages.
;
; Send me any feedback,suggestions,additional code, etc.
;

		%include "system.inc"
		
%assign	statbuf_size	1024
%assign	dirbuf_size	4096


		CODESEG
		
START:
		mov	ecx,title			; print title
		call	print
		
		mov	ebx,_proc			; open	/proc
		sys_open EMPTY,O_RDONLY
		test	eax,eax
		js	near error
		
		mov	ebp,eax				; ebp holds filehandle

get_next_dentry:
		sys_getdents ebp,dirbuf,dirbuf_size	; read this dir
		test	eax,eax
		js	near error			; cant read the dir
		jz	near no_more_files_in_proc	; no more entries in this dir
		
		mov	ebx,ecx				; ebx=dirbuf
		mov	ecx,eax				; ecx = the number of bytes
							; that actually have been read
next_filename:
		pushad					; save regs

		lea	esi,[ebx+10]			; esi=next entry name
		call	is_number			; is it a process?
		test	eax,eax
		jnz	near not_a_number		; nope

		push	esi				; save entry's name
		
		mov	esi,_proc			;
		mov	edi,file_buf			;
		call	strcpy				; file_buf="/proc/"
		
		pop	esi				; restore entry's name
							; edi already holds file_buf
		call	strcat				; file_buf="/proc/pid"
		
		mov	esi,_stat			; esi="/stat"
							; edi already holds file_buf
		call	strcat				; file_buf="/proc/pid/stat"
	
		sys_open edi,O_RDONLY			; open /proc/pid/stat
		test	eax,eax
		js	not_a_number
		
		sys_read eax,statbuf,statbuf_size	; read it
		test	eax,eax
		js	not_a_number

		sys_close 				; close it
		
		mov	edi,ecx				; edi=statbuf ptr
		call	print_fields
		
		mov	ecx,cr
		call	print
		
not_a_number:
							; lets get to the next 
							; dentry		
		popad					; restore regs
		xor	eax,eax
		mov	ax,[ebx+8]			; eax=rec_len
		
		add	ebx,eax				; point ebx to next entry
		sub	ecx,eax				; rc-=rec_len
		jz	near get_next_dentry		; read more dentries
		jmp	next_filename			; our buf is not empty

			
error:	
no_more_files_in_proc:

		sys_exit_true


;
; -------------------------------- procedures ---------------------------------
;

; edi=buf, ecx=field num (begins at 1)
; -
print_field:
		pushad

.next_field:				
		push	ecx
		
		xor	eax,eax
		xor	ecx,ecx
		dec	ecx
		mov	esi,edi			; esi = ptr
		repnz	scasb			; look for \0
		
		pop	ecx
		loop	.next_field		
		
		mov	ecx,esi			; our field
		call	print
		
		mov	ecx,tab			; \t
		call	print
		
		popad	
		ret

; edi=buf
; 
print_fields:
		pushad
		
		; replace all ' ' with \0
		mov	esi,edi
.next_char:
		lodsb
		test	al,al
		jz	.end_of_buf
		cmp	al,' '
		jnz	.next_char
		mov	byte [esi-1],0		; replace ' ' with \0
		jmp	.next_char
.end_of_buf:
		; now print the fields we are interested in
		mov	esi,fields
.next_f:		
		lodsb
		test	al,al
		jz	.ret			; end of table
		movzx	ecx,al
		call	print_field
		jmp	.next_f
.ret:
		popad
		ret

; esi=string
; eax= 0 if it consists only of digits
is_number:
		push	esi
		xor	eax,eax

.next_char:		
		lodsb
		
		test	al,al
		jz	.done
		
		cmp	al,'0'
		jae	.next_test
		
		inc	ah		; set flag
		jmp	.done
		
.next_test:
		cmp	al,'9'
		jle	.next_char
		
		inc	ah		; set flag
.done:
		xchg	ah,al		; put flag in al
		xor	ah,ah		; wipe ah
		
		pop	esi
		ret


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
		
		xor	edx,edx
		dec	edx
.do_strlen:
		inc	edx
		lodsb
		test	al,al
		jnz	.do_strlen
		
		pop	esi
		pop	eax
		ret

; esi=source  edi=dest
; -
strcpy:
		pushad
				
		call	strlen
		inc	edx		; copy NULL too
		mov	ecx,edx
		rep	movsb
		
		popad
		ret

; esi=source  edi=dest
; -
strcat:
		pushad
				
		xchg	esi,edi
		call	strlen
		
		xchg	esi,edi
		add	edi,edx
		
		call	strlen
		inc	edx		; copy NULL byte too
		mov	ecx,edx
		rep 	movsb		; copy
		
		popad
		ret
	


		DATASEG
		
title:		db	"PID",9,"TTY",9,"STAT",9,"RSS",9,"COMMAND",10,0
_proc:		db	"/proc/",0
_stat:		db	"/stat",0
cr:		db	10,0
tab:		db	9,0
fields:		db	1,7,3,24,2,0

		UDATASEG

file_buf:	resb	256

statbuf	resb	statbuf_size
dirbuf	resb	dirbuf_size

		END		
								
