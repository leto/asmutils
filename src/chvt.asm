;Copyright (C) 1999 Indrek Mandre <indrek@mare.ee>
;
;$Id: chvt.asm,v 1.4 2002/03/07 06:16:39 konst Exp $
;
;hackers' chvt/deallocvt
;
;0.01: 29-Jul-1999	initial release
;
;syntax: chvt N
;	 deallocvt [N]...
;
;example: chvt 3
;	  deallocvt 10 11 12
;	  deallocvt
;
;Changes current VT/deallocates VTs

%include "system.inc"

CODESEG

atoi:
	_mov	eax,0
	_mov	ebx,10
        _mov	ecx,0
.next:
        mov	cl,[esi]
	sub	cl,'0'
	jb	.done
	cmp	cl,9
	ja	.done
	mul	bx
	add	eax,ecx
.nextsym:
	inc	esi
	jmp short .next
.done:
	ret

open_ioctl:
	sys_open EMPTY,O_RDONLY
	test	eax,eax
	js	errorexit
	lea	edx,[esp-0x10]	;buffer is on the stack
	sys_ioctl eax,KDGKBTYPE
	or	eax,eax
	ret
errorexit:
	sys_exit_false

START:
	mov	ebx,devtty
	call	open_ioctl
	jz	.proceed
	mov	ebx,devconsole
	call	open_ioctl
	jnz	errorexit
.proceed:
	mov	ebp,ebx		;file descriptor

	pop	edi
	pop	esi	;how we are called?
.n1:			
	lodsb
	or 	al,al
	jnz	.n1

	cmp	dword [esi-5],"chvt"
	jnz	deallocvt
	
	cmp	edi,byte 2
	jnz	errorexit
	pop	esi
	or	esi,esi
	jz	do_exit
	call	atoi
	sys_ioctl ebp,VT_ACTIVATE,eax
	sys_ioctl EMPTY,VT_WAITACTIVE
do_exit:
	sys_exit_true

deallocvt:
	xor	eax,eax
	dec	edi
	jz	do_dealloc
next_arg:
	pop	esi
	or	esi,esi
	jz	do_exit
	call	atoi
do_dealloc:
	sys_ioctl ebp,VT_DISALLOCATE,eax
	jmp short next_arg


devtty		db	"/dev/tty0",EOL
devconsole	db	"/dev/console",EOL

END
