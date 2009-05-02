;Copyright (C) 2001 Joshua Hudson <joshudson@hotmail.com>
;
;$Id: paste.asm,v 1.1 2001/07/20 07:04:18 konst Exp $
;
;hacker's paste
;
;syntax: paste [-d delim] file file [file ...]
;
;return 0 on success, nonzero on error
;
;Can handle 1024 files
;
;Extend, optimize as you like, but please maintain help and error message.

%include "system.inc"

CODESEG

; ebp = argc, next file descriptor
; esi = last file descriptor
; edi = argv[n], file handle
; ebx = buf count

numfiles equ 1024
bufsize equ 1024

START:
	pop	ebp			; argc
	dec	ebp
	jz	.useage			; no args
	xor	esi, esi
	pop	edi			; argv[0]
	mov	byte [delim], __t	; Default delimionator is TAB

.nextarg:
	pop	edi			; get next argument
	cmp	word [edi], '-d'
	je	.setdelim		; delimionator
	sys_open	edi,O_RDONLY
	test	eax,eax
	js	.fail			; failed to open file
	mov	dword [desc+esi], eax
	add	esi, 4
.checkarg:
	dec	ebp
	jnz	.nextarg		; get the next argument
	or	esi, esi
	jz	.useage			; must be at least 1 file
	jmps	.go

.setdelim:
	dec	ebp
	jz	.useage
	pop	edi
	mov	cl, byte [edi]
	mov	byte [delim], cl
	jmps	.checkarg

.useage:
	mov	ecx, useage
	mov	esi, dword [useagel]
	sys_write	STDERR,	ecx, esi
.error:
	xor	edi, edi
	inc	edi
.exit:
	sys_exit	edi

.fail:
	mov	ecx, fail
	mov	esi, dword [faill]
	sys_write	STDERR, ecx, esi
	jmp	.error


.go:				; Begin reading from files
	mov	dword [files], esi
	xor	ebx, ebx
	mov	dword [bufptr], ebx
	xor	ebp, ebp
	mov	edi, dword [desc]
.nextread:
	mov	ecx, dword [desc+ebp]
	or	ecx, ecx
	jz	.nextfile
	mov	eax, char
.readone:
	mov	ecx, char
	xor	edx, edx
	inc 	edx
	sys_read 	edi,ecx,edx	; read next byte
	test	eax, eax
	js	.fail
	jz	.eof
	mov	al, byte [char]
	cmp	al, __n
	je	.nextfile
	call	.pushbuf	; place al on bufer
	jmp	.readone

.eof:
	sub	dword [files], 4
	jz	.done		; zero-out desc
				; eax is zero
	mov	dword [desc + ebp], eax

.nextfile:
	add	ebp, 4
	cmp	ebp, esi
	je	.lastfile
	mov	edi, dword [desc + ebp]
	mov	al, byte [delim]
	call	.pushbuf
	jmp	.nextread

.lastfile:
	mov	al, __n
	call	.pushbuf
	call	.flushbuf
	xor	ebp, ebp
	mov	edi, dword [desc + ebp]
	jmp	.nextread

.done:
	xor	eax, eax	; No need to flush buffer
	sys_exit	eax

; .pushbuf: place al on buffer
.pushbuf:
	mov	ebx, dword [bufptr]
	mov	byte [buf + ebx], al
	inc	ebx
	cmp	ebx, bufsize
	je	.flushbufi
	mov	dword [bufptr], ebx
	ret
.flushbuf:
	mov	ebx, dword [bufptr]
.flushbufi:
	mov	eax, buf
	sys_write	STDOUT, eax, ebx
	xor	ebx,ebx
	mov	dword [bufptr], ebx
	ret

;*** DEBUGGING: NO BUFFER ***
;	mov	byte [buf], al
;	mov	eax, buf
;	mov	ebx, 1
;	sys_write	STDOUT, eax, ebx
;	ret

; THIS IS IN THE CODE SEGMENT
useage	db	"paste [-d delim] file file [file ...]", __n, 0
useagel	dd	38
fail	db	"Unable to read input file", __n, 0
faill	dd	26

UDATASEG

buf	resb bufsize
desc	resd numfiles
bufptr	resd 1
files	resd 1
char	resb 1
delim	resb 1

END

