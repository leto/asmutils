;Copyright (C) 2000 Jonathan Leto <jonathan@leto.net>
;
;$Id: head.asm,v 1.4 2002/02/02 08:49:25 konst Exp $
;
;hackers' head
;
;syntax: head [-n #] [-c #] file [file] ... 
;
;return 0 on success, 1 on error
;ascii_to_num from strings.asm by Dmitry Bakhvalov <dl@gazeta.ru>
;
;This is slightly over-commented, hopefully someone can learn from it.
;
;Version 0.1 - Sun Dec 10 00:01:52 EST 2000 
;Version 0.2 - Tue Oct 09 12:24:26 EST 2001 - Fixed reading from stdin -JH

%include "system.inc"

%assign	BUFSIZE	0x2000

;ebp = file descriptor
;edi = return code

CODESEG

START:   
	_mov	[chars],dword 0		; lines by default
	_mov	[lines],dword 10	; default to 10 lines
	_mov	edi,0			; default return value
	_mov	ebp,STDIN		; default file descriptor
	pop	ebx			; argc
	dec	ebx			 
	pop	ebx			; argv[0], program name
	jz 	.read			; read stdin if no args
	jmps	.nextfile

.set_chars:
	pop	esi
	call	.ascii_to_num
	_mov	[chars], eax
	jmps .nextfile

.set_num_of_lines:
	pop	esi
	call	.ascii_to_num
	_mov	[lines], eax
	jmps	.nextfile

.prepfile:
	sys_close	ebp		; Close the file discriptor
	inc	ebp			; If we read stdin, trigger end
.nextfile:			
	pop	ebx			; get next arg
	or	ebx,ebx		
	jnz	.n2			; exit if none
.exit:
	or	ebp, ebp		; If read no files (ebp = STDIN,0)
	jz	.read			; Read stdin!
	sys_exit edi			; exit with return value
.n2:
	cmp word [ebx], "-n"
	je	.set_num_of_lines
	
	cmp word [ebx], "-c"
	je	.set_chars
	
	sys_open ebx,O_RDONLY
	xchg	ebp,eax
	;_mov	ebp,eax			; save fd
	test	ebp,ebp		
	jns	.read			; successful open is > 0

.error:
	inc	edi		
	jmps	.nextfile		; try to open next file

.read:
	_mov	ecx,buf
	_mov	edx,BUFSIZE
.readloop:
	sys_read ebp
	test	eax,eax
	js	.error			; fd < 0, error
	jz	.prepfile		; EOF, go to next file

	mov	esi,[chars]
	test	esi,esi
;	cmp	[chars],dword 0
	jg 	.print_chars

	xor	esi,esi			; set to zero
	dec	esi			; set to -1 so loop can have inc esi at top
	_mov	ebx,eax			; keep size of read for test against counter

.findnewlines:
	inc	esi
	cmp	esi,ebx
	jg	.write
	cmp	[ecx+esi],byte 0xa	; is it a newline?
	jne	.findnewlines		; keep looking

.dec_lines:
	dec	dword [lines]
	mov	eax,[lines]
	test	eax,eax
	jnz	.findnewlines		; keep finding newlines
				
.write:					; found enough newlines

	inc	esi			; add one to esi for last newline
.print_chars:
	sys_write STDOUT,ecx,esi	; print
	jmp	.nextfile

;---------------------------------------
; esi = string
; eax = number 
.ascii_to_num:
        xor	eax,eax                 ; zero out regs
        xor	ebx,ebx
.next_digit:
        lodsb                           ; load byte from esi
        test	al,al
        jz	.done
        sub	al,'0'                  ; '0' is first number in ascii
        imul	ebx,10
        add	ebx,eax
        jmp	short .next_digit
.done:
        xchg	ebx,eax                 ; ebx=eax,eax=ebx
        ret
;---------------------------------------

UDATASEG

lines	resd	1
chars	resd	1
buf	resb	BUFSIZE

END
