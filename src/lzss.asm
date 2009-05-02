;Copyright (C) 1999 Cecchinel Stephan <interzone@pacwan.fr>
;
;$Id: lzss.asm,v 1.6 2006/02/09 07:59:23 konst Exp $
;
;hackers' lzss
;
;syntax: lzss e|d [file]
;
;LZSS compression algorithm implementation
;
;Warning: result is send to stdout,
;if no file is given - reads stdin
;
;decoding is not supported yet :)
;
;0.01: 19-Dec-1999	inital release (CS)
;0.02: 12-Sep-2000	cleanup and size improvements (KB)
;0.03: 11-Jan-2001	outfile fix (KB)

%include "system.inc"

CPU 486

%assign	N_BITS	15
%assign	F_BITS	4
%assign	N	(1<<N_BITS)
%assign	F	(1<<F_BITS)
%assign	THRESHOLD	3
%assign	FBUFFSIZE	16384		;i/o file buffer size (16k by default) must be a 2^x
%assign	BUFFCYCL	((FBUFFSIZE/4)-1)

CODESEG

text1	db	"Usage: lzss e|d file",__n
_len1	equ	($-text1)
%assign	len1	_len1

text2	db	"Can't open input file",__n
_len2	equ	($-text2)
%assign	len2	_len2

START:
	_mov	ebp,STDIN
	_mov	[outfile],byte STDOUT

	pop	eax
	dec	eax
	pop	edi

	dec	eax
	js	.usage
	pop	edi
	dec	eax
	js	.read
	pop	ebx
	sys_open EMPTY,O_RDONLY
	mov	ebp,eax
	test	eax,eax
	jns	.read
	sys_write STDOUT,text2,len2
	jmps	.quit
.usage:
	sys_write STDOUT,text1,len1
	jmps	.quit

.read:
	mov	[infile],ebp
	mov	eax,lzss_encode
	cmp	byte[edi],'e'
	jz	.call_it
	mov	eax,lzss_decode
	cmp	byte[edi],'d'
	jnz	.usage
.call_it:
	call	eax
.quit:
	sys_exit_true


;-------------------------------------------
; initialize ring_buff,prev,next
;	   edi=ring_buff

init_lzss:
	pusha
	mov	ecx,((N+F)/4)
	xor	eax,eax
	mov	dword[edi-(ring_buff-bit_pos)],31
	mov	[edi-(ring_buff-bit_val)],eax
	mov	[edi-(ring_buff-output)],eax

	rep	stosd
					;normally edi point on next (as next follow ring_buff)
	mov	ecx,((N*3)+2)
	mov	eax,N
	rep	stosd
	popa
	ret

;-----------------------------------------
; input:   eax=r
;	   edi=ring_buff

delete:
	push	ebx
	push	ecx
	push	edx
	mov	edx,N
	mov	ebx,[edi+(prev-ring_buff)+eax*4]	;ebx=prev[r]
	cmp	ebx,edx
	je	.fdel
	mov	ecx,[edi+(next-ring_buff)+eax*4]				; ecx=next[r]
	mov	[edi+(next-ring_buff)+ebx*4],ecx				; next[prev[r]]=next[r]
	mov	[edi+(prev-ring_buff)+ecx*4],ebx	;prev[next[r]]=prev[r]
	mov	[edi+(next-ring_buff)+eax*4],edx				; next[r]=N
	mov	[edi+(prev-ring_buff)+eax*4],edx	;prev[r]=N
.fdel:	pop	edx
	pop	ecx
	pop	ebx
	ret

;---------------------------------------------
; input:	eax=r
;		edi=ring_buff

insert:
	push	edx
	push	ecx
	push	ebx
	mov	bx,[edi+eax]
	and	ebx,(N-1)		;ebx=(ring_buf[r]+(ring_buf[r+1]<<8))& (N-1)
	mov	ecx,[edi+ebx*4+((N+1)*4)+(next-ring_buff)]	;ecx=next[c+N+1]
	mov	[edi+ebx*4+((N+1)*4)+(next-ring_buff)],eax	;next[c+N+1]=r
	lea	edx,[ebx+(N+1)]
	mov	[edi+(prev-ring_buff)+eax*4],edx		;prev[r]=ebx+N+1
	mov	[edi+eax*4+(next-ring_buff)],ecx		;next[r]=ecx
	cmp	ecx,N
	je	.fins
	mov	[edi+(prev-ring_buff)+ecx*4],eax				; prev[ecx]=r
.fins:	pop	ebx
	pop	ecx
	pop	edx
	ret

;-------------------------------------------------
; input:	eax=r
;		edi=ring_buff

locate:
	push	ebx
	push	ecx
	push	edx
	push	esi
	
	xor	ecx,ecx
	mov	[edi+(match_pos-ring_buff)],ecx		;match_pos=match_len=0
	mov	[edi+(match_len-ring_buff)],ecx		;match_pos=match_len=0
	mov	bx,[edi+eax]
	and	ebx,(N-1)				;ebx=(ring_buf[r]+(ring_buf[r+1]<<8))& (N-1)
	mov	ecx,[edi+ebx*4+((N+1)*4)+(next-ring_buff)]	;ecx=p=next[c+N+1]
	xor	edx,edx					;i=edx=0

.loc0:	cmp	ecx,N
	je	.loc4
	xor	edx,edx
	push	ebx
	push	eax
	lea	esi,[edi+ecx]
	lea	ebx,[edi+eax]
.loc1:	mov	al,[esi+edx]
	cmp	al,[ebx+edx]
	jne	.loc2
	inc	edx
	cmp	edx,F
	jbe	.loc1
.loc2:	pop	eax
	pop	ebx
	cmp	edx,[edi+(match_len-ring_buff)]		;if i>match_len
	jbe	.loc3
	mov	[edi+(match_len-ring_buff)],edx		;match_len=i
	push	eax
	sub	eax,ecx
	and	eax,(N-1)
	mov	[edi+(match_pos-ring_buff)],eax 	;match_pos=(r-next[c+N+1])&(N-1)
	pop	eax
.loc3:	cmp	edx,F
	je	.flocate
	mov	ecx,[edi+ecx*4+(next-ring_buff)]	;ecx=next[ecx]
	jmps	.loc0
.loc4:	cmp	edx,F
	jne	.floc
.flocate:
	mov	eax,ecx
	call	delete		;delete(p)
.floc:
	pop	esi
	pop	edx
	pop	ecx
	pop	ebx
	ret

;------------------------------------------
; macros definition needed by lzss_encode
%macro _sendbit0 0
	_mov	eax,0
	call	sendbit
%endmacro
%macro _sendbit1 0
	_mov	eax,1
	call	sendbit
%endmacro

;--------------------------------------

lzss_encode:
	pusha
	cld
	mov	edi,ring_buff
	call	init_lzss
	xor	edx,edx			;maxlen=edx=0
	xor	ebx,ebx			;r=0
	
	call	get_inbuff		;get a FBUFFSIZE length block in inbuff

.enc0:	cmp	edx,F
	jge	.enc1
	test	ecx,ecx
	jnz	.enc0a
	call	get_inbuff		;if whole inbuff is read try to get another FBUFFSIZE length block,
	test	ecx,ecx			;if no more are available, get_inbuff return ecx=0
	jz	.enc1
.enc0a:	lodsb
	dec	ecx
	mov	[edi+edx],al
	mov	[edi+edx+N],al
	inc	edx			;maxlen++
	jmps	.enc0

.enc1:	test	edx,edx
	jz	near .fenc1
	mov	eax,ebx
	call	locate								; locate(r)
	cmp	edx,[edi+(match_len-ring_buff)]
	jge	.enc2
	mov	[edi+(match_len-ring_buff)],edx		;match_len=maxlen

.enc2:	push	ecx
	cmp	dword[edi+(match_len-ring_buff)],THRESHOLD
	jge	short .enc3

	_sendbit0
	xor	eax,eax
	inc	eax										; after _sendbit0 eax=0 so now eax=1
	mov	[edi+(match_len-ring_buff)],eax	;match_len=1
	movzx	eax,byte[edi+ebx]		;al=ring_buff[r]
	mov	cl,8
	call	sendbits			;sendbits(ring_buff[r],8)
	jmps	.enc23
.enc3:
	_sendbit1
	mov	eax,[edi+(match_pos-ring_buff)]
	mov	cl,N_BITS
	call	sendbits
	mov	eax,[edi+(match_len-ring_buff)]
	dec	eax
	mov	cl,F_BITS
	call	sendbits
.enc23:	pop	ecx

.enc4:	mov	eax,[edi+(match_len-ring_buff)]
	test	eax,eax
	jz	.enc1
	dec	eax
	mov	[edi+(match_len-ring_buff)],eax

	lea	eax,[ebx+F]
	and	eax,(N-1)
	call	delete			;delete( (r+F) & (N-1) )
	dec	edx			;maxlen--

	push	ebx
	test	ecx,ecx
	jnz	.enc41
	call	get_inbuff
	test	ecx,ecx
	jz	.enc5
.enc41:	lodsb
	_add	ebx,F
	cmp	ebx,N
	jl	.enc4b
	mov	byte[edi+ebx],al
.enc4b:	and	ebx,(N-1)
	mov	byte[edi+ebx],al
	inc	edx			;maxlen++
	dec	ecx
.enc5:	pop	ebx

	mov	eax,ebx
	call	insert			;insert(r)
	inc	eax
	and	eax,(N-1)
	mov	ebx,eax			;r=(r+1)&(N-1)
	jmps	.enc4
.fenc1:
	_sendbit1
	xor	eax,eax
	mov	cl,N_BITS
	call	sendbits
	call	flushbuff
	popa
	ret


;----------------------------------------
lzss_decode:

;------------------------------------------
; input: 	eax=bits pattern
;		cl=bit_length
;
sendbits:
	push	ebx
	mov	ebx,eax
	dec	ecx
	and	ecx,byte 0x1f
	xor	eax,eax
.boucle:
	bt	ebx,ecx
	setc	al
	call	sendbit
	dec	ecx
	jns	.boucle
	pop	ebx
	ret

;------------------------------------------
; input: eax=0 or 1
;	 edi point on ring_buff

sendbit:
	push	edi
	push	ecx
	xor	ecx,ecx
	inc	ecx
	and	eax,ecx
	lea	edi,[edi-(ring_buff-outbuff)]
	mov	ecx,[edi+(bit_pos-outbuff)]
	test	ecx,ecx
	jz	.send2
	shl	eax,cl
	or	[edi+(bit_val-outbuff)],eax
	dec	dword[edi+(bit_pos-outbuff)]

	pop	ecx
	pop	edi
	ret
.send2:
	or	eax,[edi+(bit_val-outbuff)]
	mov	ecx,[edi+(output-outbuff)]
	bswap	eax
	mov	[edi+ecx*4],eax
	inc	ecx
	and	ecx,BUFFCYCL
	jz	.sendbuff
.send3:	xor	eax,eax
	mov	[edi+(output-outbuff)],ecx
	mov	dword [edi+(bit_pos-outbuff)],31
	mov	[edi+(bit_val-outbuff)],eax
	pop	ecx
	pop	edi
	ret
.sendbuff:
	pusha
	sys_write [outfile],outbuff,FBUFFSIZE
	popa
	jmps	.send3

;------------------------------------------
; input:	edi point on ring_buff

flushbuff:
	lea	ecx,[edi-(ring_buff-outbuff)]
	mov	ebx,[edi-(ring_buff-outfile)]

	mov	eax,[edi-(ring_buff-bit_val)]
	mov	edx,[edi-(ring_buff-output)]
	mov	[ecx+edx*4],eax
	inc	edx
	shl	edx,2
	sys_write
	ret

;------------------------------------------
; get_inbuff:	refill the input buffer
;
;	return number of byte read in ecx
;	and inbuff addr in esi

get_inbuff:
	push	eax
	push	ebx
	push	edx
	push	edi
	
	sys_read [infile],inbuff,FBUFFSIZE
	xor	ecx,ecx
	test	eax,eax
	jz	.endin
	js	.endin
	mov	ecx,eax
.endin:	mov	esi,inbuff
	pop	edi
	pop	edx
	pop	ebx
	pop	eax
	ret

UDATASEG
	
;------------------------ file in/out descriptors
infile	resd	1
outfile	resd	1
inbuff	resd	(FBUFFSIZE/4)
outbuff	resd	(FBUFFSIZE/4)
;------------------------ bits i/o vars
output	resd	1
bit_pos	resd	1
bit_val	resd	1
;------------------------ lzss internal engine
ring_buff	resb	(N+F)
next		resd	((N*2)+1)
prev		resd	(N+1)
match_pos	resd	1
match_len	resd	1
;------------------------
outname		resb	256

END
