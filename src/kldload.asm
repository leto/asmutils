;Copyright (C) 2001 Konstantin Boldyshev <konst@linuxassembly.org>
;
;$Id: kldload.asm,v 1.1 2001/12/08 16:26:52 konst Exp $
;
;hackers' kldload/kldunload/kldstat (FreeBSD)
;
;syntax: kldstat
;	 kldload filename
;	 kldunload name|id
;
;example: kldstat
;	  kldload fire_saver
;	  kldunload kernel ;)
;
;NOTES:
;
;There are few differencies from usual kldunload and kldstat:
;'kldunload' tries to interpret argument as name first,
;and if that fails, it tries it as id (no -i switch)
;'kldstat' has a little bit different ouptut formatting.
;This is not perl or even C, so I tried to KISS.
;
;0.01: 08-Dec-2001	initial release

%include "system.inc"

CODESEG

%assign	BUFSIZE	0x2000

stat_title	db	"Id",__t,"Refs",__t,"Address",__t,__t,"Size",__t,__t,"Name",__n
STAT_TITLE_LEN	equ	$ - stat_title

START:
	pop	ebx
	pop	esi
.n1:
	lodsb
	or 	al,al
	jnz	.n1

	cmp	dword [esi-5],'stat'
	jz	near .kldstat
	cmp	word [esi-7],'un'
	jz	.kldunload

.kldload:
	dec	ebx
	jz	.exit

	pop	ebx

.load:
	sys_kldload

.exit:
	sys_exit eax

;
;
;

.kldunload:
	dec	ecx
	jz	.exit

	pop	ebp		;name OR fileid

	sys_kldfind ebp		;first, try it as name
	mov	ebx,eax
	test	eax,eax
	js	.unload

	mov	esi,ebp		;then, assume it is fileid
	xor	eax,eax	
	xor	ebx,ebx
.next_digit:
	lodsb
	sub	al,'0'
	jb	.done
	cmp	al,9
	ja	.done
	imul	ebx,byte 10
	add	ebx,eax
	jmps	.next_digit
.done:

.unload:			;ebx should contain fileid now
	sys_kldunload
	jmps	.exit

;
;
;

.kldstat:
	xor	ebp,ebp
	mov	edi,buf

.s1:
	sys_kldnext ebp
	or	eax,eax
	jz	.stat_done

	mov	ebp,eax
	
	mov	esi,kldstat_buf    
	mov	dword [esi],KLDSTAT_BUF_SIZE
	sys_kldstat ebp,esi

	mov	eax,[esi+kld_file_stat.id]
	_mov	ecx,10
	call	itoa

	mov	eax,[esi + kld_file_stat.refs]
	call	itoa

	mov	ax,"0x"
	stosw

	mov	eax,[esi + kld_file_stat.address]
	_mov	ecx,0x10
	call	itoa

	mov	ax,"0x"
	stosw

	mov	eax,[esi + kld_file_stat.size]
	call	itoa

	add	esi,byte kld_file_stat.name
.s2:
	lodsb
	stosb
	or	al,al
	jnz	.s2
	mov	byte [edi - 1], __n
	
	jmps	.s1

.stat_done:
	xor	al,al
	stosb
	
	sys_write STDOUT, stat_title, STAT_TITLE_LEN

	mov	esi,buf
	mov	ecx,esi
.s3:
	lodsb
	or	al,al
	jnz	.s3

	sub	esi,ecx
	dec	esi
	
	sys_write STDOUT,EMPTY,esi

	xor	eax,eax
	jmp	.exit

;itoa (unsigned long value, char *string, int radix)
;
;print 32 bit number as binary,octal,decimal,or hexadecimal value
;
;<EAX	unsigned long value
;<EDI	char *string
;<ECX	base    (2, 8, 10, 16, or another one)

itoa:
	push	edi
	call	.printB
	pop	edx

	mov	al,__t
	stosb

	cmp	cl,0x10
	jnz	.done

	sub	edx,edi
	cmp	dl,-7
	jbe	.done

	stosb

.done:
	ret

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


UDATASEG

kldstat_buf:
B_STRUC kld_file_stat,.version,.name,.refs,.id,.address,.size
KLDSTAT_BUF_SIZE equ	$ - kldstat_buf

buf	CHAR	BUFSIZE

END
