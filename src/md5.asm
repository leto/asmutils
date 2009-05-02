;  md5.asm
;
;  MD5 alg impl based on R. Rivest's rfc1321, April 1992
;
;  USAGE: $ md5 [file(s)]
;
;  (c) 2003.03(01) Maciej Hrebien
;
;  $Id: md5.asm,v 1.2 2003/05/26 05:07:07 konst Exp $

%include "system.inc"

CODESEG

; in:  ebx (x), ecx (y), edx (z)
; out: eax = x&y | (~x)&z

 F:
	push	ebx
	mov	eax,ebx
	not	ebx
	and	eax,ecx
	and	ebx,edx
	or	eax,ebx
	pop	ebx
	ret


; in:  ebx (x), ecx (y), edx (z)
; out: eax = x&z | y&(~z)

 G:
	push	edx
	mov	eax,edx
	not	edx
	and	eax,ebx
	and	edx,ecx
	or	eax,edx
	pop	edx
	ret


; in:  ebx (x), ecx (y), edx (z)
; out: eax = x^y^z

 H:
	mov	eax,ebx
	xor	eax,ecx
	xor	eax,edx
	ret


; in:  ebx (x), ecx (y), edx (z)
; out: eax = y^(x|(~z))

 I:
	mov	eax,edx
	not	eax
	or	eax,ebx
	xor	eax,ecx
	ret


; main routine :)

 START:
	fstcw	[esp]			; make fpu floor().. (note: argc is touched!)
	or	[esp],word 0x400
	fldcw	[esp]

	mov	edi,T
 fill_T:
	inc	edx			; Ti = uint32(floor(fmag*fabs(sin(++i))))..
	push	edx

	fild	dword [esp]
	fsin
	fabs
	fmul	qword [fmag]
	fistp	qword [esp]		; note: argc is touched!

	pop	eax
	stosd

	cmp	edx,64
	jl	short fill_T

	pop	eax			; argc
	pop	eax			; arvg[0]
	pop	eax			; argv[1]
	push	eax
					; M as stdin..?
	_mov	ebp,STDIN

	or	eax,eax
	jz	short pre_finger_print
 argv:
	pop	ebx			; argv[n]
	push	ebx

	or	ebx,ebx
	jz	near exit

	sys_open ebx,O_RDONLY

	or	eax,eax
	js	near err

	xchg	ebp,eax			; M

 pre_finger_print:

	mov	edi,A			; init A,B,C & D with magics..

	mov	eax,0x67452301
	stosd
	mov	eax,0xefcdab89
	stosd
	mov	eax,0x98badcfe
	stosd
	mov	eax,0x10325476
	stosd

	_mov	eax,0
	stosd				; zero M_len & flags..
	stosw

 do_finger_print:

	mov	edi,X
	_mov	edx,64
	push	edi

 read_lp:				; read in loop (don't forget about STDIN!)
					; to got full block..
	sys_read ebp,edi,edx

	sub	edx,eax
	add	edi,eax

	or	eax,eax
	js	near err
	jnz	short read_lp

	pop	edi
	sub	edx,64
	neg	edx

	add	[M_len],edx

	cmp	edx,64			; got full block?
	jge	short hash

	or	edx,edx			; EOF..
	jnz	short pad

	cmp	[flag_padded],byte 0	; & already padded?
	jnz	near done
 pad:
	cmp	[flag_1added],byte 0
	jnz	short _1added

	inc	byte [flag_1added]	; start padding seq..
	mov	[edi+edx],byte 0x80
	inc	edx

 _1added:

	cmp	edx,56			; to big block? zeros must be splitted into 2..
	jg	short fill_0
					; we will fit in 1 block, padd with zeros..
	_mov	ecx,56
	add	edi,edx
	sub	ecx,edx

	xor	al,al
	rep	stosb

	mov	eax,[M_len]		; & add M size on 64 bits..
	push	eax
	shl	eax,3
	stosd
	pop	eax
	shr	eax,29
	stosd

	inc	byte [flag_padded]	; note we are done with padding!
	jmp	short hash

 fill_0:

	_mov	ecx,64
	add	edi,edx
	sub	ecx,edx

	xor	al,al
	rep	stosb

 hash:
	push	ebp

	std				; load A,B,C & D into registers..
	mov	esi,D
	lodsd
	xchg	edx,eax
	lodsd
	xchg	ecx,eax
	lodsd
	xchg	ebx,eax
	lodsd
	cld

	mov	esi,T			; T ptr, outer & inner loop cnter..
	_mov	ebp,3
	push	dword 15

 pre_FGHI:

	push	eax			; get X i-index initial value..
	_mov	eax,0

	mov	al,[ebp+i_T]
	xchg	edi,eax

	pop	eax

 do_FGHI:

	push	ecx
	push	eax

	call	[ebp*4+f_T]		; do F, G, H or I

	add	[esp],eax		; a += f(b,c,d)
	pop	eax
	add	eax,[esi]		; a += Ti
	add	eax,[edi*4+X]		; a += Xi

	mov	ecx,[esp+4]		; get inner loop cnter & rol rate..
	and	ecx,0x3
	mov	cl,[ecx+ebp*4+rol_T]

	rol	eax,cl			; a <& s
	add	eax,ebx			; a += b

	mov	cl,[ebp+inc_T]		; actualize X i-index..
	add	edi,ecx
	and	edi,0xf
	add	esi,4			; & mov T ptr to next Ti

	pop	ecx

	xchg	edx,ecx			; rotate right arguments for F,G,H or I,
	xchg	ecx,ebx			; a -> b, b -> c, c -> d, d -> a..
	xchg	ebx,eax

	dec	dword [esp]		; done with inner loop?
	jns	short do_FGHI

	and	[esp],dword 15		; reset the counter

	dec	ebp			; do next outer loop..
	jns	short pre_FGHI
					; note: esi points to A in here!
	add	[esi],eax		; A += AA
	add	[esi+4],ebx		; B += BB
	add	[esi+8],ecx		; C += CC
	add	[esi+12],edx		; D += DD

	pop	ebp
	pop	ebp

	jmp	near do_finger_print

 done:
;	sys_close ebp

	mov	esi,A			; A,B,C,D hex print..
	lea	edi,[esi+22]		; mov edi,hex_buf
	push	edi

	_mov	ecx,16
 hex_lp:
	lodsb
	mov	dl,al

	shr	al,4
	aam
	aad	'a'-'0'
	add	al,'0'
	stosb

	xchg	eax,edx

	and	al,0xf
	aam
	aad	'a'-'0'
	add	al,'0'
	stosb

	loop	hex_lp

	pop	ecx
	_mov	ebx,STDOUT

	sys_write ebx,ecx,32

	cmp	ebp,STDIN		; stdin or named fd?
	je	short putNL

	sys_write ebx,SPC,1

	pop	esi			; argv[n] - fname
	push	esi

	_mov	edx,-1
 strlen:
	inc	edx
	lodsb
	or	al,al
	jnz	short strlen

	pop	ecx

	sys_write ebx,ecx,edx
 putNL:
	sys_write ebx,NL,1

	jmp	argv
 err:
;	sys_close ebp
;	_mov	ebx,1

	xchg	ebx,eax
 exit:
	sys_exit ebx

 _rodata:

 fmag	dq 4294967296.0
 SPC	db ' '
 NL	db 0xa

; NOTE: all below is in reversed order!

 rol_T	db 21,15,10,6	; for I,
	db 23,16,11,4	; for H,
	db 20,14, 9,5	; for G
	db 22,17,12,7	; & F

 inc_T	db 7,3,5,1	; X i-index inc values in proper round
 i_T	db 0,5,1,0	; X i-index initial values (set before round)
 f_T	dd I,H,G,F	; f we call in 1st, 2nd, 3rd & 4th round of MD5

UDATASEG

 X	resb 64
 T	resd 64
 A	resd 1
 B	resd 1
 C	resd 1
 D	resd 1
 M_len	resd 1

 flag_padded	resb 1
 flag_1added	resb 1

 hex_buf	resb 32

END
