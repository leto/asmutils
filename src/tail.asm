;Copyright (C) 2001 Jani Monoses <jani@astechnix.ro>
;
;$Id: tail.asm,v 1.5 2002/08/15 16:08:33 konst Exp $
;
;hackers' tail
;
;syntax: tail [-n lines] [FILE]
;	 tail -n CHARSc [FILE]
;
;Revision history:
;	0.1	Initial revision (JM)
;	0.2	Added support for -n CHARSc (JH)
	
%include "system.inc"

%assign BUFSIZE		0x4000		;16K - max guarranteed size of tail 

CODESEG
START:		
		mov	esi, $ + 1	; important!  esi must be readable
		mov	byte [lines],10 ;default line count
		_mov	ebp,STDIN	;default input file
		pop	ecx		;argc
		dec	ecx
		jz	.go		;if no args assume defaults
		pop	ebx
		pop 	ebx
;		cmp	byte[ebx],'+'	; tail+ (maybe later... )
;		je	plus		; if someone wants to implement this
		cmp	byte[ebx],"-"	; Not an option
		jne	.file
		mov	esi, ebx
		inc	esi
		cmp	byte[esi],"n"	;option or filename?
		jne	.firstchar
		pop	esi		;line count

;put line count from ascii representation in ebx
.firstchar:	
		xor	ebx,ebx
		xor	eax,eax
.nextchar:
		lodsb
		sub	al,'0'
		jb	.endconvert
		cmp	al, 9
		jg	.endconvert
		imul	ebx,byte 10
		add	ebx,eax	
		jmp	short .nextchar
.endconvert:	
		mov	[lines],ebx	
;		dec	ecx		;eat two args 
;		dec	ecx
;		jz	.go		;no file name: assume STDIN
		pop	ebx		;file name (last argument)
		or	ebx, ebx
		jz	.go		;no file name: assume STDIN
.file:
		sys_open	ebx,O_RDONLY
		test	eax,eax
		js	near dexit
		mov	ebp,eax		;save file descriptor

;if regular file seek to last BUFSIZE bytes.Especially good for large files.
.go:	
		sys_fstat ebp,statbuf
		test	dword[statbuf.st_mode],S_IFREG		
		jz	.gogo				;if !regular file
		mov	ebx,[statbuf.st_size]
		sub	ebx,BUFSIZE
		jbe	.gogo				;or size < BUFSIZE
		sys_lseek ebp,ebx,SEEK_SET
.gogo:							;just read
		mov	ecx,buf
		dec	esi
		cmp	[esi], byte 'c'
		je	tailchar

;reads the input in BUFSIZE sized chunks
;and moves the buffers to prevent overflow 
.readinput:
		sys_read ebp,ecx,BUFSIZE		
		test	eax,eax
		js	dexit
		jz	writebuffer
		add	ecx,eax
		cmp	ecx,safety
		jle	.readinput
		push	dword	.readinput	; False call!

bufcopy:
		push	ecx
		mov	edi,buf
		mov	esi,buf2
		sub	ecx,esi
		rep	movsb
		pop	ecx
		sub	ecx,BUFSIZE
		ret

dexit:		
		sys_exit

;walk through the buffer from end to beginning and stop 
;when enough newlines are encountered
writebuffer:	
		cmp	ecx,buf
		jz	dexit
		mov	edx,ecx
		mov	ebx,[lines]
		inc	ebx
		dec	ecx

.nl:		
		dec	ebx
		jz	.tail
.searchnl:
		dec	ecx
		cmp	ecx,buf			;start of buffer reached?
		jz	.endbuf
		cmp	byte[ecx],10		;is it a newline char ?
		jz	.nl
		jmp	short .searchnl		
.tail:
		inc	ecx
.endbuf:
		sub	edx,ecx
		sys_write	STDOUT,ecx,edx 
		jmps	dexit

;read from the buffer to find the last [lines] bytes
tailchar:
	mov	ecx, buf
	mov	ebx, ebp
	_mov	edx, BUFSIZE
.read:
	sys_read
	or	eax, eax
	js	dexit
	jz	.write
	add	ecx, eax
	cmp	ecx, safety
	jb	.read
	call	bufcopy
	jmps	.read

.write:
	mov	edx, [lines]
	sub	ecx, edx		; ECX = read back
	mov	eax, buf		; EAX = start of buffer
	cmp	ecx, eax		; Check for undeflow
	jnb	.wwrite
	xchg	eax, ecx		; ECX = start of buffer
	sub	eax, ecx		; EAX = -underflowsize
	add	edx, eax		; output size to total buf size
.wwrite:
	sys_write	STDOUT
	jmp	dexit

UDATASEG
	lines	resd	1	
	buf	resb	BUFSIZE
	buf2	resb	BUFSIZE
	safety	resb	BUFSIZE
	statbuf	B_STRUC	Stat,.st_mode,.st_size
END
