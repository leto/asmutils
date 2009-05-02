;Copyright (C) 1999 Konstantin Boldyshev <konst@linuxassembly.org>
;Copyright (C) 2002 Thomas M. Ogrisegg <tom@rhadamanthys.org>
;
;$Id: swapon.asm,v 1.3 2002/03/21 08:33:21 konst Exp $
;
;hackers' swapon/swapoff/mkswap
;
;syntax: swapon device ...
;
;example: swapon /dev/hda9 /dev/hda10
;	  swapoff /dev/hda5
;	  mkswap /dev/hda8
;
;0.01: 04-Jul-1999	initial release
;0.02: 18-Mar-2002	mkswap extnesion for Linux 2.2+ (TO)

%include "system.inc"

CODESEG

START:
	pop	esi
	pop	esi
.n1:
	lodsb
	or 	al,al
	jnz	.n1
.next_file:
	pop	ebx
	or	ebx,ebx
	jz	.exit
	cmp	word [esi-7],'mk'
	jz	.mkswap
	cmp	word [esi-3],'ff'
	jnz	.swapon

.swapoff:
	sys_swapoff
	jmps	.next_file

.swapon:
	sys_swapon
	jmps	.next_file

.mkswap:
	sys_open EMPTY,O_RDWR
	test	eax,eax
	js	.exit
	mov	ebp,eax
	sys_lseek ebp,0,SEEK_END
	test	eax,eax
	jns	.do_mkswap

.error:
	sys_write STDERR,error,errlen
.exit:
	sys_exit eax

.do_mkswap:
	mov	edi, eax
	shr	edi, 0xc
	dec	edi
	sys_lseek ebp,0x400,SEEK_SET
	test	eax,eax
	js	.error
	push	byte 0x1
	mov	ecx,esp
	sys_write ebp,EMPTY,4
	push	edi
	mov	ecx,esp
	sys_write ebp,EMPTY,4
	sys_lseek ebp,0xff6,SEEK_SET
	sys_write ebp,signature,siglen
	test	eax,eax
	js	.error
	sys_close ebp
	xor	eax,eax
	jmps	.exit

signature	db	"SWAPSPACE2"
siglen	equ	$	-	signature
error		db	"i/o error.", __n
errlen	equ	$	-	error

END
