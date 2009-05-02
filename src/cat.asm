;Copyright (C) 1999 Konstantin Boldyshev <konst@linuxassembly.org>
;
;$Id: cat.asm,v 1.5 2004/01/20 05:26:33 konst Exp $
;
;hackers' cat
;
;syntax: cat [file...]
;
;returns error count
;
;0.01: 05-Jun-1999	initial release
;0.02: 17-Jun-1999	fixed bug with 2.0 kernel, size improvements
;0.03: 04-Jul-1999	fixed more bugs (^D, kernel 2.0), buffered io
;0.04: 14-Mar-2002	squeezed one byte :-) (KB)
;0.05: 15-Jan-2004	added GNU extensions (with BIG_CAT) (JH)

%include "system.inc"
%define BIG_CAT

CODESEG

;BUFSIZE > 8192 doesn't make sense, BUFSIZE < 8192 results in slower perfomance

%assign	BUFSIZE	0x2000

%define SHOW_TAB 1
%define SHOW_END 2
%define SHOW_NP  4
%define SQUEEZE  8
%define NUMBER  16
%define NUMB_NB 32

;ebp	-	current handle of file to read
;edi	-	return code

START:
	_mov	edi,0
	_mov	ebp,STDIN	;file handle (STDIN if no args)
	pop	ebx
	dec	ebx
	pop	ebx
	jz	near	next_file.read_loop	;if no args - read STDIN
%ifdef BIG_CAT
	;mov	ah, 0
.getopt	pop	ebx
	or	ebx, ebx
	jz	.null
	mov	esi, ebx
	lodsb
	cmp	al, '-'
	jne	.dofile		; Not an option
	cmp	[esi], byte 0
	je	.dofile
.subopt	lodsb
	cmp	al, 0
	je	.getopt
	cmp	al, 'A'
	jne	.nA
	or	ah, byte SHOW_TAB | SHOW_END | SHOW_NP
.nA	cmp	al, 'b'
	jne	.nb
	or	ah, byte NUMB_NB | NUMBER
.nb	cmp	al, 'e'
	jne	.ne
	or	ah, byte SHOW_NP | SHOW_END
.ne	cmp	al, 'E'
	jne	.nE
	or	ah, byte SHOW_END
.nE	cmp	al, 'n'
	jne	.nn
	or	ah, byte NUMBER
.nn	cmp	al, 's'
	jne	.ns
	or	ah, byte SQUEEZE
.ns	cmp	al, 't'
	jne	.nt
	or	ah, byte SHOW_TAB | SHOW_NP
.nt	cmp	al, 'T'
	jne	.nT
	or	ah, byte SHOW_TAB
.nT	cmp	al, 'v'
	jne	.nv
	or	ah, byte SHOW_NP
.nv	cmp	al, '-'
	jne	.subopt
	mov	[opt], ah
	jmps	next_file

.null	push	ebx
	mov	[opt], ah
	jmps	next_file.read_loop
.dofile	push	ebx
	mov	[opt], ah
%endif

next_file:
	pop	ebx		;pop filename pointer
	or	ebx,ebx
	jz	.exit		;exit if no more agrs

; open O_RDONLY
%ifdef	BIG_CAT
	_mov	ebp, STDIN
	cmp	[ebx], word '-'
	je	.read_loop
%endif

	sys_open EMPTY,O_RDONLY
	xchg	ebp,eax
	test	ebp,ebp		;have we opened file?
	jns	.read_loop	;yes, read it
.error:
	inc	edi		;record error
	jmps	next_file	;try next file

.read_loop:
%ifdef BIG_CAT
	test	[opt], byte 255
	jnz	large_rt
%endif
	sys_read ebp,buf,BUFSIZE
	test	eax,eax
	js	.error
	jz	next_file
;	jz	.close_file
	sys_write STDOUT,EMPTY,eax	;write to STDOUT
	jmps	.read_loop
;.close_file:
;	sys_close; ebp			;close current file
;
;	jmp short next_file		;try next file

.exit:
%ifdef BIG_CAT
	mov	edx, [outct]
	or	edx, edx
	jz	.noflush
	mov	ecx, outbuf
	sys_write	STDOUT
.noflush:
%endif
	sys_exit edi
%ifdef BIG_CAT
large_rt:				; The full routine that
	mov	esi, buf		; processes all options :)
.nextc	call	getc
	js	near	next_file
	mov	ah, [opt]		; Important!
	cmp	al, __n
	je	.lf
	cmp	al, __t
	je	.tab

	test	ah, SHOW_NP
	jz	.print
	cmp	al, 128
	jb	.nometa
	push	eax
	mov	al, 'M'			; M- formatting
	call	putc
	mov	al, '-'
	call	putc
	pop	eax
	and	al, 127
.nometa	cmp	al, 32	
	jb	.np
.print	call	putc			; Unformatted
	jmps	.nextc
.tab	test	ah, SHOW_TAB
	jz	.print
.np	push	eax			; ^ formatting
	mov	al, '^'
	call	putc
	pop	eax
	add	al, '@'
	jmps	.print

.lf	test	ah, byte SQUEEZE	; Linefeed (most complex)
	jz	.lfok			; Squeeze it out?
	cmp	[last], byte __n
	jne	.lfok
	cmp	[last2], byte __n
	jne	.lfok
	jmps	.nextc
.lfok	test	ah, SHOW_END		; Show a dollar sign?
	jz	.nod
	mov	bl, [last]	; Preserve last
	mov	al, '$'
	call	putc
	mov	[last], bl	; Restore last
	mov	al, __n
.nod	test	ah, NUMB_NB
	jz	.ctlf
	cmp	[last], al
	jne	.ctlf
	inc	byte [blkct]
.ctlf	call	putc
	dec	byte [blkct]		; Number this line!
	jmp	.nextc

getcok:
	mov	esi, ecx
	mov	[incnt], eax
getc:
	dec	dword	[incnt]
	js	.underflow
	lodsb
	ret
.underflow:
	sys_read	ebp, buf, BUFSIZE
	or	eax, eax
	ja	getcok
	dec	eax
	ret

putc:
	push	edi

	test	ah, NUMBER
	jz	.nonumber
	test	[blkct], byte 255
	jnz	.nonumber

; Number this one
	mov	ah, [last]
	push	eax
	inc	byte	[blkct]
	mov	eax, [count]
	inc	eax
	mov	[count], eax
	_mov	ebx, 10
	xor	edi, edi
.divide	xor	edx, edx		; Cvt to digits on stack
	div	ebx
	add	dl, byte '0'
	push	edx
	inc	edi
	or	eax, eax
	jnz	.divide
	_mov	ebx, 6
	sub	ebx, edi
	jna	.pop
.space	mov	al, ' '
	push	ebx
	call	putc
	pop	ebx
	dec	ebx
	jnz	.space
.pop	pop	eax			; Send them
	call	putc
	dec	edi
	jnz	.pop
	mov	al, ' '
	call	putc
	mov	al, ' '
	call	putc
	pop	eax
	mov	[last], ah
	
.nonumber:
	mov	edi, [outct]
	add	edi, outbuf
	stosb
	inc	dword [outct]
	xchg	al, [last]
	mov	[last2], al
	cmp	edi, outbuf + BUFSIZE
	jb	.nof
	sys_write	STDOUT, outbuf, BUFSIZE
	xor	eax, eax
	mov	[outct], eax
.nof	pop	edi
	ret
%endif

UDATASEG

buf	resb	BUFSIZE
%ifdef BIG_CAT
outbuf	resb	BUFSIZE
incnt	resd	1
outct	resd	1
count	resd	1
opt	resb	1
blkct	resb	1
last	resb	1
last2	resb	1
%endif

END
