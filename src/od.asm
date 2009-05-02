;Copyright (C) 2001 Joshua Hudson <joshudson@hotmail.com>
;
;$Id: od.asm,v 1.1 2001/07/30 04:49:57 konst Exp $
;
;Usage: od [-cox] [file]
;	xd [file]
; -c	produce a character dump
; -o	produce an octal dump
; -x	produce a hexidecimal dump
;
; Removed -d option for a decimal dump (that would require a LOT of code).
; Otherwise, I think this is standard/POSIX od
;
; This code could be considerably optimized by using function pointers.
; Observe that .oct_cvt and .hex_cvt are almost exactly the same.

%include "system.inc"

; Dump type macros
octal_dump	equ 0
char_dump	equ 1
hex_dump	equ 2

CODESEG

START:
	pop	ebp		; Argc
	pop	ebx		; Program Name

; If we are called as xd, behave as od -x for HP-UX compatibility
	dec	ebx
.nextxd:
	inc	ebx
	cmp	byte [ebx], byte 0
	jne	.nextxd
	cmp	byte [ebx - 2], 'x'
	jne	.nextarg
	mov	[type], byte hex_dump
.nextarg:			; Process all arguments
	dec	ebp
	jz	.dump
	pop	ebx		; Argv n
	cmp	word [ebx], '-o'
	je	.od
	cmp	word [ebx], '-c'
	je	.cd
	cmp	word [ebx], '-x'
	je	.xd
	sys_open	ebx, O_RDONLY	;Not an option, so open it
	test	eax, eax
	js	.error
	mov	[input], eax
	jmps	.nextarg

.od	mov	byte [type], octal_dump
	jmps	.nextarg
.cd	mov	byte [type], char_dump
	jmps	.nextarg
.xd	mov	byte [type], hex_dump
	jmps	.nextarg

.dump	cmp	byte [type], char_dump
	jne	.dump1
.dumpA	call	.read
	call	.char_cvt
	jmps	.dumpA
.dump1	cmp	byte [type], octal_dump
	jne	.dump2
.dumpB	call	.read
	call	.oct_cvt
	jmps	.dumpB
.dump2	call	.read
	call	.hex_cvt
	jmps	.dump2

.error	_mov	ecx, errln
	_mov	edx, errsize		; Length of error message
	sys_write	STDERR		; Error message
	sys_exit	1		; Exit now

.read:
	_mov	ecx, inbuf
	_mov	edx, inbuflen
	_mov	ebx, [input]
	sys_read	ebx, ecx, edx
	test	eax, eax
.rela	js	.error
	je	.eof
	mov	[amt], eax
	ret

.writebuf:
	_mov	ecx, outbuf
	_mov	edx, [outcnt]
	sys_write	STDOUT
	test	eax, eax
	js	.rela
	xor	eax, eax
	mov	[outcnt], eax
	ret

.write	_mov	ebx, [outcnt]
	mov	[outbuf + ebx], al
	inc	ebx
	mov	[outcnt], ebx
	cmp	al, __n
	je	.writebuf
	ret

.eof	mov	eax, [posn]
	cmp	byte [type], hex_dump
	jne	.eof1
	mov	cl, 32
	call	.hexdig
	jmp	.exit
.eof1	mov	cl, 21
	call	.od_dword
.exit	mov	al, __n
	call	.write
	sys_exit	0

;*** CHARACTER DUMP
.char_cvt:
	xor	edi, edi
.char_cvt_nl:
	_mov	eax, [posn]
	add	eax, edi
	push	eax
	and	al, 15
	jnz	.ccnohead
	mov	cl, 21
	pop	eax
	call	.od_dword
	push	eax		; So we do not corrupt stack
.ccnohead:			; Smaller than jmps .ccdumpone
	pop	eax
.ccdumpone:
	_mov	al, [inbuf + edi]
	cmp	al, ' '
	jl	.checkspc
	cmp	al, 126 	; ~, last printable char
	jg	.odchar
	push	eax		; Printable, so dump _c__
	mov	al, ' '
	call	.write
	pop	eax
	call	.write
	mov	al, ' '
	call	.write
	mov	al, ' '
	call	.write
.ccdonewith:
	inc	edi		; Increment buffer
	cmp	edi, [amt]
	je	.char_line
	_mov	eax, edi
	and	al, byte 15
	or	al, al
	jnz	.ccdumpone

.char_line:
	mov	al, __n
	call	.write
	cmp	edi, [amt]
	jne	.char_cvt_nl
	_mov	eax, [posn]
	add	eax, edi
	mov	[posn], eax
	ret

.checkspc:			; Check for \c
	_mov	esi, list
	cmp	al, __n
	je	.ch_newl
	cmp	al, __t
	je	.ch_tab
	cmp	al, 10		; \r
	je	.ch_rtn
	cmp	al, 0
	je	.ch_spec
	cmp	al, 12		; \f
	je	.ch_formfeed
	cmp	al, 8		; \b
	je	.ch_backspace

.odchar:			; dump al as \xxx
	and	eax, 255	; Trim off high bits
	push	eax		; Save on stack
	mov	al, '\'		; \
	call	.write
	pop	esi
	mov	eax, esi	; Top 2 bits
	and	esi, 3Fh	; Trim off top bits
	shr	eax, 6
	add	al, '0'
	call	.write
	mov	eax, esi	; Next 3 bits
	and	esi, 7h
	shr	al, 3
	add	al, '0'
	call	.write
	mov	eax, esi
	add	al, '0'		; Last 3 bits
	call	.write
	jmp	.ccdonewith

.ch_newl	add	esi, byte 12
		jmps	.ch_spec
.ch_tab		add	esi, byte 20
		jmps	.ch_spec
.ch_rtn		add	esi, byte 16
		jmps	.ch_spec
.ch_formfeed	add	esi, byte 8
		jmps	.ch_spec
.ch_backspace	add	esi, byte 4

.ch_spec:
	mov	ah, 4
.ch_spec_next:
	mov	al,  [esi]
	call	.write
	inc	esi
	dec	ah
	jnz	.ch_spec_next
	jmp	.ccdonewith

; * Octal-dump bits of eax up to cl, used by char_cvt and oct_cvt
.od_dword:
	_mov	esi, eax
.od_dw_next:
	sub	cl, 3
	jc	.od_dw_done
	_mov	eax, esi
	shr	eax, cl
	and	al, 7
	add	al, '0'
	call	.write
	jmp	.od_dw_next
.od_dw_done:
	mov	al, ' '
	jmp	.write

;*** OCTAL DUMP *
.oct_cvt:
	_mov	ebx, [amt]
	mov	[inbuf + ebx], byte 0
	xor	edi, edi
.oct_cvt_nl:
	_mov	eax, [posn]
	add	eax, edi
	push	eax
	and	al, 15
	jnz	.oct_cvt_nonl
	pop	eax
	mov	cl, 21
	call	.od_dword
	push	eax
.oct_cvt_nonl:
	pop	eax
.oddumpone:
	xor	eax, eax		; Read a word and pass it to od_dword
	mov	ax, [inbuf + edi]
	mov	cl, 18
	call	.od_dword
	inc	edi
	inc	edi
	cmp	edi, [amt]
	jge	.oddone			; Buffer empty
	_mov	eax, edi
	add	eax, [posn]
	and	eax, 15
	jz	.od_retn		; End of line
	jmps	.oddumpone
.oddone:
	_mov	eax, [amt]		; Store info
	and	eax, 1
	jz	.odnodec
	dec	edi
.odnodec:
	add	[posn], edi
	mov	al, __n			; Write __n
	jmp	.write			; and return
.od_retn:
	mov	al, __n			; Write __n
	call	.write
	jmps	.oct_cvt_nl		; and continue

;*** HEXIDECIMAL DUMP *
; See .od_cvt for comments.
; Code identical except for call to .hexdig
; instead of .od_dword and setting of cl
.hex_cvt:
	_mov	ebx, [amt]
	mov	[inbuf + ebx], byte 0
        xor     edi, edi
.hex_cvt_nl:
        _mov    eax, [posn]
        add     eax, edi
        push    eax
        and     al, 15
        jnz	.hex_cvt_nonl
        pop     eax
        mov     cl, 32
        call	.hexdig
	push	eax
.hex_cvt_nonl:
	pop	eax
.hcdumpone:
	_mov	ax, [inbuf + edi]
	mov	cl, 16
	call	.hexdig
	inc	edi
	inc	edi
	cmp	edi, [amt]
	jge	.hcdone
	_mov	eax, edi
	add	eax, [posn]
	and	eax, 15
	jz	.hexdig_retn
	jmps	.hcdumpone
.hcdone:
	_mov	eax, [amt]
	and	eax, 1
	jz	.hcnodec
	dec	edi
.hcnodec:
	add	[posn], edi
	mov	al, __n
	jmp	.write

.hexdig_retn:
	mov	al, __n
	call	.write
	jmp	.hex_cvt_nl

;* Hexdump bytes of eax up to cl, used by .hex_cvt ***
.hexdig:
	mov	esi, eax
.hexdiga:
	sub	cl, 4
	mov	ebx, esi
	shr	ebx, cl
	and	ebx, 15
	mov	al, [hexdig + ebx]
	call	.write
	or	cl, cl
	jz	.hexdigdone
	jmp	.hexdiga
.hexdigdone:
	mov	al, ' '
	jmp	.write




;*** Our string data is stored here ***
hexdig  db      "0123456789abcdef"

list	db	"\0  \b  \f  \n  \r  \t  "
errln	db	"File access error", __n
errsize	equ 18

UDATASEG
input	resd 1		; = 0, STDIN
posn	resd 1		; = 0
outcnt	resd 1		; = 0, amount to write
amt	resd 1		; amount read from last call
inbuf	resb 1025	; one block for input buffer + pad byte
outbuf	resb 80		; line buffered
type	resb 1		; = 0, octal_dump

inbuflen	equ 1024
outbuflen	equ 1920

END

