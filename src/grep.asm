;Copyright (C) 1999-2002 Konstantin Boldyshev <konst@linuxassembly.org>
;
;$Id: grep.asm,v 1.6 2002/02/18 06:46:47 konst Exp $
;
;hackers' grep
;
;syntax: grep [-b] [-c] [-q] [-v] PATTERN [file...]
;
;-b	print byte offset before each line of output
;-c	print count of matching lines for each file (instead of actual lines)
;-q	be quiet (supress output, only set exit code)
;-v	invert matching (select non-matching lines)
;
;there's no support for regexp, only pure string patterns.
;returns 0 on success (if pattern was found), 1 otherwise
;
;0.01: 19-Dec-1999	initial release (dumb and slow version)
;0.02: 14-Feb-2002	added -v option
;0.03: 18-Feb-2002	added -b, -c options,
;			output filename when grepping several files

%include "system.inc"

CODESEG

%assign	_q	00000001b
%assign	_v	00000010b
%assign	_c	00000100b
%assign	_b	10000000b

%assign	BUFSIZE	0x4000

do_exit:
	sys_exit [retcode]

START:
	_mov	ebp,STDIN	;file handle (STDIN if no args)
	mov	[retcode],byte 1

	pop	ebx
	dec	ebx
	jz	do_exit

	pop	esi
.s0:
	pop	edi		;get pattern

	cmp	word [edi],"-q"
	jnz	.s2
	or	al,_q
.s1:
	dec	ebx
	jmps	.s0
.s2:
	cmp	word [edi],"-c"
	jnz	.s3
	or	al,_c
	jmps	.s1
.s3:
	cmp	word [edi],"-b"
	jnz	.s4
	or	al,_b
	jmps	.s1
.s4:
	cmp	word [edi],"-v"
	jnz	.proceed
	or	al,_v
	jmps	.s1

.proceed:
	mov	[flag],byte al
	dec	ebx
	jz	.mainloop	;if no args - read STDIN
	mov	[argc],ebx

.next_file:
	pop	ebx		;pop filename pointer
	or	ebx,ebx
	jz	do_exit		;exit if no more agrs

	xor	eax,eax
	mov	[count],eax
	mov	[realoff],eax
	mov	[fname],ebx

; open O_RDONLY

	sys_open EMPTY,O_RDONLY
	mov	ebp,eax
	test	eax,eax
	js	.next_file

.mainloop:
	mov	esi,buf
	call	gets
	cmp	[tmp], byte 0
	jz	.find
	
	test	[flag],byte _c
	jz	.next_file

	call	write_fname
	call	write_count
	jmps	.next_file

.find:
	call	strstr

	mov	edx,[flag]

	test	eax,eax
	setz	bh
	test	dl,_v
	setz	bl

	xor	bl,bh
	jz	.mainloop

.match:
	mov	[retcode],byte 0
	test	dl,_q
	jnz	.mainloop

	inc	dword [count]
	test	dl,_c
	jnz	.mainloop
	
	call	write_fname
	call	write_byteoff

    	call	strlen
	sys_write STDOUT,esi,eax

	jmp	.mainloop

;
;
;

write_fname:
	cmp	[argc],byte 1
	jbe	.return
	pusha
	mov	esi,[fname]
	call	strlen
	mov	byte [esi+eax],':'
	inc	eax
	sys_write STDOUT,esi,eax
	mov	byte [esi+eax-1],0
	popa
.return:
	ret

write_byteoff:
	test	[flag],byte _b
	jz	.return

	pusha
	mov	eax,[byteoff]
	call	itoa

	mov	byte [edi],':'
	mov	edx,edi
	sub	edx,esi
	inc	edx
	sys_write STDOUT,esi
	popa
.return:
	ret

write_count:
	pusha
	mov	eax,[count]
	call	itoa
	mov	byte [edi],__n
	mov	edx,edi
	sub	edx,esi
	inc	edx
	sys_write STDOUT,esi
	popa
	ret

itoa:
	_mov	edi,itoabuf
	_mov	ecx,10
	mov	esi,edi

.printB:
	sub	edx,edx 
	div	ecx 
	test	eax,eax 
	jz	.print0
	push	edx
	call	.printB
	pop	edx
.print0:
	add	dl,'0'
	cmp	dl,'9'
	jle	.print1
	add	dl,0x27
.print1:
	mov	[edi],dl
 	inc	edi
 	ret


;esi	-	buffer
gets:
	pusha
	mov	[tmp], byte 1

	push	dword [realoff]
	pop	dword [byteoff]

.read_byte:
	sys_read ebp,tmp,1
	cmp	eax,edx
	jnz	.return

	inc	dword [realoff]

	mov	al,[tmp]
	mov	[esi],al
	inc	esi
	cmp	al,__n
	jnz	.read_byte
;	dec	esi
	mov	[esi],byte 0
	mov	[tmp],byte 0

.return:
	popa
	ret

;very dumb but short strstr
;
;esi	-	haystack
;edi	-	needle

strstr:
	push	esi
	push	edi

	xor	eax,eax
	cmp	[esi],byte 0
	jz	.rets

	push	esi
	mov	esi,edi
	call	strlen
	mov	ecx,eax
	pop	esi
	or	ecx,ecx
	jz	.return	

.next:
	xor	eax,eax

	push	ecx
	push	edi
	repz	cmpsb
	pop	edi
	pop	ecx
	jz	.rets
	cmp	[esi],byte 0
	jnz	.next
	jmp	short .return
	
.rets:
	mov	eax,esi

.return:
	pop	edi
	pop	esi
	ret

strlen:
	push	edi
	mov	edi,esi
	mov	eax,esi
	dec	edi
.l1:
	inc	edi
	cmp	[edi],byte 0
	jnz	.l1
	xchg	eax,edi
	sub	eax,edi
	pop	edi
	ret

UDATASEG

argc	resd	1
fname	resd	1
count	resd	1
realoff	resd	1
byteoff	resd	1

retcode	resd	1
tmp	resb	1
flag	resb	1
itoabuf	resb	0x10
buf	resb	BUFSIZE

END
