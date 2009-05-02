;Copyright (C) 2001 Tiago Gasiba <ee97034@fe.up.pt>
;
;$Id: whoami.asm,v 1.2 2002/03/14 18:25:57 konst Exp $
;
;hacker's whoami
;
;syntax: whoami
;
;TODO:
;        - UID not found in /etc/passwd
;        - read() doesn't read all file at once
;        - optimize SPEED and SIZE (algorithm??)

%include "system.inc"

%assign	BUFFERLEN	20
%assign	MAXSTRLEN	200

%assign	STACK_FRAME_SIZE	16

%define	FSIZE		esp+12
%define	FD		esp+8
%define	UID		esp+4
%define	BEG_DATA	esp

CODESEG

START:
	mov	ebp,esp				;create stack frame

	_sub	esp,STACK_FRAME_SIZE
;	sys_brk
	mov	dword [BEG_DATA],_end		;save beg. of data

	sys_getuid
	mov	[UID],eax

	sys_open file,O_RDONLY
	test	eax,eax
	js	near .exit
	mov	[FD],eax			;save file descrp.
	
	sys_lseek [FD],0,SEEK_END
	mov	[FSIZE],eax

	sys_lseek [FD],0,SEEK_SET

	mov	eax,[BEG_DATA]
	add	eax,[FSIZE]
	inc	eax
	sys_brk	eax
	mov	eax,[BEG_DATA]
	mov	byte [eax],__n

	mov	eax,[BEG_DATA]
	inc	eax
	sys_read [FD],eax,[FSIZE]
						;  FIXME FIXME FIXME
						; have we read all???
	
	sys_close [FD]

	; search for name
	cld
	mov	edi,[BEG_DATA]
	mov	ecx,[FSIZE]

.outro:
	mov	al,':'
times 2	repne	scasb
	mov	esi,edi
	repne	scasb
	dec	edi
	mov	byte [edi],0
	call	ascii2uint
	cmp	eax,[UID]
	je	.encontrado
	mov	al,__n
	repne	scasb
	jmps	.outro

.encontrado:
	std
	mov	al,__n
	mov	edi,esi
	repne	scasb
	inc	edi
	inc	edi
	push	edi
	mov	al,':'
	cld
	repne	scasb
	dec	edi
	mov	word [edi],0x000a
	pop	esi

	call	strlen

	sys_write STDOUT,esi,eax
.exit:
	mov	esp,ebp				; destroy stack frame
	sys_exit 0

;--------------------------------------------------
; Function    : ascii2uint
; Description : converts an ASCIIZ number to uint
; Needs       : esi - pointer to string
; Gives       : eax - converted number
; Destroys    : eax
;--------------------------------------------------
ascii2uint:
	pusha
	_mov	eax,0			; initialize sum
	_mov	ebx,0			; zero digit
.repete:
	mov	bl,[esi]		; get digit
	test	bl,bl
	jz	.exit			; are we done ?
	and	bl,~0x30		; ascii digit -> bin digit
	imul	eax,10			; prepare next conversion
	add	eax,ebx
	inc	esi			; next digit
	jmps	.repete
.exit:
	mov	[esp+28],eax		; save eax
	popa
	ret

;-----------------------------------------------------
; function  : strlen
; objective : returns the length of a string
; needs     : esi - pointer to stringz
; returns   : eax - string length
; destroys  : eax
;-----------------------------------------------------
strlen:
	pusha
	cld
	_mov	ecx,MAXSTRLEN
	mov	edi,esi
	_mov	eax,0
	repne	scasb
	_mov	eax,MAXSTRLEN
	sub	eax,ecx
	dec	eax
	mov	[esp+28],eax
	popa
	ret

file	db	"/etc/passwd",0

UDATASEG					; to be able to brk()

END
