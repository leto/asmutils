;Copyright (C) 2000 Dmitry Bakhvalov <dl@gazeta.ru>
;
;$Id: mv.asm,v 1.4 2002/02/02 08:49:25 konst Exp $
;
;hackers' mv
;
;syntax: mv source dest, or
;	 mv source... directory
;
;No options are supported by now
; 
;If someone really feels like he needs more of the original GNU mv's
;options - just ask me or better yet add 'em yourself :)
;
;Send me any feedback,suggestions,additional code, etc.

		%include "system.inc"
		CODESEG
START:
		pop	ecx			; get argc
		cmp	ecx,byte 3		; must have at least 3 args
		jl	near invalid_args

		pop	eax			; skip argv[0]
		dec	ecx			; dont count argv[0]
		
		dec	ecx			; last argument's index
		xor	edi,edi			;  eax=NULL
		xchg	edi,[esp+ecx*4]		;  argv[last_arg]=NULL
		jmp	short args_loop

move_file:
		call	mv
args_loop:		
		pop	esi			; get nex arg
		test	esi,esi			; no more?
		jnz	move_file
		
no_more_args:
invalid_args:
		sys_exit_true			; exit


; mv files
; esi - source file; edi - dest file/dir
; carry = 1 if error

mv:
		pushad

		call	is_dir			; is our dest a dir
		jnz	.just_move		; it's a file. move now
		
		push	edi			; save target
		
		call	strlen			; get src len
		mov	ax,0x002f		; al='/',ah=0
		mov	ecx,edx			; save strlen
		dec	edx			; last char
		mov	edi,esi			; edi=src
		add	edi,edx			; edi points to the lats char
		cmp	byte [edi],al		; is it a '/'
		jnz	.no_slash		; nope
		mov	byte [edi],ah		; remove '/'
.no_slash:
		std				; backward scanning
		repne	scasb			; look for first '/'
		cld				; forward scanning
		jnz	.slash_not_found	; 
		inc	edi			; correct edi

.slash_not_found:
		inc	edi			; correct edi
		mov	ebp,esi			; save esi
		mov	esi,edi			; esi=corrected scasb result
		pop	edi			; restore original dest

		mov	edx,esi			; edx=src filename
		mov	esi,edi			; esi=dst dir name
		mov	edi,buf			; edi=tmp buf
		call	full_name		; make full name: "dst_dir/filename"
		mov	esi,ebp			; restore original src

.just_move:
		sys_rename esi, edi
				
		popad
		ret		

;
; ----------------------------- procedures ------------------------------------
;


; edi - tmp buf, esi - dir, edx - file
;
full_name:
		pushad
		call	strcpy
		call	fix_slash
		mov	esi,edx
		call	strcat
		popad
		ret

; edi=file name
; -
fix_slash:
		push	edx
		push	esi
		
		mov	esi,edi
		call	strlen
		dec	edx
		
		mov	ax,0x002F
		cmp	byte [edi+edx],al
		jz	.ok
		
		inc	edx
		mov	word [edi+edx],ax
.ok:
		pop	esi
		pop	edx
		ret
		

; edi = file name
; zero flag = 1 if dir; carry flag=1 if file doesnt exists
is_dir:
		pushad
		
		sys_stat edi,stat_buf
		test	eax,eax
		js	.error
		
		movzx	eax,word [stat_buf.st_mode]
		mov	ebx,40000q
		and	eax,ebx
		cmp	eax,ebx
		clc				; file exists
		jmp	.popit
.error:
		stc				; if file doesnt exist set
						; carry flag
.popit:						
		popad
		ret		


; esi=string
; edx=strlen
strlen:
		push	eax
		push	esi
		
		cld
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


		UDATASEG

stat_buf B_STRUC Stat,.st_mode

buf:		resb	4096
buf_size	equ 	$-buf

		END
