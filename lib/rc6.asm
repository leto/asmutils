;Copyright (C) 1999 Cecchinel Stephan <inter.zone@free.fr>
;
;$Id: rc6.asm,v 1.3 2000/12/10 08:20:36 konst Exp $
;
;implementation of RC6 crypto algorythm
;
;RC6 algo mainly consists of 3 functions:
;	setkey in_key, length		->>set crypto key of length bits (256)
;	encrypt in_block,out_block	->>encrypt 16 byte block
;	decrypt in_block,out_block	->>decrypt 16 byte block
;
;	really simple to implement....no?
;
;10-Sep-2000 cleanup (KB)

%include "system.inc"

CODESEG

	global RC6_Setkey
	global RC6_Encrypt
	global RC6_Decrypt

PROC	RC6_Setkey, in_key, key_len

%define	a dword[ebp-4]			;local vars on the stack
%define	b dword[ebp-8]
%define i dword[ebp-12]
%define j dword[ebp-16]

	pusha

	sub	esp,byte 16

	mov	edi,l_key
	mov	dword[edi],0x0b7e15163
	xor	ecx,ecx
        inc	ecx
.cpy:
	mov	eax,dword [-4+edi+ecx*4]
	add	eax,0x09e3779b9
	mov	dword [edi+ecx*4],eax
	inc	ecx
	cmp	ecx,byte 44
	jb	.cpy

	xor	ecx,ecx
	mov	esi,in_key
	mov	edx,key_len
	shr	edx,5
.cpy1:
	mov	eax,[esi+ecx*4]
	mov	[edi+ecx*4],eax
	inc	ecx
	cmp	ecx,edx
	jb	.cpy1

        mov	esi,ll			;esi=ll
	dec	edx			;edx=t=(key_len/32)-1
	xor	ecx,ecx			;ecx=k=0
	mov	a,ecx
	mov	b,ecx
	mov	i,ecx
	mov	j,ecx			;a=b=i=j=0
.cpy2:
	push	ecx
	mov	ebx,i
	mov	eax,[edi+ebx*4]
	add	eax,a
	add	eax,b
	rol	eax,3
	add	b,eax			;b+=a
	mov	a,eax			;a=rol(l_key[i]+a+b
	mov	ebx,j
	mov	eax,dword [esi+ebx*4]
	add	eax,b
	mov	ecx,b
	rol	eax,cl
	mov	b,eax			;b=rol(ll[j]+b,b)
	mov	eax,a
	mov	ebx,i
	mov	[edi+ebx*4],eax		;l_key[i]=a
	mov	eax,b
	mov	ebx,j
	mov	[esi+ebx*4],eax		;ll[j]=b
	mov	eax,i
	inc	eax
	cmp	eax,byte 43
	jnz	.s1
	xor	eax,eax
.s1:
	mov	i,eax			;i=i+1 %43

	mov	eax,j
	inc	eax
	cmp	eax,edx
	jnz	.s2
	xor	eax,eax
.s2:
	mov	j,eax
	pop	ecx
	inc	ecx
	cmp	ecx,132
	jb	.cpy2
	mov	eax,edi

	add	esp,byte 16
	popa
ENDP


;---------------------------------------
;encrypt:
;
; input:	edi=in_block
;		esi=out_block

PROC RC6_Encrypt, in_block, out_block
	pusha
	mov	esi,out_block
	mov	edi,in_block
	push	esi
	mov	esi,l_key
	mov	eax,[edi]		;a=in_block[0]
	mov	ebx,[edi+4]
	add	ebx,[esi]		;b=in_block[1]+l_key[0]
	mov	ecx,[edi+8]		;c=in_block[2]
	mov	edx,[edi+12]
	add	edx,[esi+4]		;d=in_block[3]+l_key[1]
	lea	ebp,[esi+8]
.boucle:
	lea	esi,[edx+edx+1]
	imul	esi,edx
	rol	esi,5			;u=rol(d*(d+d+1),5)

	lea	edi,[ebx+ebx+1]
	imul	edi,ebx
	rol	edi,5			;t=rol(b*(b+b+1),5)

	push	ecx
	mov	ecx,esi
	xor	eax,edi
	rol	eax,cl
	add	eax,[ebp]		;a=rol(a^t,u)+l_key[i]
	pop	ecx

	push	eax
	xchg	ecx,eax
	mov	ecx,edi
	xor	eax,esi
	rol	eax,cl
	add	eax,[ebp+4]		;c=rol(c^u,t)+l_key[i+1]
	xchg	ecx,eax
	pop	eax

	push	eax
	mov	eax,ebx
	mov	ebx,ecx
	mov	ecx,edx
	pop	edx
	add	ebp,byte 8
	cmp	ebp,(l_key+(42*4))
	jnz	.boucle

	pop	edi
	mov	esi,l_key
	add	eax,[esi+(42*4)]
	mov	[edi],eax
	mov	[edi+4],ebx
	add	ecx,[esi+(43*4)]
	mov	[edi+8],ecx
	mov	[edi+12],edx
	
	popa
ENDP

;---------------------------------------
PROC RC6_Decrypt, in_blk2, out_blk2

	pusha
	mov	esi,out_blk2
	push	esi
	mov	edi,in_blk2
	mov	esi,l_key

	mov	edx,[edi+12]		;d=in_blk[3]
	mov	ecx,[edi+8]
	sub	ecx,[esi+(43*4)]	;c=in_blk[2]-l_key[43]
	mov	ebx,[edi+4]		;b=in_blk[1]
	mov	eax,[edi]
	sub	eax,[esi+(42*4)]	;a=in_blk[0]-l_key[42]
	lea	ebp,[esi+(40*4)]

.boucle2:
	push	edx
	mov	edx,ecx
	mov	ecx,ebx
	mov	ebx,eax
	pop	eax

	lea	esi,[edx+edx+1]
	imul	esi,edx
	rol	esi,5			;u=rol(d*(d+d+1),5)

	lea	edi,[ebx+ebx+1]
	imul	edi,ebx
	rol	edi,5			;t=rol(b*(b+b+1),5)

	push	eax
	xchg	ecx,eax
	mov	ecx,edi
	sub	eax,[ebp+4]
	ror	eax,cl
	xor	eax,esi
	xchg	ecx,eax
	pop	eax

	push	ecx
	mov	ecx,esi
	sub	eax,[ebp]
	ror	eax,cl
	xor	eax,edi
	pop	ecx

	sub	ebp,byte 8
	cmp	ebp,l_key
	jnz	.boucle2

	mov	esi,ebp
	pop	edi
	sub	edx,[esi+4]
	mov	[edi+12],edx		;out_blk[3]=d-l_key[1]
	mov	[edi+8],ecx		;out_blk[2]=c
	sub	ebx,[esi]
	mov	[edi+4],ebx		;out_blk[1]=b-l_key[0]
	mov	[edi],eax		;out_blk[0]=a

	popa
ENDP

UDATASEG

l_key	resd	45			;internal RC6 key
ll	resd	9

END
