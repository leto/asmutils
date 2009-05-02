;Copyright (C) 2001 Rudolf Marek <marekr2@feld.cvut.cz>
;
;$Id: dd.asm,v 1.5 2003/06/20 18:53:11 konst Exp $
;
;hackers' dd
;
;syntax: dd if= of= count= skip= bs= seek= conv=(sync|swab)
; swab requires an even bs
;
;number can be also 1k=1*1024 etc m=1024 * 1024, k=1024 b=512 w=2
;
;0.1: 2001-Feb-21	initial release
;0.2: 2002-Apr-15	added O_LARGEFILE for input file
;0.3: 2003-Jun-18	fixed pipe bug, added conv=sync conv=swab
;			count blocks, recover lseek (JH)
;
;All comments/feedback welcome.

%include "system.inc"

%define SIMPLE_CONV
%define LSEEK_RECOVER
%define COUNT_BLOCKS
%define ERROR_MSG

%ifdef	__LINUX__
%define LARGE_FILES
%endif

CODESEG

usage	db	"usage: dd as you know except ibs= obs= conv=",__n
_ul	equ	$-usage
%assign	usagelen _ul
%ifdef ERROR_MSG
errmsg	db	"IO-error", 10
errlen	equ	$-errmsg
%endif

START:  
	_mov 	ebp,STDOUT
	_mov 	edi,STDIN 
	pop     eax                     ;argc
	dec     eax
	pop     eax                     ;argv[0], program name
	jnz      .continue

	sys_write ebp,usage,usagelen
	sys_exit 0

.continue:
	
	mov	byte [bs+1],0x2		;bs = 512 - default block size
	
.next_arg:
	pop	esi
	or 	esi,esi
	jz 	near .no_next_arg

.we_have_arg:
	push 	dword .next_arg

	cmp 	word [esi],'of'
	jz 	.parse_output_file
	cmp 	word [esi],'if'
	jz 	.parse_input_file
	mov	edx,count
	cmp 	dword [esi],'coun'
	jz 	.update_fields	
	add	edx,byte 4
	cmp 	word [esi],'bs'
	jz 	.update_fields	
	add	edx,byte 4
	cmp 	dword [esi],'skip'
	jz 	.update_fields	
	add	edx,byte 4
	cmp 	dword [esi],'seek'
	jz 	.update_fields	
%ifdef SIMPLE_CONV
	cmp	dword [esi],'conv'
	je	.conv
%endif

	ret  ;ignore unknown opt

.parse_input_file:		;I always wanted to xchange .. :)
	_mov	ecx,(O_RDONLY|O_LARGEFILE)
	xchg	edx,ebp
	call	.open
	xchg	edi,ebp
	xchg	edx,ebp
	ret

.parse_output_file:	; No no, not O_TRUNC. Try to improve GNU dd, not copy
	_mov	ecx,(O_WRONLY|O_CREAT|O_LARGEFILE)
	_mov	edx,(S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH) ;dd feeds _always_ 666
.open:	
	call 	.check
	xchg 	ebx,esi
	sys_open
	test 	eax,eax
	js 	.do_error
	xchg 	ebp,eax
	ret

.update_fields:
	call 	.check
	call 	.ascii_to_num
	mov 	[edx],eax
	ret
%ifdef SIMPLE_CONV
.conv:		; Turn on rudimentry conversion (sync & swab)
	add	esi, byte 5
	cmp	[esi], dword 'sync'
	je	.c_sync
	cmp	[esi], dword 'swab'
	je	.c_swab
	ret
%endif

.check:
	lodsb
	or 	al,al
	jz	.error
.ok:
	cmp 	al,'='
	jnz 	.check
	ret
.do_error:
%ifdef ERROR_MSG
	sys_write	2, errmsg, errlen
%endif
%ifdef COUNT_BLOCKS
	call	.showcount
%endif
.error:
	sys_exit 1

%ifdef SIMPLE_CONV
.c_sync	mov	[c_sync], byte 1
	ret
.c_swab	mov	[c_swab], byte 1
	ret
%endif

.no_next_arg:			;now we should have opened files - ready to copy
	mov 	eax,[bs]
	push	eax
	add	eax,buf
	sys_brk eax            ;get some mem
	pop	eax
	mul 	dword [skip]   ;EDX:EAX seek input file

%ifdef LARGE_FILES
	push    edi
	mov     ebx,edi
	mov     ecx,edx
	mov     edx,eax
	_mov     esi,result
	_mov     edi,SEEK_SET
	sys_llseek
	;pop	edi
%else	
	or 	edx,edx		;file bigger than 4Gb cannot lseek more
%ifdef LSEEK_RECOVER		;so skip blocks if compiled in
	jnz	.recover
%else
	jnz 	.do_error	
%endif
	sys_lseek edi, eax, SEEK_SET
%endif

%ifdef LSEEK_RECOVER
	or	eax, eax	; Trick here is to read [skip] full blocks
	jns	.norecover
.recover:
	mov	ebx, esi
	mov	ecx, buf
.rec_nextblock:
	dec	dword [skip]
	js	.norecover	; Already skipped enough?
	mov	edx, [bs]
.rec_nextread:
	sys_read
	or	eax, eax
	jna	.do_error
	sub	edx, eax
	jnz	.rec_nextread
	jmp	short	.rec_nextblock
.norecover:
%endif

	mov 	eax,[bs]	; Now seek nicely on output file
	mul 	dword [seek]
%ifdef LARGE_FILES
	mov     ebx,ebp
	mov     ecx,edx
	mov     edx,eax
	;push    edi
	;mov     esi,result
	;mov     edi,SEEK_SET
	sys_llseek
	pop	edi
%else
	or 	edx,edx		; Can't skip here
	jnz 	.do_error	
	sys_lseek ebp,eax,SEEK_SET
%endif
	mov 	esi,[count]
.next_block:
	; The idea here is to keep reading until [bs] bytes have been read
	mov	ebx, edi
	_mov	ecx, buf
	_mov	edx, [bs]
.next_read:
	sys_read
	test 	eax,eax
	jz 	.no_more_data
	js 	near .do_error
	add	ecx, eax
	sub	edx, eax
	ja	.next_read
%ifdef COUNT_BLOCKS
	inc	dword [incnt]
%endif

%ifdef SIMPLE_CONV
	call	.swab
%endif

	mov 	ebx,ebp
	mov 	edx,ecx
	mov	ecx,buf
	sub	edx,ecx
	sys_write
%ifdef ERROR_MSG
	cmp	eax, edx
	jne	near .do_error
%endif
%ifdef COUNT_BLOCKS
	inc	dword [outcnt]
%endif
	dec 	esi
	jnz	.next_block
	xor	eax, eax
.no_more_data:	
%ifdef COUNT_BLOCKS
	cmp	edx, [bs]
	je	.finalize	; Guess what, we can skip all of this
	inc	byte [inpart]
	inc	byte [outpart]
%endif
%ifdef	SIMPLE_CONV
	cmp	[c_sync], byte 1
	jne	.flush
	xor	eax, eax
	mov	edi, ecx
	mov	ecx, edx
	rep	stosb	; Actually loops 0 times on zero
	mov	ecx, edi
%ifdef COUNT_BLOCKS
	dec	byte [outpart]
	inc	byte [outcnt]
%endif
.flush: 
	call	.swab
%endif
	mov 	edx,ecx
	mov	ecx,buf
	sub	edx,ecx
	sys_write ebp
.finalize:
	sys_close edi
	sys_close ebp
%ifdef	COUNT_BLOCKS
	call	.showcount
%endif
	sys_exit 0	

;Swab buffer code
; ecx = end of buffer
; all registers conserved
.swab:	test	[c_swab], byte 1
	jz	.ret
	pusha
	mov	esi, buf
	mov	edi, esi
	sub	ecx, esi
	or	ecx, ecx
	jz	.trap
.swabber:
	lodsw
	xchg	al, ah
	stosw
	loop	.swabber
.trap:	popa
.ret	ret

;Here is long output count code-------------
%ifdef COUNT_BLOCKS
.showcount:
	mov	edi, buf
	push	edi
	mov	eax, [incnt]
	call	.itoa
	xor	eax, eax
	mov	ah, [inpart]
	add	eax, "+0 "
	stosd
	mov	eax, 0x0A2C6E69		; "in,", __n
	stosd
	mov	eax, [outcnt]
	call	.itoa
	xor	eax, eax
	mov	ah, [outpart]
	add	eax, "+0 "
	stosd
	mov	eax, 0x0A74756F		; "out,", __n
	stosd
	pop	ecx
	mov	edx, edi
	sub	edx, ecx
	sys_write	STDERR
	ret

.itoa:
	_mov	ebx, 10
	xor	ecx, ecx
.itoan	xor	edx, edx
	div	ebx
	add	dl, '0'
	push	edx
	inc	ecx
	or	eax, eax
	jnz	.itoan
.itoap	pop	eax
	stosb
	loop	.itoap
	ret
%endif

;---------------------------------------stolen from renice.asm
; esi = string
; eax = number 
.ascii_to_num:
	;push	esi
	xor     eax,eax                 ; zero out regs
	xor     ebx,ebx
	
	;cmp     [esi], byte '-'
	;jnz     .next_digit
	;lodsb

.next_digit:
	lodsb                           ; load byte from esi
	or	al,al
	jz	.done
	cmp 	al,'9'
	ja  	.multiply  
	sub	al,'0'                  ; '0' is first number in ascii
	imul	ebx,10
	add	ebx,eax
	jmp	short	.next_digit

.done:
	xchg    ebx,eax
	;pop	esi
	;cmp     [esi], byte '-'
	;jz     .done_neg
	ret
;.done_neg:
;	neg	eax			;if first char is -, negate
;	ret
.multiply:
	cmp 	al,'w'
	jz	 .mul_2
	cmp 	al,'b'
	jz 	.mul_512
	cmp	al, 'k'
	jz	.mul_1024
	cmp 	al,'m'
	jnz	near .error		;we don't know others yet

	shl	ebx,10
.mul_1024:
	shl	ebx,1
.mul_512: 
	shl	ebx,8
.mul_2:
	shl	ebx,1
	jmp	short .done
		
;---------------------------------------	

UDATASEG

count	resd	1
bs	resd	1
skip	resd	1
seek	resd	1

incnt	resd	1
outcnt	resd	1
inpart	resb	1
outpart	resb	1

c_sync	resb	1
c_swab	resb	1

result	resq	1
buf	resb	1	;here will our buff start

END
