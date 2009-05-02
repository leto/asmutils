;  idea.asm
;
;  IDEA cipher impl based on Bruce Schneier's "Applied Cryptography"
;    (Polish edition WNT W-wa 1995, page 314..321 & code examples
;                     at the end of the book)
;
;  USAGE: $ idea e/d key [file(s)]
;
;  NOTE:
;    IDEA algorithm is patented by Ascom-Tech AG but free of
;               charge for non-commercial users
;
;  (c) 2003.03(01) Maciej Hrebien with dedication
;           to Dominika Ferenc (miss You all the time!)
;
;  $Id: idea.asm,v 1.4 2003/05/26 05:10:20 konst Exp $

%include "system.inc"

%assign PADchr '*' ; padding char at the end of not full block

CODESEG

; multiply ax with bx modulo (2**16)+1
;       the result goes to ax
; NOTE: the MSBs of eax must be zeroed!

 mod_mul:

	or	eax,eax
	jz	short _a0

	or	bx,bx
	jz	short _b0

	push	edx
	push	ebx

	xor	edx,edx
	mul	bx
	shl	edx,16
	xchg	dx,ax
	xchg	edx,eax
	mov	ebx,65537
	div	ebx
	xchg	ax,dx
	
	pop	ebx
	pop	edx
	ret

 _a0:	mov	ax,bx
 _b0:	neg	ax
	inc	ax
	ret


; ax's multiplicative inversion (brutal method)
;      NOTE: the MSBs of eax are zeroed!

 inv:
	and	eax,0xffff

	or	eax,eax
	jz	short inv_ret

	push	ebx
	push	ecx
	push	edx

	_mov	ecx,65535
	lea	ebx,[ecx+2]

 inv_lp:

	xor	edx,edx
	push	eax

	mul	ecx
	div	ebx

	pop	eax

	dec	edx
	jz	short inv_done

	loop	inv_lp

 inv_done:

	xchg	ecx,eax
	pop	edx
	pop	ecx
	pop	ebx

 inv_ret:

	ret


; encode key generator
; in:  esi - user_key[16]
; out: edi - en_key[52]

 gen_en_key:

	pusha
	push	edi

	_mov	ecx,8
	rep	movsw			; memcpy(en_key,user_key,2*8)

	pop	esi
	inc	ecx			; i = 1, b = 0..
	_mov	ebx,0

 gek_lp:

	push	ecx

	and	ecx,7			; ax = en_key[b+(i&7)]
	lea	edx,[ebx+ecx]
	mov	ax,[esi+edx*2]

	inc	ecx			; dx = en_key[b+((i+1)&7)]
	and	ecx,7
	lea	edx,[ebx+ecx]
	mov	dx,[esi+edx*2]

	shl	ax,9			; en_key[j++] = (ax << 9)|(dx >> 7)
	shr	dx,7
	or	ax,dx
	stosw

	pop	ecx

	mov	eax,ecx			; b += (!((i++)&7))*8
	and	eax,7
	sub	al,1
	setc	al
	shl	eax,3
	add	ebx,eax

	inc	ecx
	cmp	ecx,44
	jle	short gek_lp

	popa
	ret


; decode key generator
; in:  esi - en_key[52]
; out: edi - de_key[52]

 gen_de_key:

	pusha
	xor	eax,eax

	mov	ax,[esi+2*48]		; de_key[0]=inv(en_key[48])
	call	inv
	stosw

	mov	ax,[esi+2*49]		; de_key[1]=-en_key[49]
	neg	ax
	stosw

	mov	ax,[esi+2*50]		; de_key[2]=-en_key[50]
	neg	ax
	stosw

	mov	ax,[esi+2*51]		; de_key[3]=inv(en_key[51])
	call	inv
	stosw
					; k = 42
	_mov	ecx,42

 gdk_lp:

	mov	eax,[esi+ecx*2+2*4]	; de_key[i++]=en_key[k+4]
	stosd				; de_key[i++]=en_key[k+5]

	mov	ax,[esi+ecx*2]		; de_key[i++]=inv(en_key[k])
	call	inv
	stosw

	mov	ax,[esi+ecx*2+2*2]	; de_key[i++]=-en_key[k+2]
	neg	ax
	stosw

	mov	ax,[esi+ecx*2+2*1]	; de_key[i++]=-en_key[k+1]
	neg	ax
	stosw

	mov	ax,[esi+ecx*2+2*3]	; de_key[i++]=inv(en_key[k+3])
	call	inv
	stosw

	sub	ecx,6
	jnz	short gdk_lp

	mov	eax,[esi+2*4]		; de_key[46]=en_key[4]
	stosd				; de_key[47]=en_key[5]

	lodsw				; de_key[48]=inv(en_key[0])
	call	inv
	stosw

	lodsw				; de_key[49]=-en_key[1]
	neg	ax
	stosw

	lodsw				; de_key[50]=-en_key[2]
	neg	ax
	stosw

	lodsw				; de_key[51]=inv(en_key[3])
	call	inv
	stosw

	popa
	ret


; encode / decode routine
; in:  esi - en/de_key[52], edi - input[4]
; out: edi - output[4]

 do_idea:

	pusha
	push	edi

	mov	cx,[edi]		; x1
	mov	dx,[edi+2*1]		; x2
	mov	bp,[edi+2*2]		; x3
	mov	di,[edi+2*3]		; x4

	_mov	eax,8
 di_lp:
	push	eax

	lodsw				; x1 = x1 %* key[i++]
	mov	bx,cx
	call	mod_mul
	xchg	cx,ax

	lodsw				; x2 += key[i++]
	add	dx,ax

	lodsw				; x3 += key[i++]
	add	bp,ax

	lodsw				; x4 = x4 %* key[i++]
	mov	bx,di
	call	mod_mul
	xchg	di,ax

	mov	bx,bp			; tmp1 = (x1^x3) %* key[i++]
	xor	bx,cx
	lodsw
	call	mod_mul
	push	eax

	mov	bx,di			; tmp2 = (tmp1 + (x2^x4)) %* key[i++]
	xor	bx,dx
	add	bx,ax
	lodsw
	call	mod_mul

	pop	ebx			; tmp1 += tmp2
	add	bx,ax

	xor	cx,ax			; x1 ^= tmp2
	xor	bp,ax			; x3 ^= tmp2
	xor	dx,bx			; x2 ^= tmp1
	xor	di,bx			; x4 ^= tmp1

	xchg	bp,dx			; swap(x2,x3)

	pop	eax
	dec	eax
	jnz	short di_lp

	mov	bx,cx			; x1 = x1 %* key[i++]
	lodsw
	call	mod_mul
	xchg	cx,ax

	lodsw				; x2 += key[i++]
	add	bp,ax

	lodsw				; x3 += key[i++]
	add	dx,ax

	mov	bx,di			; x4 = x4 %* key[i++]
	lodsw
	call	mod_mul

	pop	edi			; store..

	mov	[edi],cx		; x1
	mov	[edi+2*1],bp		; x2
	mov	[edi+2*2],dx		; x3
	mov	[edi+2*3],ax		; x4

	popa
	ret


; idea main routine
; in:  esi - key[52], edi - fd to read from
; out: eax < 0 if err

 idea:
	push	eax			; some space for buffer..
	push	eax
 i_lp:
	_mov	eax,7
 i_pad:
	mov	[esp+eax],byte PADchr
	dec	eax
	jns	i_pad

	_mov	edx,8
	mov	ecx,esp
 i_read:				; read in loop cause of STDIN..
	sys_read edi,ecx,edx

	add	ecx,eax
	sub	edx,eax

	or	eax,eax
	js	short i_ret
	jnz	short i_read

	cmp	edx,8
	je	short i_ret

	push	edi
	lea	edi,[esp+4]

	call	do_idea

	sys_write STDOUT,edi,8

	pop	edi
	jmp	short i_lp
 i_ret:
	pop	ecx
	pop	ecx

	ret


; main routine :)

 START:
	pop	eax			; argc
	pop	eax			; argv[0]
	pop	esi			; argv[1]

	or	esi,esi
	jz	short help

	lodsb

	cmp	al,'e'
	je	short getkey

	cmp	al,'d'
	jne	short help

 getkey:

	mov	[ed_flag],al
	pop	esi			; argv[2]

	or	esi,esi
	jz	short help

	mov	edi,usr_key
	_mov	ecx,16
	push	edi

 key_copy:

	lodsb
	or	al,al
	jz	short copy_done

	stosb
	loop	key_copy

 copy_done:

	pop	esi
	lea	edi,[esi+16]		; mov edi,enc_key

	call	gen_en_key

	mov	ebp,edi

	cmp	[ed_flag],byte 'e'
	je	short pre

	mov	esi,edi
	add	edi,2*52		; mov edi,dec_key

	call	gen_de_key

	mov	ebp,edi
 pre:
	pop	ecx			; argv[3]
	push	ecx
	_mov	eax,STDIN
	
	jecxz	go
 argv:
	pop	eax			; argv[n]

	or	eax,eax
	jz	short exit

	sys_open eax,O_RDONLY

	or	eax,eax
	js	short err
 go:
	xchg	edi,eax
	mov	esi,ebp

	call	idea

;	push	eax
;	sys_close edi
;	pop	eax

	or	eax,eax
	jns	short argv

	jmp	short err
 help:
	sys_write STDERR,usage,25
 err:
 exit:
	sys_exit eax

 _rodata:

 usage db "$ idea e/d key [file(s)]",0xa

UDATASEG

 usr_key resb 16
 enc_key resb 2*52
 dec_key resb 2*52
 ed_flag resb 1

END
