;Copyright (C) 1999 Cecchinel Stephan <interzone@pacwan.fr>
;
;$Id: rmd.asm,v 1.3 2000/12/10 08:20:36 konst Exp $
;
;calculate the RIPEMD-160 checksum
;
;this code is free, you can eat it, drink it, fuck it , as you want...
;just send me a mail if you use it, if you find bugs, or anything else...
;
;The RIPEMD-160 algorithm is a 160bit checksum algorithm, it is more
;secure than MD5 algo at the time I write this 7 oct 1999 01:31 am.
;No weakness in this algorithm has been found and the creators
;of the algo tell that for some years it will stay enough secure.
;MD5 algorithm has been proven to be insecure, and should not be
;used anymore for sensible information...
;
;usage is very simple:
;first you call RMD_Init for initialisation of the engine (no input)
;then you call RMD_Update with esi=buffer, ecx=number of bytes to process
;
;RMD_Update calculates the checksum of data block, you can process a file
;in one block or in several blocks, you just have to call RMD_Init to
;re-initialise the RMD engine at the beginning of each new checksum
;
;When you have processed all the file, just call RMD_Final with edi=checksum,
;edi points to 40 byte long buffer to store the 160 bit resulting checksum.
;
;10-Sep-2000 (KB):
;	serious cleanup and rearrangement
;	speed optimized version merged

%include "system.inc"

CODESEG

	global RMD_Init
	global RMD_Update
	global RMD_Final

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
	mov	ebx,[esi]		; get func.
	mov	edx,[esi+4]		; get var.
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

END
