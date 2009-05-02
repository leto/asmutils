;Copyright (C) 2000 Dmitry Bakhvalov <dl@gazeta.ru>
;
;$Id: cp.asm,v 1.6 2002/02/02 08:49:25 konst Exp $
;
;hackers' cp
;
;syntax: cp [option] source dest, or
;	 cp [option] source... directory
;
;The only supported option by now is -r. Does anyone really use anything
;else anyway? :)
; 
;If someone really feels like he needs more of the original GNU cp's
;options - just ask me or better yet add 'em yourself :)
;
;Send me any feedback,suggestions,additional code, etc.

		%include "system.inc"

		CODESEG

usage_msg	db	"Usage: cp [-r] source dest",__n
_usage_msg_len	equ $-usage_msg
%assign		usage_msg_len _usage_msg_len

%assign		buf_size	0x1000

START:
		pop	ecx			; get argc
		cmp	ecx,byte 3		; must have at least 3 args
		jae	proceed

invalid_args:
		sys_write STDOUT,usage_msg,usage_msg_len
no_more_args:
		sys_exit eax			; exit

proceed:
		pop	eax			; skip argv[0]
		dec	ecx			; dont count argv[0]
		
						; let's test for "-r" option
		pop	ebx

;		cmp	word [ebx],"-R"
;		jz	set_recursive
		cmp	word [ebx],"-r"
		jnz	not_recursive

set_recursive:
		inc	byte [recursive]	; set recursive flag
		dec	ecx			; one argument has gone
		jmp	dont_push

not_recursive:	
		push	ebx			; put our arg back onto the stack
dont_push:		
		dec	ecx			; last argument's index

		xor	eax,eax			;  eax=NULL
		xchg	eax,[esp+ecx*4]		;  argv[last_arg]=NULL
		mov	[dst],eax		;  dst=arv[last_arg]

file_to_dir_loop:		
		pop	edi			; get nex arg
		test	edi,edi			; no more?
		jz	no_more_args
		
		call	is_dir
		jnz	copy_this_file		
		
						; well, we have a dir here
		cmp	byte [recursive],1	; did we specify -r option ?
		jne	file_to_dir_loop	; we have a dir and no -r option
						; so we simply skip this argument

		push	dword [dst]		; push dst	
		push	edi			; push src 
		call	rcopy			; do recursive copy
		pop	eax			; remove function's args
		pop	eax
		jmp	file_to_dir_loop	; go on
		
copy_this_file:		
		push	edi			; save src filename
		mov	edi,[dst]		; edi = destination
		pop	esi			; esi= source
		call	copy			; copy
		jmp	file_to_dir_loop	; go on
		
; copy files
; esi - source file; edi - dest file/dir; ebp=flags
; carry = 1 if error

copy:
		pushad
		
		sys_stat esi,stat_buf
		movzx	edx,word [stat_buf.st_mode]
		test	eax,eax
		jns	.stat_ok
		mov	edx,600q
.stat_ok:

		call	is_dir			; is our dest a dir
		jnz	.just_copy		; it's a file. copy now
		
		push	edx			; save file attr
		push	esi			; save src filename
		mov	edx,esi			; edx=src filename
		mov	esi,edi			; esi=dst dir name
		mov	edi,buf			; edi=tmp buf
		call	full_name		; make full name: "dst_dir/filename"
		pop	esi			; restore src filename
		pop	edx			; restore file attr

.just_copy:		
		sys_open esi,O_RDONLY
		test	eax,eax
		jns	.no_error
		jmp	.error
.no_error:
		mov	esi,eax			; esi - src handle
		sys_open edi,O_WRONLY|O_CREAT|O_TRUNC
		test	eax,eax
		js	.error
		mov	edi,eax			; edi - dst handle
		
.copy_loop:
		sys_read esi,buf,buf_size	; read source
		test	eax,eax
		js	.error
		jz	.no_more_data
		
		mov	ebx,edi			; ebx = dst handle
		mov	edx,eax			; edx = num of bytes
						; ecx already holds buf		
		sys_write			; write it

		cmp	edx,buf_size
		jz	.copy_loop

;		jmp	.copy_loop
.no_more_data:
		sys_close esi			; close src
		sys_close edi			; close dst
		clc				; clear carry bit - all ok
		jmp	.return
.error:		
		stc				; set carry flag - error
.return:		
		popad
		ret		


;
;		recursive copying is a bitch, but what the hell! 
;		we do ASM here :)
;
;
;		yeah, I know. These %defines look somewhat fearsome :)
;
		%define	CALL_FRAME	8
		%define SRC_DIR		(CALL_FRAME+0)
		%define DST_DIR		(CALL_FRAME+4)
		%define HANDLE_SIZE	4
		%define HANDLE_OFFS	(HANDLE_SIZE+0)
		%define DENTS_BUF_SIZE	266
		%define DENTS_BUF_OFFS	(DENTS_BUF_SIZE+HANDLE_OFFS)
		%define BUF_SIZE	2048
		%define BUF_OFFS	(DENTS_BUF_OFFS+BUF_SIZE)
		%define BUF1_SIZE 	2048
		%define BUF1_OFFS	(BUF_OFFS+BUF1_SIZE)
		%define LOCAL_BUFSIZE	(HANDLE_SIZE+DENTS_BUF_SIZE+BUF_SIZE+BUF1_SIZE)
rcopy:
		push	ebp
		mov	ebp,esp
		sub	esp,LOCAL_BUFSIZE

		mov	edi,[ebp+SRC_DIR]		; src must be a dir
		call	is_dir
		jnz	near .error

		mov	edi,[ebp+DST_DIR]		; dst must be a dir too
		call	is_dir
		jz	near .dst_ok
		
		sys_mkdir edi,755q			; create target dir
		test	eax,eax				; if there's a file with sucha name
		js	near .error			; or our mkdir fails we exit anyway
		
.dst_ok:		
		sys_open [ebp+SRC_DIR],O_RDONLY		; opendir(src)
		test	eax,eax
		js	near .error
		
		mov	[ebp-HANDLE_OFFS],eax
		
.next_dentry:		
		lea	ecx,[ebp-DENTS_BUF_OFFS]
		sys_getdents [ebp-HANDLE_OFFS],EMPTY,DENTS_BUF_SIZE
		test	eax,eax
		js	near .error
		jz	near .done
		
		mov	edi,ecx				; edi = buf
		mov	ecx,eax				; ecx = rc
		
.main_loop:
		lea	edx,[edi+10]			; edx = filename
		mov	ax,0x002E
		cmp	byte [edx],al			; starts with "." ?
		jnz	.without_dots			; nope
		cmp	byte [edx+1],ah			; null?
		jz	.skip				; skip "." dir
		cmp	word [edx+1],ax			; ".." dir
		jz	.skip				; skip it
	    
.without_dots:
		push	edi				; save buf ptr

		lea	edi,[ebp-BUF1_OFFS]		; tmp buffer
		push	edi				; save for later use (.its_a_file)
		mov	esi,[ebp+DST_DIR]		; dst dir
							; edx hold filename
		call	full_name			; create fullname

		
		lea	edi,[ebp-BUF_OFFS]		; tmp buffer
		push	edi				; save edi for later use (.its_a_file)
		mov	esi,[ebp+SRC_DIR]		; src dir
							; edx hold filename
		call	full_name			; create fullname

							; edi holds tmp buffer
		call	is_dir
		jnz	.its_a_file
		
		pop	eax				; remove saved edi's. we dont need 'em
		pop	eax
		
		pushad					; call ourself
		lea	eax,[ebp-BUF1_OFFS]		; C-style calling convention
		push	eax				; second arg first
		lea	eax,[ebp-BUF_OFFS]
		push	eax				; then goes the first one
		call	rcopy
		pop	eax				; remove function's args
		pop	eax
		popad
		jmp	.next

.its_a_file:
		; copy the damn file
		pop	esi				; get saved addreses
		pop	edi
		call	copy

.next:
		pop	edi				; restore buf ptr
.skip:
		xor	eax,eax
		mov	ax,[edi+8]			; eax=rec_len
		
		add	edi,eax
		sub	ecx,eax
		
		jnz	.main_loop
		jmp	.next_dentry
		
.done:
		mov	ebx,[ebp-HANDLE_OFFS]
		sys_close

.error:		
		add	esp,LOCAL_BUFSIZE
		pop	ebp
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
		mov	ebx,S_IFDIR
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
    		mov     edx,esi
    		dec     edx
.do_strlen:
                inc     edx
                cmp     [edx],byte 0
                jnz     .do_strlen
                sub     edx,esi
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

dst		resd	1
recursive	resb	1

buf		resb	buf_size

stat_buf B_STRUC Stat,.st_mode

		END
