;Copyright (C) 1999-2000 Konstantin Boldyshev <konst@linuxassembly.org>
;
;$Id: mkdir.asm,v 1.3 2000/02/10 15:07:04 konst Exp $
;
;hackers' mkdir/rmdir
;
;0.01: 05-Jun-1999	initial release
;0.02: 17-Jun-1999	size improvements
;0.03: 04-Jul-1999	fixed bug with 2.0 kernel, size improvements
;0.04: 29-Jan-2000	-m & -p support
;
;syntax: mkdir [OPTION] DIRECTORY ...
;	 rmdir DIRECTORY...
;
;-m	set permission mode (only octal number)
;-p	create parent directories as needed
;
;example: mkdir -p -m 700 this/is/a/very/long/and/useless/directory/tree
;
;only octal mode strings are suppoted (f.e. 750)
;by default directories are created with permissions of 755
;
;returns last error number

%include "system.inc"

%define MKDIR 0
%define RMDIR 1

CODESEG

;
;ebp: -p flag
;

START:
	pop	eax
	dec	eax
	jnz	.begin
.exit:
	sys_exit eax

.begin:
	pop	esi
.n1:				;set edi to argv[0] eol
	lodsb
	or 	al,al
	jnz	.n1
	mov	edi,esi

	_mov	ecx,755q
	xor	ebp,ebp

.next_arg:
	pop	esi
	push	esi

	cmp	word [esi],"-p"
	jnz	.check_m
	inc	ebp
	pop	esi
	jmp	short .next_arg

.check_m:
	cmp	word [esi],"-m"
	jnz	.next_file

	pop	esi
	pop	esi
	or	esi,esi
	jz	.exit

	mov	edx,esi
	xor	ecx,ecx
	xor	eax,eax
	_mov	ebx,8

.next:
	mov	cl,[esi]
	sub	cl,'0'
	jb	.done
	cmp	cl,7
	ja	.done
	mul	bl
	add	eax,ecx
	inc	esi
	jmp short .next

.done:
	cmp	edx,esi
	jz	.exit
	or	eax,eax
	jz	.exit

	mov	ecx,eax
	jmp	short .next_arg
	
.next_file:
	pop	ebx
	or	ebx,ebx
	jz	.exit
	cmp	word [edi-6],"rm"
	jnz	.mkdir
	sys_rmdir
	jmp short .next_file

.mkdir:
	push	edi

	mov	dl,1
	or	ebp,ebp
	jz	.call
	
	mov	esi,ebx
	jmp	short .check

.next_dir:
	mov	edi,esi
	mov	[edi], byte 0
.call:
	sys_mkdir
	or	edx,edx
	jnz	.done_mk
	mov	[edi], byte '/'

	inc	esi
.check:
	xor	edx,edx
	mov	edi,esi
	mov	al,'/'
	call	strchr
	jc	.next_dir
	inc	edx
	cmp	esi,edi
	jnz	.next_dir
.done_mk:
	pop	edi
	jmp	short .next_file

;
;carry set if character found
;

strchr:
	push	eax
	mov	ah,al
	clc
.next:
	lodsb
	or	al,al
	jz	.return
	cmp	al,ah
	jnz	.next
	stc
.return:
	dec	esi
	pop	eax
	ret

END
