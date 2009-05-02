;Copyright (C) 1999 Cecchinel Stephan <interzone@pacwan.fr>
;
;$Id: rc6crypt.asm,v 1.6 2002/02/02 08:49:25 konst Exp $
;
;hackers' rc6crypt
;
;syntax:   rc6crypt e|d KEY FILE...
;
;encrypts or decrypts given file(s)
;
;KEY is an ascii key use for crypt or decrypt, it is internally
;converted to 256 bit key for RC6 with the Ripemd algo
;
;0.01: 24-Dec-1999	initial release (CS)
;0.02: 12-Sep-2000	rewritten to be linked with libcrypto,
;			various cleanup and size improvements (KB)

%include "system.inc"

%assign	FBUFSIZE	0x2000		;size of the file buffer

CODESEG

syntax:
db "Copyright (c) 1999-2000 Cecchinel Stephan",__n,
db "Usage:	rc6crypt e|d KEY FILE...",__n
db "	e - encrypt",__n
db "	d - decrypt",__n
db "	KEY is an ascii string of unlimited lenght",__n

_lsyntax	equ	$-syntax
%assign		lsyntax _lsyntax

texterr		db	"An error occured..",__n
_ltexterr	equ	$-texterr
%assign		ltexterr _ltexterr

devrandom	db	"/dev/random",EOL

START:
	pop	esi		;get argc
	cmp	esi,byte 4  	;there must me at least 3 args (rc6crypt e|d key file)
	jae	arg_ok

usage:
	sys_write STDOUT,syntax,lsyntax
do_exit:
	sys_exit_true

arg_ok:
	pop	ebx		;our name
	pop	ebx		;1st arg (e or d)
	mov	al,[ebx]
	mov	[action],al
	cmp	al,'d'
	jz	.make_key
	cmp	al,'e'
	jnz	usage

.make_key:

	pop	ebx		;2nd arg (key string)
	invoke	parsekey,ebx
	invoke	RC6_Setkey,key,256

.begin:
	pop 	ebx
	test	ebx,ebx
	jz	do_exit

	sys_open EMPTY,O_RDWR
	mov	ebp,eax
	test	eax,eax
	js	.begin
.read0:
	xor	eax,eax
	mov	[flength],eax
.read1:
	_mov	ecx,ibuffer
	_mov	edx,FBUFSIZE
.read_loop:
	sys_read ebp
	test	eax,eax
	jns	.read_ok
.error:
	sys_write STDOUT,texterr,ltexterr
	jmp	do_exit
.read_ok:
	jz	near .next_f2
	
	pusha
	mov	ecx,eax
	shr	ecx,4
	jz	.crypt2
	mov	edx,ecx
	mov	esi,ibuffer
	mov	edi,obuffer
.crypt:
	cmp	byte [action],'d'
	jz	.decrypt
	invoke	RC6_Encrypt,esi,edi
	jmps	.done_crypt
.decrypt:
	invoke	RC6_Decrypt,esi,edi
.done_crypt:
	add	esi,byte 16
	add	edi,byte 16
	dec	ecx
	jnz	.crypt

	shl	edx,4
	add	[flength],edx
	pusha
	mov	esi,edx
	xor	edi,edi
	sub	edi,eax
	sys_lseek ebp,edi,SEEK_CUR	
	sys_write ebp,obuffer,esi
	popa
.crypt2:
	popa
.next_f2:
	cmp	eax,FBUFSIZE
	jz	near .read1

	cmp	byte [action],'e'
	jz	.finish_encrypt

.finish_decrypt:
	mov	esi,ibuffer
	and	eax,byte -16
	mov	edi,[esi+eax]
	sys_ftruncate ebp,edi
	jmp	.finish

.finish_encrypt:
	and	eax,byte 15
	jz near .finish1
	add	[flength],eax		;length+=rest
	mov	edi,eax
	mov	esi,ibuffer
	sys_read ebp,esi,edi
        xor	esi,esi
        sub	esi,edi
        sys_lseek ebp,esi,SEEK_CUR

	sys_open devrandom,O_RDONLY	;open /dev/random

	mov	ebx,eax
	_mov	eax,16
	sub	eax,edi			;length=16-rest
	lea	ecx,[ibuffer+edi]
	mov	edx,eax
	sys_read			;read("/dev/random",ibuffer+rest,16-rest)

	invoke	RC6_Encrypt,ibuffer,obuffer
        sys_write ebp,obuffer,16

.finish1:
	mov	eax,[flength]
	mov	esi,obuffer
	mov	[esi],eax
	sys_write ebp,esi,4
.finish:
	sys_close ebp
	jmp	.begin

;--------------------------------------------------
; parse the given key string, with the Ripemd algo..
; transform it in a 256 bit key to use with RC6...

PROC	parsekey , stringkey
	pusha
	xor	ecx,ecx
	mov	edi,stringkey
.strlen:
	cmp	byte[edi+ecx],1
	inc	ecx
	jnc	.strlen
	dec	ecx
	call	RMD_Init
	mov	ebx,ecx
	shr	ecx,1
	mov	esi,edi
	call	RMD_Update
	push	edi
	mov	edi,key1
	call	RMD_Final
	pop	edi
	mov	edx,ebx
	call	RMD_Init
	mov	ebx,ecx
	test	edx,1
	jz	.suite
	inc	ecx
.suite:
	lea	esi,[edi+ebx]
	call	RMD_Update
	mov	edi,key2
	call	RMD_Final

; compose key with key1 and key2

	mov	esi,key1
	cld
	mov	edi,key
	movsd
	movsd
	movsd
	lodsd
	xor	eax,[esi+4]
	stosd
	lodsd
	xor	eax,[esi+4]
	stosd
	add	esi,byte 8
	movsd
	movsd
	movsd
	popa
ENDP

;
;library functions
;

PROC	RC6_Setkey, in_key, key_len

%define	a dword[ebp-4]			;local vars on the stack
%define	b dword[ebp-8]
%define i dword[ebp-12]
%define j dword[ebp-16]

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

;
;RMD
;

;size of incoming data buffer
;needs to be fixed for RMD_Final
;needs to be a power of two

%assign	BUFSIZE	0x2000

;magic initialization constants

%assign	_A	0x67452301
%assign	_B	0xefcdab89
%assign	_C	0x98badcfe
%assign	_D	0x10325476
%assign	_E	0xc3d2e1f0

%if	__OPTIMIZE__ = __O_SIZE__

;RMD-160 core constants, bit shifts, offsets
;Never change the order

Round1:	dd FF,0
	db 0,11,1,14,2,15,3,12
	db 4,5,5,8,6,7,7,9
	db 8,11,9,13,10,14,11,15
	db 12,6,13,7,14,9,15,8
Round2:	dd GG,0x5a827999
	db 7,7,4,6,13,8,1,13
	db 10,11,6,9,15,7,3,15
	db 12,7,0,12,9,15,5,9
	db 2,11,14,7,11,13,8,12
Round3:	dd HH,0x6ed9eba1
	db 3,11,10,13,14,6,4,7
	db 9,14,15,9,8,13,1,15
	db 2,14,7,8,0,13,6,6
	db 13,5,11,12,5,7,12,5
Round4:	dd II,0x8f1bbcdc
	db 1,11,9,12,11,14,10,15
	db 0,14,8,15,12,9,4,8
	db 13,9,3,14,7,5,15,6
	db 14,8,5,6,6,5,2,12
Round5:	dd JJ,0xa953fd4e
	db 4,9,0,15,5,5,9,11
	db 7,6,12,8,2,13,10,12
	db 14,5,1,12,3,13,8,14
	db 11,11,6,8,15,5,13,6
Round6:	dd JJJ,0x50a28be6
	db 5,8,14,9,7,9,0,11
	db 9,13,2,15,11,15,4,5
	db 13,7,6,7,15,8,8,11
	db 1,14,10,14,3,12,12,6
Round7:	dd III,0x5c4dd124
	db 6,9,11,13,3,15,7,7
	db 0,12,13,8,5,9,10,11
	db 14,7,15,7,8,12,12,7
	db 4,6,9,15,1,13,2,11
Round8:	dd HHH,0x6d703ef3
	db 15,9,5,7,1,15,3,11
	db 7,8,14,6,6,6,9,14
	db 11,12,8,13,12,5,2,14
	db 10,13,0,13,4,7,13,5
Round9:	dd GGG,0x7a6d76e9
	db 8,15,6,5,4,8,1,11
	db 3,14,11,14,15,6,0,14
	db 5,6,12,9,2,12,13,9
	db 9,12,7,5,10,15,14,8
Round10: dd FFF,0
	db 12,8,15,5,10,12,4,9
	db 1,12,5,5,8,14,7,6
	db 6,8,2,13,13,6,14,5
	db 0,15,3,13,9,11,11,11

;-----------------------------------------
; return:  eax=(b)^(c)^(d)
FF:
FFF:	xor	ecx,ebx
	xor	ecx,edx
	jmps	endf2

;----------------------------------------
; return:  eax= ( (b)&(c) | (~b)&(d) )
%define var	dword [ebp-24]
GGG:
GG:	and	ecx,ebx
	not	ebx
	and	edx,ebx
	or	ecx,edx
	jmps	endf

;----------------------------------------
; return:  eax=( (b)&(d)  |  (c)&(~d) )
III:
II:	and	ebx,edx
	not	edx
	and	ecx,edx
	or	ecx,ebx
	jmps	endf

;------------------------------------------
; return:  (b)^(c)|(~d)
JJJ:
JJ:	not	edx
	or	ecx,edx
	xor	ecx,ebx
	jmps	endf

;------------------------------------------
; II:  return eax=( (b)| ((~c)^(d) )
HHH:
HH:	not	ecx
	or	ecx,ebx
	xor	ecx,edx
endf:	add	ecx,[esi+4]
endf2:	movzx	edx,byte[esi+8]
	add	ecx,[edi+edx*4]
	add	eax,ecx
	mov	cl,byte[esi+9]
	rol	eax,cl
	add	esi,byte 10
	ret

%endif	;__OPTIMIZE__

;RMD-160 core hashing function
;
;do the calculation in 5 rounds of 16 calls to in order FF,GG,HH,II,JJ
;then one parallel pass of 5 rounds of 16 calls to JJJ,III,HHH,GGG,FFF  
;don't try to understand the code,
;it extensively uses black magic and Voodoo incantations
;
;input:    edi: buffer to process

%define	ee	dword [ebp-4]		;local vars on the stack
%define	dd	dword [ebp-8]
%define	cc	dword [ebp-12]
%define	bb	dword [ebp-16]
%define	aa	dword [ebp-20]

%if	__OPTIMIZE__ = __O_SIZE__

%define	e	dword [ebp-24]
%define	d	dword [ebp-28]
%define	c	dword [ebp-32]
%define	b	dword [ebp-36]
%define	a	dword [ebp-40]

%define	eee	e
%define	ddd	d
%define	ccc	c
%define	bbb	b
%define	aaa	a

;
;macro for calling the FF,GG,HH,II functions
;

%macro invoke_f 5
	mov	eax,%1
	mov	ebx,%2
	mov	ecx,%3
	mov	edx,%4
	call	dword [esi]
	add	eax,%5
	mov	%1,eax
	rol	%3,10
%endmacro

%else	;__O_SPEED__

%define	eee	dword [ebp-24]
%define	ddd	dword [ebp-28]
%define	ccc	dword [ebp-32]
%define	bbb	dword [ebp-36]
%define	aaa	dword [ebp-40]
%define	a	eax
%define	b	ebx
%define	c	ecx
%define	d	edx
%define	e	ebp

%macro invokeff 7
	mov	esi,%2
	xor	esi,%3
	xor	esi,%4
	add	esi,[edi+(%6*4)]
	add	%1,esi
	rol	%1,%7
	add	%1,%5
	rol	%3,10
%endmacro

%macro invokegg 7
	push	%2			;3 (micro-ops for PII family)
	mov	esi,%2			;1
	and	esi,%3			;1
	not	%2			;1
	and	%2,%4			;1
	or	esi,%2			;1
	add	esi,[edi+(%6*4)]	;2
	lea	%1,[%1+esi+0x5a827999]	;1
	rol	%1,%7			;1
	pop	%2			;2
	rol	%3,10			;1
	add	%1,%5			;1
%endmacro

%macro invokehh 7
	mov	esi,%3			;1
	not	esi			;1
	or	esi,%2			;1
	xor	esi,%4			;1
	add	esi,[edi+(%6*4)]	;2
	lea	%1,[%1+esi+0x6ed9eba1]	;1
	rol	%1,%7			;1
	rol	%3,10			;1
	add	%1,%5			;1
%endmacro

%macro invokeii 7
	push	%4			;3
	mov	esi,%4			;1
	and	esi,%2			;1
	not	%4			;1
	and	%4,%3			;1
	or	esi,%4			;1
	add	esi,[edi+(%6*4)]	;2
	lea	%1,[%1+esi+0x8f1bbcdc]	;1
	rol	%1,%7			;1
	pop	%4			;2
	rol	%3,10			;1
	add	%1,%5			;1
%endmacro

%macro invokejj 7
	mov	esi,%4			;1
	not	esi			;1
	or	esi,%3			;1
	xor	esi,%2			;1
	add	esi,[edi+(%6*4)]	;2
	lea	%1,[%1+esi+0xa953fd4e]	;1
	rol	%1,%7			;1
	rol	%3,10			;1
	add	%1,%5			;1
%endmacro

%macro invokejjj 7
	mov	esi,%4
	not	esi
	or	esi,%3
	xor	esi,%2
	add	esi,[edi+(%6*4)]
	lea	%1,[%1+esi+0x50a28be6]
	rol	%1,%7
	rol	%3,10
	add	%1,%5
%endmacro

%macro invokeiii 7
	push	%4			;3
	mov	esi,%4			;1
	and	esi,%2			;1
	not	%4			;1
	and	%4,%3			;1
	or	esi,%4			;1
	add	esi,[edi+(%6*4)]	;2
	lea	%1,[%1+esi+0x5c4dd124]	;1
	rol	%1,%7			;1
	pop	%4			;2
	rol	%3,10			;1
	add	%1,%5			;1
%endmacro

%macro invokehhh 7
	mov	esi,%3
	not	esi
	or	esi,%2
	xor	esi,%4
	add	esi,[edi+(%6*4)]
	lea	%1,[%1+esi+0x6d703ef3]
	rol	%1,%7
	rol	%3,10
	add	%1,%5
%endmacro

%macro invokeggg 7
	push	%2			;3
	mov	esi,%2			;1
	and	esi,%3			;1
	not	%2			;1
	and	%2,%4			;1
	or	esi,%2			;1
	add	esi,[edi+(%6*4)]	;2
	lea	%1,[%1+esi+0x7a6d76e9]	;1
	rol	%1,%7			;1
	pop	%2			;2
	rol	%3,10			;1
	add	%1,%5			;1
%endmacro

%endif

RMD_Transform:

	pusha
	mov	ebp,esp
	sub	esp,byte 40		;protect the local vars space

	cld
	push	edi
	mov	esi,A
	lea	edi,[ebp-40]
	push	esi
	_mov	ecx,5
	push	ecx
	rep	movsd
	pop	ecx			;copy A to E in a-d and aa-dd
	pop	esi
	rep	movsd
	pop	edi

%if	__OPTIMIZE__ = __O_SIZE__

	add	esi,byte (Rounds-LoPart);esi=Rounds

	_mov	ecx,2
.round0:
	push	ecx
	_mov	ecx,16
.round1:
	push	ecx
	invoke_f	a,b,c,d,e
	invoke_f	e,a,b,c,d
	invoke_f	d,e,a,b,c	;do the jerk
	invoke_f	c,d,e,a,b
	invoke_f	b,c,d,e,a
	pop	ecx
	loop	.round1
	pop	ecx
	add	ebp,byte 20
	dec	ecx
	jnz	near .round0
	sub	ebp,byte 40

%else

	push	ebp
	mov	eax,aaa
	mov	ebx,bbb
	mov	ecx,ccc
	mov	edx,ddd
	mov	ebp,eee

;Round 1

	invokeff a,b,c,d,e,0,11
	invokeff e,a,b,c,d,1,14
	invokeff d,e,a,b,c,2,15
	invokeff c,d,e,a,b,3,12
	invokeff b,c,d,e,a,4,5

	invokeff a,b,c,d,e,5,8
	invokeff e,a,b,c,d,6,7
	invokeff d,e,a,b,c,7,9
	invokeff c,d,e,a,b,8,11
	invokeff b,c,d,e,a,9,13

	invokeff a,b,c,d,e,10,14
	invokeff e,a,b,c,d,11,15
	invokeff d,e,a,b,c,12,6
	invokeff c,d,e,a,b,13,7
	invokeff b,c,d,e,a,14,9

	invokeff a,b,c,d,e,15,8

;Round 2

	invokegg e,a,b,c,d,7,7
	invokegg d,e,a,b,c,4,6
	invokegg c,d,e,a,b,13,8
	invokegg b,c,d,e,a,1,13
	invokegg a,b,c,d,e,10,11

	invokegg e,a,b,c,d,6,9
	invokegg d,e,a,b,c,15,7
	invokegg c,d,e,a,b,3,15
	invokegg b,c,d,e,a,12,7
	invokegg a,b,c,d,e,0,12

	invokegg e,a,b,c,d,9,15
	invokegg d,e,a,b,c,5,9
	invokegg c,d,e,a,b,2,11
	invokegg b,c,d,e,a,14,7
	invokegg a,b,c,d,e,11,13

	invokegg e,a,b,c,d,8,12

;Round 3

	invokehh d,e,a,b,c,3,11
	invokehh c,d,e,a,b,10,13
	invokehh b,c,d,e,a,14,6
	invokehh a,b,c,d,e,4,7
	invokehh e,a,b,c,d,9,14

	invokehh d,e,a,b,c,15,9
	invokehh c,d,e,a,b,8,13
	invokehh b,c,d,e,a,1,15
	invokehh a,b,c,d,e,2,14
	invokehh e,a,b,c,d,7,8

	invokehh d,e,a,b,c,0,13
	invokehh c,d,e,a,b,6,6
	invokehh b,c,d,e,a,13,5
	invokehh a,b,c,d,e,11,12
	invokehh e,a,b,c,d,5,7

	invokehh d,e,a,b,c,12,5

;Round 4

	invokeii c,d,e,a,b,1,11
	invokeii b,c,d,e,a,9,12
	invokeii a,b,c,d,e,11,14
	invokeii e,a,b,c,d,10,15
	invokeii d,e,a,b,c,0,14

	invokeii c,d,e,a,b,8,15
	invokeii b,c,d,e,a,12,9
	invokeii a,b,c,d,e,4,8
	invokeii e,a,b,c,d,13,9
	invokeii d,e,a,b,c,3,14

	invokeii c,d,e,a,b,7,5
	invokeii b,c,d,e,a,15,6
	invokeii a,b,c,d,e,14,8
	invokeii e,a,b,c,d,5,6
	invokeii d,e,a,b,c,6,5

	invokeii c,d,e,a,b,2,12

;Round 5

	invokejj b,c,d,e,a,4,9
	invokejj a,b,c,d,e,0,15
	invokejj e,a,b,c,d,5,5
	invokejj d,e,a,b,c,9,11
	invokejj c,d,e,a,b,7,6

	invokejj b,c,d,e,a,12,8
	invokejj a,b,c,d,e,2,13
	invokejj e,a,b,c,d,10,12
	invokejj d,e,a,b,c,14,5
	invokejj c,d,e,a,b,1,12

	invokejj b,c,d,e,a,3,13
	invokejj a,b,c,d,e,8,14
	invokejj e,a,b,c,d,11,11
	invokejj d,e,a,b,c,6,8
	invokejj c,d,e,a,b,15,5

	invokejj b,c,d,e,a,13,6

;000ooo=======---------------

	mov	[var1],ebp
	pop	ebp
	mov	aaa,eax
	mov	bbb,ebx
	mov	ccc,ecx
	mov	ddd,edx
	mov	eax,[var1]
	mov	eee,eax
	push	ebp
	mov	eax,aa
	mov	ebx,bb
	mov	ecx,cc
	mov	edx,dd
	mov	ebp,ee

;Round 6

	invokejjj a,b,c,d,e,5,8
	invokejjj e,a,b,c,d,14,9
	invokejjj d,e,a,b,c,7,9
	invokejjj c,d,e,a,b,0,11
	invokejjj b,c,d,e,a,9,13

	invokejjj a,b,c,d,e,2,15
	invokejjj e,a,b,c,d,11,15
	invokejjj d,e,a,b,c,4,5
	invokejjj c,d,e,a,b,13,7
	invokejjj b,c,d,e,a,6,7

	invokejjj a,b,c,d,e,15,8
	invokejjj e,a,b,c,d,8,11
	invokejjj d,e,a,b,c,1,14
	invokejjj c,d,e,a,b,10,14
	invokejjj b,c,d,e,a,3,12

	invokejjj a,b,c,d,e,12,6

;Round 7

	invokeiii e,a,b,c,d,6,9
	invokeiii d,e,a,b,c,11,13
	invokeiii c,d,e,a,b,3,15
	invokeiii b,c,d,e,a,7,7
	invokeiii a,b,c,d,e,0,12

	invokeiii e,a,b,c,d,13,8
	invokeiii d,e,a,b,c,5,9
	invokeiii c,d,e,a,b,10,11
	invokeiii b,c,d,e,a,14,7
	invokeiii a,b,c,d,e,15,7

	invokeiii e,a,b,c,d,8,12
	invokeiii d,e,a,b,c,12,7
	invokeiii c,d,e,a,b,4,6
	invokeiii b,c,d,e,a,9,15
	invokeiii a,b,c,d,e,1,13

	invokeiii e,a,b,c,d,2,11

;Round 8

	invokehhh d,e,a,b,c,15,9
	invokehhh c,d,e,a,b,5,7
	invokehhh b,c,d,e,a,1,15
	invokehhh a,b,c,d,e,3,11
	invokehhh e,a,b,c,d,7,8

	invokehhh d,e,a,b,c,14,6
	invokehhh c,d,e,a,b,6,6
	invokehhh b,c,d,e,a,9,14
	invokehhh a,b,c,d,e,11,12
	invokehhh e,a,b,c,d,8,13

	invokehhh d,e,a,b,c,12,5
	invokehhh c,d,e,a,b,2,14
	invokehhh b,c,d,e,a,10,13
	invokehhh a,b,c,d,e,0,13
	invokehhh e,a,b,c,d,4,7

	invokehhh d,e,a,b,c,13,5

;Round 9

	invokeggg c,d,e,a,b,8,15
	invokeggg b,c,d,e,a,6,5
	invokeggg a,b,c,d,e,4,8
	invokeggg e,a,b,c,d,1,11
	invokeggg d,e,a,b,c,3,14

	invokeggg c,d,e,a,b,11,14
	invokeggg b,c,d,e,a,15,6
	invokeggg a,b,c,d,e,0,14
	invokeggg e,a,b,c,d,5,6
	invokeggg d,e,a,b,c,12,9

	invokeggg c,d,e,a,b,2,12
	invokeggg b,c,d,e,a,13,9
	invokeggg a,b,c,d,e,9,12
	invokeggg e,a,b,c,d,7,5
	invokeggg d,e,a,b,c,10,15

	invokeggg c,d,e,a,b,14,8

;Round 10

	invokeff b,c,d,e,a,12,8
	invokeff a,b,c,d,e,15,5
	invokeff e,a,b,c,d,10,12
	invokeff d,e,a,b,c,4,9
	invokeff c,d,e,a,b,1,12

	invokeff b,c,d,e,a,5,5
	invokeff a,b,c,d,e,8,14
	invokeff e,a,b,c,d,7,6
	invokeff d,e,a,b,c,6,8
	invokeff c,d,e,a,b,2,13

	invokeff b,c,d,e,a,13,6
	invokeff a,b,c,d,e,14,5
	invokeff e,a,b,c,d,0,15
	invokeff d,e,a,b,c,3,13
	invokeff c,d,e,a,b,9,11

	invokeff b,c,d,e,a,11,11

;000ooo===----------------------------

	mov	[var1],ebp
	pop	ebp
	mov	aa,eax
	mov	bb,ebx
	mov	cc,ecx
	mov	dd,edx
	mov	eax,[var1]
	mov	ee,eax

%endif	;__OPTIMIZE__

	mov	edi,A
	mov	eax,dd
	add	eax,ccc
	add	eax,[edi+4]
	push	eax
	mov	eax,ee
	add	eax,ddd
	add	eax,[edi+8]
	mov	[edi+4],eax
	mov	eax,aa
	add	eax,eee
	add	eax,[edi+12]
	mov	[edi+8],eax
	mov	eax,bb
	add	eax,aaa
	add	eax,[edi+16]
	mov	[edi+12],eax
	mov	eax,cc
	add	eax,bbb
	add	eax,[edi]
	mov	[edi+16],eax
	pop	eax
	mov	[edi],eax	

	add	esp,byte 40
	popa
	ret

;---------------------------------------------
; initialize the RIPEMD-160 engine with the 5 magic constants(_A to _E)
; and clear the LowPart & HighPart counters & the calculation buffer
; then generate the Rounds table from the Round1 to Round8 tables
;
; 1st function to call to calc.RMD160 

RMD_Init:
	pusha
	cld
	mov	edi,A
	mov	eax,_A
	stosd
	mov	eax,_B
	stosd
	mov	eax,_C
	stosd
	mov	eax,_D
	stosd
	mov	eax,_E
	stosd
	xor	eax,eax
	stosd
	stosd
	_mov	ecx,16
	rep	stosd			;clear the buffer

%if	__OPTIMIZE__ = __O_SIZE__

;build Rounds table

	mov	esi,Round1
	_mov	ecx,10
.in1:	push	ecx
	mov	ebx,[esi]		;get func.
	mov	edx,[esi+4]		;get var.
	add	esi,byte 8
	_mov	ecx,16
.in2:	lodsw
	mov	[edi],ebx
	mov	[edi+4],edx
	mov	[edi+8],ax
	add	edi,byte 10
	loop	.in2
	pop	ecx
	loop	.in1

%else	;__O_SPEED__

	mov	[length],eax

%endif	;__OPTIMIZE__

	popa
	ret

;-----------------------------------------------
; the most of the job is done here
; process ecx bytes from esi input buffer
;
; input:	esi=input
;		ecx=number of bytes
RMD_Update:
	pusha
	mov	edi,esi
	mov	edx,ecx
	shr	ecx,6
	jz	.upd1a	
.upd1:	call	RMD_Transform
	add	edi,byte 64
	loop	.upd1
.upd1a:
	mov	esi,LoPart
	mov	eax,[esi]
	mov	ecx,eax
	add	eax,edx
	cmp	eax,ecx
	jge	.upd2
	inc	dword[esi+4]
.upd2:	mov	[esi],eax
	popa
	ret

;--------------------------------------------------------------------
; finalize the job, and write the resulting 160 bits digest RMD code
; in edi buffer (20 bytes length) 
;
; RMD_Final:
;	input:	edi=digest

RMD_Final:
	pusha
	push	edi

%if	__OPTIMIZE__ = __O_SPEED__
	_mov	ecx,16
        mov	edi,buff1
        xor	eax,eax
        rep	stosd
%endif

	mov	esi,buffer
	mov	eax,[LoPart]
	push	eax
	mov	ecx,eax
	mov	edx,eax
	and	eax,(BUFSIZE-64)
	add	esi,eax
	and	ecx,byte 63
	mov	edi,buff1
	push	edi
	rep	movsb

	mov	ebx,edx
	mov	ecx,edx
	shr	edx,2
	and	edx,byte 15
	and	ecx,byte 3
        lea	ecx,[ecx*8+7]
	xor	eax,eax
	inc	eax
	shl	eax,cl
	pop	edi
	xor	[edi+edx*4],eax

	and	ebx,byte 63
	cmp	ebx,byte 55
	jle	.fin2

	call	RMD_Transform
	push	edi
	xor	eax,eax
	_mov	ecx, 16
	rep	stosd
	pop	edi
.fin2:
	pop	eax
	shl	eax,3
	mov	[edi+(14*4)],eax
	mov	eax,[HiPart]
	shr	eax,29
	mov	[edi+(15*4)],eax
	call	RMD_Transform

	pop	edi
	_mov	ecx,5
	mov	esi,A
	rep	movsd
	popa
	ret

UDATASEG

;RMD-160 core registers & buffer
;don't change the order 'cause RMD engine is based on this order

A	resd	1
B	resd	1
C	resd	1
D	resd	1
E	resd	1
LoPart	resd	1
HiPart	resd	1
buff1	resd	16		;calculation buffer

%if	__OPTIMIZE__ = __O_SIZE__

Rounds	resb	(10*16*10)	;to store the expanded Round1 to Round8 tables

%else	;__O_SPEED__

var1	resd	1
length	resd	1

%endif	;__OPTIMIZE__

buffer	resd	BUFSIZE

;
;internal RC6 key
;

l_key	resd	45			
ll	resd	9

;---------------------------------------------------------------------

ibuffer	resb	FBUFSIZE	;input file buffer
obuffer	resb	FBUFSIZE	;output file buffer

action	resb	1		;encrypt/decrypt
flength	resd	1

key1	resd	5
key2	resd	5
key	resd	8

END
