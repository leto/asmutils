;Copyright (C) 1999 Cecchinel Stephan <inter.zone@free.fr>
;
;$Id: md5.asm,v 1.3 2000/12/10 08:20:36 konst Exp $
;
;md5 algorithm, assembly version for asmutils.
;based on the C MD5 algorithm implementation from RSA Labs.
;
;this code is free, you can eat it, drink it, fuck it , as you want...
;just send me a mail if you use it, if you find bugs, or anything else...
;
;the MD5 engine is based on the 3 functions above
;
;usage is simple:
;      let's say	ESI  contains the data to process
;			ECX  the length in bytes of the data block
;so:
;	call	MD5_Init
;	mov	esi,buffer
;	mov	ecx,length
;	call	MD5_Update
;	mov	edi,digest	;adress to store the resulting MD5 hash value
;	call	MD5_Final
;
;and it finish, digest is the resulting 16 byte (128 bit) MD5 hash value.
;Once the MD5 engine is initialized with MD5_Init, you can call MD5_Update
;a number of times you want to process data in multiple blocks,
;you have the MD5 hash value when you call MD5_Final
;
;10-Sep-2000 (KB)
;	cleanup and size optimization

%include "system.inc"

CODESEG

	global MD5_Init
	global MD5_Update
	global MD5_Final

;magic initialization constants

%assign _A	0x67452301
%assign _B	0xefcdab89
%assign _C	0x98badcfe
%assign _D	0x10325476

;MD5 core constants, bit shifts, offsets, and functions addresses
;(never change the order)

Round1:	dd FF
	dd 0xd76aa478
	db 0,7
	dd 0xe8c7b756
	db 1,12
	dd 0x242070db
	db 2,17
	dd 0xc1bdceee
	db 3,22
	
	dd 0xf57c0faf
	db 4,7
	dd 0x4787c62a
	db 5,12
	dd 0xa8304613
	db 6,17
	dd 0xfd469501
	db 7,22
	
	dd 0x698098d8
	db 8,7
	dd 0x8b44f7af
	db 9,12
	dd 0xffff5bb1
	db 10,17
	dd 0x895cd7be
	db 11,22
	
	dd 0x6b901122
	db 12,7
	dd 0xfd987193
	db 13,12
	dd 0xa679438e
	db 14,17
	dd 0x49b40821
	db 15,22

Round2:	dd GG,
	dd 0xf61e2562
	db 1,5
	dd 0xc040b340
	db 6,9
	dd 0x265e5a51
	db 11,14
	dd 0xe9b6c7aa
	db 0,20
	
	dd 0xd62f105d
	db 5,5
	dd 0x2441453
	db 10,9
	dd 0xd8a1e681
	db 15,14
	dd 0xe7d3fbc8
	db 4,20
	
	dd 0x21e1cde6
	db 9,5
	dd 0xc33707d6
	db 14,9
	dd 0xf4d50d87
	db 3,14
	dd 0x455a14ed
	db 8,20
	
	dd 0xa9e3e905
	db 13,5
	dd 0xfcefa3f8
	db 2,9
	dd 0x676f02d9
	db 7,14
	dd 0x8d2a4c8a
	db 12,20
	
Round3:	dd HH
	dd 0xfffa3942
	db 5,4
	dd 0x8771f681
	db 8,11
	dd 0x6d9d6122
	db 11,16
	dd 0xfde5380c
	db 14,23
	
	dd 0xa4beea44
	db 1,4
	dd 0x4bdecfa9
	db 4,11
	dd 0xf6bb4b60
	db 7,16
	dd 0xbebfbc70
	db 10,23
	
	dd 0x289b7ec6
	db 13,4
	dd 0xeaa127fa
	db 0,11
	dd 0xd4ef3085
	db 3,16
	dd 0x4881d05
	db 6,23
	
	dd 0xd9d4d039
	db 9,4
	dd 0xe6db99e5
	db 12,11
	dd 0x1fa27cf8
	db 15,16
	dd 0xc4ac5665
	db 2,23

Round4:	dd II
	dd 0xf4292244
	db 0,6
	dd 0x432aff97
	db 7,10
	dd 0xab9423a7
	db 14,15
	dd 0xfc93a039
	db 5,21
	
	dd 0x655b59c3
	db 12,6
	dd 0x8f0ccc92
	db 3,10
	dd 0xffeff47d
	db 10,15
	dd 0x85845dd1
	db 1,21
	
	dd 0x6fa87e4f
	db 8,6
	dd 0xfe2ce6e0
	db 15,10
	dd 0xa3014314
	db 6,15
	dd 0x4e0811a1
	db 13,21
	
	dd 0xf7537e82
	db 4,6
	dd 0xbd3af235
	db 11,10
	dd 0x2ad7d2bb
	db 2,15
	dd 0xeb86d391
	db 9,21

;initialize MD5 engine with the 4 magic constants(_A to _D),
;clear the LowPart & HighPart counters & calculation buffer
;1st function to call to calc.MD5

MD5_Init:
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
	xor	eax,eax
	stosd
	stosd
	mov	edi,buff1
	_mov	ecx,16
	rep	stosd			;clear buffer
	popa
	ret

;
;macro for calling the FF,GG,HH,II functions
;

%macro invoke_f 4
	mov	eax,%1
	mov	ebx,%2
	mov	ecx,%3
	mov	edx,%4
	call	calling
%endmacro

;----------------------------------------
; return:  eax= ( (b)&(c) | (~b)&(d) )
FF:
	and	ecx,ebx
	not	ebx
	and	edx,ebx
	or	ecx,edx
	not	ebx
	jmps	endf

;----------------------------------------
; return:  eax=( (b)&(d)  |  (c)&(~d) )
GG:
	not	edx
	and	ecx,edx
	not	edx
	and	edx,ebx
	or	ecx,edx
	jmps	endf

;-----------------------------------------
; return:  eax=(b)^(c)^(d)
HH:
	xor	ecx,ebx
	xor	ecx,edx
	jmps	endf

;------------------------------------------
; II:  return eax=( (c)^ ((b)|(~d) )
II:
	not	edx
	or	edx,ebx
	xor	ecx,edx
endf:	add	ecx,[esi]
	movzx	edx,byte[esi+4]
	add	ecx,[edi+edx*4]
	add	eax,ecx
	mov	cl,[esi+5]
	rol	eax,cl
	add	eax,ebx
	add	esi,byte 6
	ret

;---------------------------------------------------
;MD5 core hashing function
;do the calculation in 4 rounds of 16 calls to in order FF,GG,HH,II
;
;input:    edi: buffer to process

MD5_Transform:

%define a	dword [ebp-4]		;local vars on the stack
%define b	dword [ebp-8]
%define	c	dword [ebp-12]
%define	d	dword [ebp-16]
%define calling	dword [ebp-20]

	pusha
	mov	ebp,esp
	sub	esp,byte 20		;protect the local vars space
	cld
	mov	esi,A
	lodsd
	mov	a,eax
	lodsd
	mov	b,eax
	lodsd
	mov	c,eax
	lodsd
	mov	d,eax

	mov	esi,Round1
	_mov	ecx,4
.round0:
	push	ecx
	lodsd
	mov	calling,eax		;each new round get the address of the new function to call
	_mov	ecx,4			;stored at the begginning of each Rounds tables
.round1:
	push	ecx
	invoke_f	a,b,c,d
	mov	a,eax
	invoke_f	d,a,b,c
	mov	d,eax
	invoke_f	c,d,a,b		;do the jerk
	mov	c,eax
	invoke_f	b,c,d,a
	mov	b,eax
	pop	ecx
	loop	.round1
	pop	ecx
	loop	.round0

	mov	edi,A
	mov	eax,a
	add	[edi],eax
	mov	eax,b
	add	[edi+4],eax
	mov	eax,c
	add	[edi+8],eax
	mov	eax,d
	add	[edi+12],eax
	add	esp,byte 20
	popa
	ret

;-----------------------------------------------
; the most of the job is done here
; process ecx bytes from esi input buffer
;
; input:	esi=input
;		ecx=number of bytes

MD5_Update:
	pusha
	mov	edi,LoPart

	mov	edx,[edi]		;edx=t=LowPart
	lea	eax,[edx+ecx*8]
	mov	[edi],eax		;LowPart+=(number of byte)<<3

	cmp	eax,edx
	jae	.upd0
	inc	dword[edi+4]
.upd0:	mov	ebx,ecx
	shr	ebx,29
	add	[edi+4],ebx		;HighPart+=(length of byte)>>29

	cld
	shr	edx,3
	and	edx,0x3f
.upd_loop:
	jz	.upd2
	lea	edi,[edi+edx+(buff1-LoPart)]	;edi=buff1+t

	_mov	eax,64
	sub	eax,edx
	mov	edx,eax
	cmp	ecx,edx
	jl	.updfin			;memcpy(buff1+t,input,len)
.upd1:
	push	ecx
	mov	ecx,edx
	rep	movsb			;memcpy(buff1+t,input,t)
	mov	edi,buff1
	call	MD5_Transform
	pop	ecx
	sub	ecx,edx			;len-=t
.upd2:	mov	edi,buff1
.upd2b:
	cmp	ecx,byte 64
	jl	.updfin
	push	ecx
	push	edi
	_mov	ecx,16
	rep	movsd
	pop	edi
	call	MD5_Transform
	pop	ecx
	sub	ecx,byte 64
	jmp	.upd2b
.updfin:
	rep	movsb
	popa
	ret

;--------------------------------------------------------------------
; finalize the job, and write the resulting 128 bits digest MD5 code
; in edi buffer (16 bytes length) 
;
; MD5_Final:
;	input:	edi=digest

MD5_Final:
	pusha
	push	edi

	mov	edi,LoPart
	mov	edx,[edi]
	shr	edx,3
	and	edx,0x3f		;edx=t=((LowPart>>3)&0x3f)

	lea	edi,[edi+edx+(buff1-LoPart)]	;edi=buff1+t
	mov	byte[edi],0x80
	_mov	eax,63
	sub	eax,edx
	mov	edx,eax			;t=63-t
	inc	edi
	cld
	xor	eax,eax
	cmp	edx,byte 7
	ja	.final1

	mov	ecx,edx
	rep	stosb			;memset(buff1+t+1,0,t)
	mov	edi,buff1
	call	MD5_Transform
	_mov	ecx,14
	rep	stosd			;memset(buff1,0,56)
	jmps	.final2
.final1:
	sub	edx,byte 8
	mov	ecx,edx
	rep	stosb			;memset(buff1+t+1,0,t-8)
.final2:
	mov	esi,LoPart
	mov	edi,buff1
	lodsd
	mov	[edi+(14*4)],eax
	lodsd
	mov	[edi+(15*4)],eax
	call	MD5_Transform
	pop	edi
	_mov	ecx,4
	lea	esi,[esi-((LoPart+8)-A)]
	rep	movsd
	popa
	ret

UDATASEG

;=============--------------------------------------------------------
; MD5 core registers & buffer
; don't change the order 'cause MD5 engine is based on this order

A	resd	1
B	resd	1
C	resd	1
D	resd	1
LoPart	resd	1
HiPart	resd	1
buff1	resd	16

END
