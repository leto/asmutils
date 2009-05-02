;Copyright (C) 2002 by Joshua Hudson
;
;$Id: du.asm,v 1.2 2004/01/20 05:25:31 konst Exp $
;
; hackers du - JH
;
; This guy can just about use that 8k stack
;
; Usage: du [-taskd] directory
;       -t      total all and display only total
;       -a      all files
;       -s      summary: no depth display
;       -k      display in kb blocks
;	-ss	turns off recursion all together
;	-d	Use 512 block size & fill holes (transfer est.)

%include 'system.inc'

direntbufsize	equ     8192
;S_IFMT	  	equ     0170000q
;S_IFDIR	equ     0040000q

CODESEG

START:
;*********** Process each option *****************
	pop     esi
	pop     esi
opt:	pop     esi
	or      esi, esi
	jz      bye
	lodsb
	cmp     al, '-'
	jne      doneopt
.nopt	lodsb
	cmp     al, 'a'
	je      .all
	cmp     al, 's'
	je      .sum
	cmp     al, 't'
	je      .tot
	cmp     al, 'k'
	je      .kb
	cmp	al, 'd'
	je	.kd
	cmp     al, '-'
	je      nextarg
	cmp     al, 0
	je      opt
	jmps    .nopt           ; Skip unknown options

.all	inc     byte	[optall]
	jmps    .nopt
.sum	inc     byte	[optsummary]
	jmps    .nopt
.tot	inc     byte	[opttotal]
	jmps    .nopt
.kb	inc     byte	[optkb]
	jmps    .nopt
.kd	inc     byte	[optd]
	jmps    .nopt

;******************* Display total and exit **************
bye:    cmp     [opttotal], byte 0
	je      .exit
	call    itoa
	mov     edx, itoabuf + 10
	xchg    eax, ebp
	push	edx
	call    itoa
	pop	edx
	mov     [edx], byte 10
	sub     edx, ecx
	inc	edx
	sys_write       1
.exit   sys_exit_true

;***************** Process each directory ******************
doneopt:
	dec	esi
	push	esi
	xor	ebp, ebp
nextarg:
	pop     esi             ; next argument
	or      esi, esi
	jz      bye
	mov     edi, pathbuf
.copy	lodsb
	stosb
	or      al, al
	jnz     .copy
	dec     edi
	call    du
	js	nextarg
	add     ebp, eax
	cmp     [opttotal], byte 0
	jne     nextarg
	call    itoa
	call    outline
	jmps    nextarg

;**************** Calc usage of each directory *************
du:
	; Stat it
	sys_lstat	pathbuf, sts
	or	eax, eax
	js	near	.duret		; cant stat this guy
	test	[optd], byte 1
	jz	.dev
	mov	eax, [sts.st_size]
	add	eax, 511
	xor	edx, edx
	mov	ebx, 512
	div	ebx
	jz	.gotbk
.dev	mov	eax, [sts.st_blocks]
	mov	ebx, 512		; Want # of device blocks used
	mul	ebx			; not 512 byte blocks
	mov	ebx, [sts.st_blksize]
	shr	ebx, 2			; Why?
	div	ebx
.gotbk	cmp	[optkb], byte 0
	je	.no2k
	or	eax, eax		; If used no blocks, will use none
	jz	.no2k
	mov	ebx, 512 * 4
	test	[optd], byte 1
	jnz	.nodv2
	mov	ebx, [sts.st_blksize]
.nodv2	mul	ebx
	mov	ebx, 1024 * 4		; Why not 1024?
	div	ebx
	or	edx, edx
	jz	.no2k
	inc	eax			; Round up!
.no2k	cmp	[optsummary], byte 2
	jnb	near	.dubye		; No recursion at all!
	mov	ebx, [sts.st_mode]
	and	ebx, S_IFMT
	cmp	ebx, S_IFDIR
	jne	near	.dubye

;******************* Du recursion *****************************
	push	ebx		; Save mode for later
	push	ebp		; Be nice
	mov	ebp, eax	; Our total to sum
	sys_open	pathbuf, 0
	xchg	eax, ebx
	mov	eax, ebp	; Prevent large return on ENOPERM
	or	ebx, ebx
	js	near	.norec
	push	edi
	mov	[edi], byte '/'
	inc	edi
	xor	edx, edx
	mov	dh, direntbufsize >> 8
	call	allocdirentsbuf
	push	ecx

; Loop through all the directory entries in the directory in pathbuf
;	(we opened it)
.loop:
	pop	ecx
	xor	edx, edx
	mov	dh, direntbufsize >> 8
	push	ecx
%ifdef	__BSD__
	mov	esi, direntoffs
	sys_getdirentries
%else
	sys_getdents
%endif
	or	eax, eax
	js	.donerc
	jz	.donerc
.next:
	push	eax		; Cant pusha/popa here
	push	ebx
	push	ecx
	push	edi
%ifdef __BSD__
	cdq
	cmp	[ecx + dirent.d_fileno], edx	; Fix bum name for bum BSD
	jz	.isnxt
%endif
	lea	esi, [ecx + dirent.d_name]
	cmp	[esi], byte 0
	je	.isnxt
	cmp	[esi], word	0x002E
	je	.isnxt			; skip . (current directory)
	cmp	[esi], word	0x2E2E
	jne	.copy			; not ..
	cmp	[esi + 2], byte 0
	je	.isnxt			; skip .. (parent directory)
.copy	lodsb
	stosb
	or	al, al
	jnz	.copy
	dec	edi
	call	du			; We are recursive anyway
	js	.isnxt
	add	ebp, eax		; Total it up
	cmp	[opttotal], byte 0
	jne	.isnxt
	cmp	[optall], byte 0
	jne	.disply
	or	eax, eax
	js	.isnxt
	cmp	ebx, S_IFDIR		; ebx saved file type from call
	jne	.isnxt
.disply	call	itoa
	call	outline

.isnxt	pop	edi
	pop	ecx
	pop	ebx
	pop	eax
	movzx	edx, word [ecx + dirent.d_reclen]
	or	edx, edx
	jz	.nonext
	add	ecx, edx
	sub	eax, edx
	jnc	.next
.nonext:
	jmp	.loop

.donerc	sys_close
	pop	ecx
	call	freedirentsbuf
	pop	edi
	mov	[edi], byte 0
	add	eax, ebp	; Return total
.norec	pop	ebp
	pop	ebx
.dubye	sub	ecx, ecx	; clear sign flag
.duret	ret

;****************** Alloc/free functions *******************
allocdirentsbuf:			; works well enough
	mov	ecx, [direntsbuf]	; Assuming stack like
	add	ecx, edx
	cmp	ecx, [highwater]
	jna	.nosbrk
	push	ebx
	sys_brk	ecx
	or	eax, eax
	js	error
	pop	ebx
	mov	[highwater], ecx
.nosbrk	mov	[direntsbuf], ecx
	mov	[ecx - 4], ecx
	sub	ecx, edx
	mov	[ecx], ecx
	ret

error:	sys_exit_false

freedirentsbuf:
	mov	[direntsbuf], ecx	; Stack like: quick
	ret

;***************** Generic Subroutines *********************
itoa:	push    edi
	mov     edi, itoabuf + 10
	std
	_mov    ebx, 10
	push	eax
	mov     al, __t
	stosb
	pop	eax
.div	xor     edx, edx
	div     ebx
	xchg	eax, edx
	add     al, '0'
	stosb
	xchg	eax, edx
	or	eax, eax
	jnz	.div
	cld
	inc	edi
	mov     ecx, edi		; Odd? it makes sense (read below)
	pop     edi
	ret

outline:
	push	edi
	mov     edi, ecx
	xor     edx, edx
	mov     eax, edx
.scan	inc     edx
	scasb
	jnz     .scan
	dec	edi
	mov     [edi], byte 10
	sys_write	1
	mov     [edi], byte 0
	pop	edi
	ret

DATASEG

direntsbuf	dd	buf
highwater	dd	buf

UDATASEG

opttotal	resb    1
optall		resb    1
optsummary      resb    1
optkb		resb    1
optd		resb	1
		resb	3
sts:
%ifdef __BSD__
B_STRUC	Stat,.st_mode,.st_size,.st_blocks,.st_blksize
%else
B_STRUC Stat,.st_mode,.st_size,.st_blksize,.st_blocks
%endif

gtotal		resd	1
itoabuf		resb	11
pathbuf		resb	1024 * 2 + 4	; Real maximum
%ifdef __BSD__
direntoffs	resd	1
%endif
buf		resb	0		; Grown with sys_brk

END
