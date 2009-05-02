;Copyright (C) 2001 by Joshua Hudson
;
;$Id: cut.asm,v 1.3 2002/02/02 08:49:25 konst Exp $
;
;hacker's cut
;
;Usage: cut [-z] [-d delim] [-c start[-end]] [-f field,field] [filename]
;	-z			No delimionater in multi-field output
;	-d delim		Sets the field delimionater to :
;	-c start[-end]		Process only these characters
;	-f field[,field ...]	Echo only these fields
;
;Cut applies first the c than the f options.
;With no options, cut will act like cat (but much slower).
;Supports 4gig line length, 255 fields.

%include "system.inc"

CODESEG

START:
	pop	ebp
	pop	ebp		; Program name
	mov	[delimionator], byte __t
nextarg:
	pop	ebp
	or	ebp, ebp
	jz	near use_stdin
	cmp	[ebp], word '-c'
	je	option_c
	cmp	[ebp], word '-z'
	je	option_z
	cmp	[ebp], word '-d'
	je	option_d
	cmp	[ebp], word '-f'
	je	near option_f
	cmp	[ebp], word '--'
	je	near dashdash
	jmp	nextfile

option_z:
	mov	[usedelim], byte 1	; No delimionator in offset
	jmps	nextarg

option_c:
	add	ebp, byte 2
	cmp	[ebp], byte 0
	jne	opc_noa
	pop	ebp
	or	ebp, ebp
	jz	near fail
opc_noa	call	atoi
	xor	ecx, ecx
	inc	ecx
	mov	[firstchar], ebx
	mov	[lastchar], ecx		; Handle -c position (one char only)
	cmp	[ebp], byte '-'		; Check for start-end
	jne	nextarg
	inc	ebp
	call	atoi
	sub	ebx, [firstchar]
	js	near fail
	inc	ebx
	mov	[lastchar], ebx
	jmp	nextarg

option_d:
	add	ebp, byte 2
	cmp	[ebp], byte 0
	jne	opd_noa
	pop	ebp
	or	ebp, ebp
	jz	near fail
opd_noa call	tchar
	mov	[delimionator], al
	jmp	nextarg

option_f:
	mov	[usefieldmode], byte 1
	add	ebp, byte 2
	cmp	[ebp], byte 0
	jne	another_field
	pop	ebp
	or	ebp, ebp
	jz	near fail
another_field:
	call	atoi
	cmp	ebx, 255
	jg	badfield
	mov	[fields + ebx], byte 1	; Nonzero if not invalid 0 field
badfield:
	inc	ebp
	cmp	[ebp - 1], byte ','
	je	another_field
	jmp	nextarg

dashdash:
	pop	ebp
	or	ebp, ebp
	jnz	nextfile
use_stdin:
	push	ebp		; Zero, detect last file later
stdinfile:
	_mov	eax, STDIN
	jmps	gotfile

nextfile:
	cmp	[ebp], word 0x002D	; Dash, read from stdin
	je	stdinfile
	sys_open	ebp, O_RDONLY
	test	eax, eax
	js	near fail
gotfile:
	mov	[filehandle], eax
	mov	ebp, outbuf
	mov	edx, ebx	; This will cause fillbuf on first read

newline:
;*** Phase 1: ignore leading characters if -c mode.
	mov	esi, [firstchar]
	or	esi, esi
	jz	noskip
	dec	esi
	jz	noskip
	mov	[wrotefield], byte 0
skip:
	call	_read		; Skip next char until [firstchar] skipped
	cmp	al, __n
	je	newline
	dec	esi
	jnz	skip

;*** Phase 2: count fields and characters remaining until end
noskip:
	mov	[wrotefield], byte 0
	xor	esi, esi
	inc	esi		; Current field
	mov	edi, [lastchar] ; Characters to count
nextchar:
	call	_read
	cmp	al, __n
	je	gotnewline
	cmp	[usefieldmode], byte 0
	je	accept
	cmp	al, [delimionator]
	je	endfield
	cmp	esi, 255
	jg	waitend
	cmp	[fields + esi], byte 0
	je	reject
	cmp	[wrotefield], byte 1
	jne	accept
	push	eax
	mov	al, [delimionator]
	call	_write
	pop	eax
accept:
	mov	[wrotefield], byte 2
	call	_write
reject:	
	dec	edi
	jnz	nextchar	; Reached char limit?
	jmp	waitend

endfield:
	inc	esi
	cmp	[usedelim], byte 1
	je	reject
	cmp	[wrotefield], byte 2
	jne	reject
	mov	[wrotefield], byte 1	; On next to write, first write delim
	jmps	reject

;*** Phase 3: wait for a newline
waitend:
	call	_read
	cmp	al, __n
	jne	waitend
gotnewline:
	call	_write
	jmp	newline

;Flush the buffer and terminate:
done:	mov	edx, ebp
	sub	edx, outbuf
	jz	empty
	sys_write	STDOUT, outbuf
empty:	mov	ebx, [filehandle]
	xor	bl, bl
do_exit:
	sys_exit
fail:	mov	bl, 1
	jmps	do_exit

; This routine reads from the input file.
; Caller will preserve ebx, edx for us.
_read:
	cmp	ebx, edx
	jl	getfrombuf
fillbuf:
	mov	ebx, [filehandle]
	_mov	ecx, buf
	_mov	edx, bufsize
	sys_read
	test	eax, eax
	jc	done
	jz	done
	mov	ebx, buf
	xchg	eax, edx
	add	edx, buf
getfrombuf:
	mov	al, [ebx]
	inc	ebx
	ret

_write:
	mov	[ebp], al
	inc	ebp
	cmp	ebp, outbuf + bufsize
	jne	noflushbuf
	push	ebx
	push	edx
	sys_write	STDOUT, outbuf, bufsize
	pop	edx
	pop	ebx
noflushbuf:
	ret

; Subroutine atoi.  Convert string [ebp] to number
; Adjust [ebp] to end of number, return number in ebx, may modify all regs
atoi	xor	eax, eax
	xor	ecx, ecx
atoi_next:
	mov	cl, [ebp]
	sub	cl, '0'
	jc	atoi_done
	cmp	cl, 9
	jg	atoi_done
	inc	ebp
	xor	edx, edx
	mul	dword [ten]
	add	eax, ecx
	jmps	atoi_next
atoi_done:
	xchg	eax, ebx
	ret

ten	dd	10

; Subroutine tchar: convert a string to a character using some char conversion
; Will process \\, \xxx, \a, \b, \t, \r, \n
tchar	mov	al, [ebp]
	inc	ebp
	cmp	al, '\'
	jne	retnow
	mov	al, [ebp]
	cmp	al, 'a'
	je	tc_a
	cmp	al, 'b'
	je	tc_b
	cmp	al, 't'
	je	tc_t
	cmp	al, 'r'
	je	tc_r
	cmp	al, 'n'
	je	tc_n
	cmp	al, '0'
	jl	retnow
	cmp	al, '7'
	jg	retnow
; This is \xxx
	mov	cl, 3
	sub	al, '0'
	mov	ah, al
	inc	ebp
	mov	al, [ebp]
	sub	al, '0'
	jc	tc_xxx
	cmp	al, 7
	jg	tc_xxx
	inc	ebp
	shl	ah, cl
	xor	ah, al		; Could use add, but xor is faster
	mov	al, [ebp]	; Might have looped prev, but compress better
	sub	al, '0'		; if done this way.
	jc	tc_xxx
	cmp	al, 7
	jg	tc_xxx
	inc	ebp
	shl	ah, cl
	xor	ah, al
tc_xxx	mov	al, ah		; Got the data
retnow	ret
tc_a	mov	al, 7
	ret
tc_b	mov	al, 8
	ret
tc_t	mov	al, __t
	ret
tc_r	mov	al, 13
	ret
tc_n	mov	al, __n
	ret

DEBUG	pusha
	sys_write	STDOUT, DEBUGMSG, 6
	popa
	ret
DEBUGMSG	db	"DEBUG", __n

UDATASEG

bufsize		equ	2048
wrotefield	resb	1	; Is the first field written?
usefieldmode	resb	1	; Scan fields
delimionator	resb	1	; The delimionator byte
usedelim	resb	1	; Display delim on output
fields		resb	256	; Supports 256 fields
firstchar	resd	1	; First char of line to process
lastchar	resd	1	; Number of chars to process
filehandle	resd	1	; The handle of the open file
buf		resb	bufsize	; The buffer
outbuf		resb	bufsize ; The output buffer

END
