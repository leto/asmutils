;Copyright (C) 2001 by Joshua Hudson
;
; $Id: tr.asm,v 1.3 2002/06/24 16:51:19 konst Exp $
;
; May be used under GPL
;
; asmutils tr
;
; Usage: tr [-s] [-d] string1 [string2]
;	-s	merge duplicates in output
;	-d	delete occurences of string1
;
;	Strings are in the form of { char | '[' {low '-' high} ']' }*
;
; For reliability always quote string1 and string2
; This program can be classified as being almost GNU compliant
; (string1 is not required if -s is given, but needed in this version).

%include "system.inc"

CODESEG

START:

;*********************** Process Arguments **************************
	pop	ebp
	pop	ebp		; Program name
	xor	eax, eax	; al=delete, ah=merge
getString1:
	dec	edi
	pop	ebp
	or	ebp, ebp
	jz	fail
	mov	bl, [ebp]
	or	ebp, ebp
	jz	fail
	cmp	[ebp], word '-s'
	je	setmerge
	cmp	[ebp], word '-d'
	jne	gotString1
	inc	al
	jmps	getString1
setmerge:
	inc	ah
	jmps	getString1
gotString1:
	xor	ebx, ebx
	mov	[merge], ah
	mov	[delete], al
	or	al, al
	jz	replaceset

; Set up indexes to 'delete' mode
deleteset:
	mov	[index+ebx], al		; Nonzero
	inc	bl
	jnz	deleteset

; Process ebp as string1
	mov	esi, source
	push	esi
	call	procstr			; Returns length in eax
	pop	esi
	
	xor	ebx, ebx
	xor	cl, cl
	or	eax, eax
scandelnext:
	jz	processextra
	mov	bl, [esi]
	mov	[index+ebx], cl		; Zero, delete this char
	inc	esi
	dec	eax
	jmps	scandelnext

fail:					; Failed: exit 1
	xor	bl, bl
	inc	bl
	jmp	do_exit

; Set up indexes to 'replace' mode
replaceset:
	mov	[index+ebx], bl
	inc	bl
	jnz	replaceset

;Process ebp as string1
	mov	esi, source
	call	procstr
	pop	ebp
	push	eax
;Process ebp as string2
	or	ebp, ebp
	jz	fail
	mov	esi, dest
	call	procstr
;They must be the same length!
	pop	ebp
	cmp	ebp, eax
	jne	fail
	or	eax, eax
	jz	processextra

;Load them into indexes
	mov	esi, source
	mov	edi, dest
	xor	ebx, ebx
indexload:
	mov	bl, [esi]
	inc	esi
	mov	cl, [edi]
	inc	edi
	mov	[index+ebx], cl
	dec	eax
	jnz	indexload

processextra:		; Process possible infile & outfile
	_mov	edi, STDIN	; Input = stdin
	_mov	ebp, STDOUT	; Output = stdout

;********* Begin read/write loop here *********
replace:
	sys_read	edi, this, 1
	or	eax, eax
	jz	done
	xor	ebx, ebx
	cmp	[delete], byte 0
	jne	checkdelete
	mov	bl, [this]
	mov	al, [index+ebx]
	jmps	_write

checkdelete:
	mov	bl, [this]
	mov	cl, [index+ebx]
	or	cl, cl
	jz	replace
	mov	al, bl
_write:
	cmp	[merge], byte 0
	je	nomerge
	cmp	al, [last]
	je	replace
nomerge:
	mov	[last], al
	sys_write	ebp, last, 1
	jmps	replace

done:
	xor	bl, bl
do_exit:
	sys_exit

;********** Two-pass string converter **********
; string in ebp, final dest in esi, bufsize=256, return size in eax
; not required to preserve ANY registers
procstr:
	xor	eax, eax
	xor	ecx, ecx	; ecx = 257
	inc	ch
	inc	cl
	mov	edi, buf-1	; 256 byte temporary buffer
;Scan into temproary buffer, counting size, substuting \, and
;deleteing trailing null
phase1:
	mov	dl, [ebp]
	inc	edi
	inc	ebp
	inc	eax
	dec	ecx
	jz	phase2
	or	dl, dl
	jz	phase2
	cmp	dl, '\'
	je	slash
	mov	[edi], dl
	jmps	phase1
slash:
	; Substute \xxx (octal), \n, \r, \t, \a, \b, \\
	mov	dl, [ebp]
	inc	ebp
	or	dl, dl
	jz	phase2
	cmp	dl, 'n'
	je	slashn
	cmp	dl, 'r'
	je	slashr
	cmp	dl, 't'
	je	slasht
	cmp	dl, 'b'
	je	slashb
	cmp	dl, 'a'
	je	slasha

;Translate \xxx (octal)
	call	chkdig		; dl = [ebp] already
	jc	gotone		; Invalid or slash, so append
	mov	dh, dl
	call	readdig
	jc	gotit		; End of octal
	inc	ebp
	shl	dh, 3
	or	dh, dl
	call	readdig
	jc	gotit		; End of octal
	inc	ebp
	shl	dh, 3
	or	dh, dl
	jmps	gotit		; Limit of 3 octal
gotone	mov	dh, dl
	jmps	gotit
	
slashn	mov	dh, 10		; Newline
	jmps	gotit
slashr	mov	dh, 13		; Return
	jmps	gotit
slasht	mov	dh, __t		; Tab (what char?)
	jmps	gotit
slashb	mov	dh, 8		; Backspace
	jmps	gotit
slasha	mov	dh, 7		; Alarm
gotit	mov	[edi], dh
	jmp	phase1

phase2:		; Now translate [Low-High]
	mov	edi, buf
	xchg	ecx, eax	; Copy the transport count (will use loop)
	xor	edx, edx	; edx = 256
	inc	dh
	xor	eax, eax	; Final size counter
phase2a:
	mov	dl, [edi]
	inc	edi
	cmp	dl, '['
	jne	noexpand
	cmp	[edi+1], byte '-'
	jne	noexpand
	cmp	[edi+3], byte ']'
	jne	noexpand

;Found [Low-High]: expand in copy
	mov	bl, [edi]
	mov	bh, [edi+2]
	add	edi, 4
	cmp	bl, bh
	jle	noxchg
	xchg	bl, bh
noxchg	mov	[esi], bl
	inc	eax
	inc	esi
	dec	edx
	jz	overflow
	inc	bl
	cmp	bl, bh
	jle	noxchg
	jmps	expanded

noexpand:
	mov	[esi], dl
	dec	edx
	jz	overflow
	inc	eax
	inc	esi
expanded:
	loop	phase2a
overflow:
	dec	eax		; eax = count
	ret			; always one to high at this time

; Readdig: used by procstr in octal mode
; Set carry flag if not a digit, Otherwise, inc ebp
; Return object in dl, [ebp] is not zero
readdig	mov	dl, [ebp]
chkdig	cmp	dl, '0'
	jl	notdig
	cmp	dl, '7'
	jg	notdig
	sub	dl, '0'
	ret
notdig	stc
	ret


UDATASEG

merge	resb	1
delete	resb	1
last	resb	1
this	resb	1
index	resb	256
source	resb	256
dest	resb	256
buf	resb	256
overrun	resb	4	; Prevent buf overrun (max of this size in buf!)

END
