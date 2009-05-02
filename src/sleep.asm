;Copyright (C) 1999-2001 Konstantin Boldyshev <konst@linuxassembly.org>
;
;$Id: sleep.asm,v 1.7 2002/03/07 11:13:32 konst Exp $
;
;hackers' sleep/usleep		[GNU replacement]
;
;syntax: sleep number[nsmhd]...
;        usleep usec
;
;n	-	nanoseconds
;s	-	seconds
;m	-	minutes
;h	-	hours
;d	-	days
;
;example:	sleep 1 2 3s
;
;NOTE:	this utility has nanoseconds suffix extension
;	in addition to usual GNU sleep suffixes
;
;0.01: 17-Jun-1999	initial release
;0.02: 03-Jul-1999	sleep is now using sys_nanosleep
;0.03: 18-Sep-1999	elf macros support
;0.04: 22-Jan-2001	nanoseconds support
;0.05: 07-Mar-2002	usleep support (IM)

%include "system.inc"

CODESEG

one_ms	db	'1', 0

START:
	pop	esi
	pop	esi

; Find out whether sleep or usleep was called
.n1:
	lodsb
	or	al,al
	jnz	.n1
	cmp	byte [esi-7],'u'
	jnz	.args
; We have 'usleep', sleeping in microseconds
	mov	ch,1
	pop	esi
	push	esi
	or	esi,esi
	jnz	.n2
	;no arguments given, default is to sleep 1 microseconds
	mov	esi,one_ms	
.n2:
	push	byte 0	;force single argument
	push	esi

.args:
	pop	esi
	or	esi,esi
	jz	.toexit
	mov	edi,esi

	xor	eax,eax
	xor	ebx,ebx
	xor	edx,edx
.next_digit:
	lodsb
	sub	al,'0'
	jb	.done
	cmp	al,9
	ja	.done
	imul	ebx,byte 10
	add	ebx,eax
	adc	edx,byte 0
	jmps	.next_digit
.done:
	mov	eax,ebx
	test	edx,edx
	jnz	.ok
	test	eax,eax
.toexit:
	jz	do_exit
.ok:
	_mov	ebx,1

	or	ch,ch
	jz	.nousleep

; now nanosleep can take arguments only up to 999999 microseconds,
; that means we have to divide and conquer
	mov	ebx, 1000000
	div	ebx
	xchg	eax,edx
	mov	ecx,edx
	mov	ebx,1000
	mul	ebx
	mov	edx,ecx
	xchg	eax,edx
	jmps	.set_sleep2

.nousleep:
	mov	cl,byte [esi - 1]

	test	cl,cl
	jz	.set_sleep
.s:
    	cmp	cl,'s'
	jz	.set_sleep2
.m:
	_mov	ebx,60
	cmp	cl,'m'
	jz	.set_sleep
.h:
	_mov	ebx,60*60
	cmp	cl,'h'
	jz	.set_sleep
.d:
	_mov	ebx,60*60*24
	cmp	cl,'d'
	jz	.set_sleep	
	cmp	cl,'n'
	jnz	do_exit
	xchg	eax,edx
	jmps	.set_sleep2
.set_sleep:
	mul	ebx
.set_sleep2:
	mov	ebx,t
.nanosleep:
	mov	dword [ebx],eax
	mov	dword [ebx+4],edx
.do_sleep:
	sys_nanosleep EMPTY,NULL
	jmp	.args

do_exit:
	sys_exit eax

UDATASEG

t B_STRUC timespec

END
