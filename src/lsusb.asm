;Copyright (C) 2003 Nick Kurshev <nickols_k@mail.ru>
;
;$Id: lsusb.asm,v 1.1 2003/05/26 18:13:08 nickols_k Exp $
;
;hackers' lsusb
;
;syntax: lsusb
;
;0.01: 26-May-2003	initial release (note: some code was borrowed from other sources of this project)
;
; Note1: It's sumplest version of lsusb
; Note2: It was tested with Linux-2.4 only
;
; TODO: More complex line parser
;

%include "system.inc"

CODESEG


%assign	BUFSIZE	0x40000

START:
	push	ebp
	mov	ebp, esp
	sub	esp, 4

	sys_open fname,O_RDONLY
	test	eax,eax
	js	.do_exit
	mov	[ebp-4], eax
	sys_read eax,buf,BUFSIZE
	jz	.do_exit
	push	eax
	sys_close [ebp-4]
	pop	ecx
	mov	esi, header
	call	printS
	mov	esi, buf
	call	usb_parse
.do_exit:
	sys_exit eax
	
usb_parse:
; ARGS:
; esi - file contents
; ecx - filesize
	push	ebp
	mov	ebp, esp
	sub	esp, 12
	mov	[ebp-4], esi
	mov	[ebp-8], ecx
	mov	[ebp-12], dword 0

.next_line:
	mov	ecx, [ebp-8]
	test	ecx, ecx
	jz	near .done
	mov	esi, [ebp-4]
	mov	edi, tmp
.loop:
	lodsb
	stosb
	cmp	al, __n
	je	.line_ready
	loop	.loop
.line_ready:
	xor	al, al
	stosb
	mov	[ebp-4], esi
	mov	[ebp-8], ecx


.try_tbus:
	mov	esi, [ebp-4]
	mov	edi, tbus
	mov	ecx, tbus_size
	call	memcmp
	test	eax, eax
	jnz	near .try_vers
	mov	[ebp-12], dword 1
	add	esi, tbus_size
	push	esi
.next_char1:
	lodsb
	cmp	al, ' '
	jne	.next_char1
	dec	esi
	mov	[esi], byte 0
	pop	esi
	call	printS
	push	esi
	mov	esi, point
	call	printS
	pop	esi
	add	esi, 23
	push esi
.next_char2:
	lodsb
	cmp	al, ' '
	jne	.next_char2
	dec	esi
	mov	[esi], byte 0
	pop	esi
	call	printS
	push	esi
	mov	esi, point
	call	printS
	pop	esi
	add	esi, 15
	push esi
.next_char3:
	lodsb
	cmp	al, ' '
	je	.next_char3
.next_char4:
	lodsb
	cmp	al, ' '
	jne	.next_char4
	dec	esi
	mov	[esi], byte 0
	pop	esi
	call	printS
	push	esi
	mov	esi, obr
	call	printS
	pop	esi
	add	esi, 8
	push esi
.next_char5:
	lodsb
	cmp	al, ' '
	jne	.next_char5
	dec	esi
	mov	[esi], byte 0
	pop	esi
	call	printS
	push	esi
	mov	ecx, 4
	sub 	ecx, eax
	cmp	ecx, 0
	jle	.pr_mb
	mov	esi, space
.tab0:
	call	printS
	loop	.tab0
.pr_mb:
	mov	esi, Mb
	call	printS
	mov	esi, cbr
	call	printS
	mov	esi, space
	call	printS
	pop	esi
	jmp	.next_line

.try_vers:
	mov	esi, [ebp-4]
	mov	edi, ver_s
	mov	ecx, ver_s_size
	call	memcmp
	test	eax, eax
	jnz	near .try_manufacturer
	add	esi, ver_s_size
	push	esi
.nxt_char:
	lodsb
	cmp	al, ' '
	jne	.nxt_char
	dec	esi
	mov	[esi], byte 0
	cmp	[ebp-12], dword 0
	ja	.pr_v
	mov	ecx, 18
	mov	esi, space
.prs:
	call	printS
	loop	.prs
.pr_v:
	pop	esi
	call	printS
	mov	esi, space
	call	printS
	jmp	.next_line

.try_manufacturer:
	mov	esi, [ebp-4]
	mov	edi, manufacturer
	mov	ecx, manufacturer_size
	call	memcmp
	test	eax, eax
	jnz	.try_product
	add	esi, manufacturer_size
	push	esi
.nxt_chr2:
	lodsb
	cmp	al, __n
	jne	.nxt_chr2
	dec	esi
	mov	[esi], byte 0
	mov	edi, esi
	mov	esi, obr
	call	printS
	pop	esi
	call	printS
	mov	[edi], byte __n
	mov	esi, cbr
	call	printS
	jmp	.next_line

.try_product:
	mov	esi, [ebp-4]
	mov	edi, product
	mov	ecx, product_size
	call	memcmp
	test	eax, eax
	jnz	near .try_ifs
	add	esi, product_size
	push	esi
.nxt_char3:
	lodsb
	cmp	al, __n
	jne	.nxt_char3
	dec	esi
	mov	[esi], byte 0
	mov	edi, esi
	pop	esi
	call	printS
	mov	[edi], byte __n
	jmp	.next_line

.try_ifs:
	mov	esi, [ebp-4]
	mov	edi, ifs
	mov	ecx, ifs_size
	call	memcmp
	test	eax, eax
	jnz	near .next_line

	add	esi, 62
	push	esi
.next_char0:
	lodsb
	cmp	al, __n
	jne	.next_char0
	dec	esi
	mov	[esi], byte 0
	mov	edi, esi
	mov	esi, Obr
	call	printS
	pop	esi
	call	printS
	mov	[edi], byte __n
	mov	esi, Cbr
	call	printS
	mov	esi, eol
	call	printS
	jmp	.next_line

.done:
	leave
	ret
	
memcmp:
; args:
; esi - s1
; edi - s2
; ecx - size

	push	edi
	push	esi
	xor	eax, eax
;	cld
	repe	cmpsb
	je	.done			;strings are equal
	sbb	eax,eax
	or	eax, byte 1
.done:
	pop	esi
	pop	edi
	ret                                        

printS:
; ARGS: esi - source
; returns eax - strlen
	test	esi, esi
	jz	.exit
	push	ecx
	push	esi
	xor	ecx, ecx
.loop:
	lodsb
	test	al, al
	jz	.done
	inc	ecx
	jmps	.loop
.done:
	pop	esi
	push	ecx
	sys_write STDOUT,esi,ecx
	pop	eax	; return value
	pop	ecx
.exit:
	ret

DATASEG
fname	db	'/proc/bus/usb/devices',0

header	db	'BusPortDev Speed   Ver [Manufacturer]Name{driver}',__n,0
manufacturer db	'S:  Manufacturer='
manufacturer_size equ $-manufacturer
product db	'S:  Product='
product_size equ $-product
ifs	db	'I:  If#= 0'
ifs_size equ $-ifs
ver_s	db	'D:  Ver= '
ver_s_size equ $-ver_s
tbus	db	'T:  Bus='
tbus_size equ $-tbus
errmsg		db	"error",0
eol		db	__n,0
point		db	'.',0
space		db	' ',0
space2		db	'  ',0
obr		db	'[',0
cbr		db	']',0
Obr		db	'{',0
Cbr		db	'}',0
Mb		db	'Mb',0

UDATASEG
buf	resb	BUFSIZE
tmp	resb	BUFSIZE

END
