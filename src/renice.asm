;Copyright (C) 2001 Jonathan Leto <jonathan@leto.net>
;
;$Id: renice.asm,v 1.1 2001/01/21 15:18:46 konst Exp $
;
;hackers' renice
;
;syntax: renice priority pid [ pid ... ]
;
;Version 0.1 - Thu Jan 04 12:54:59 EST 2001
;
;All comments/feedback welcome.

%include "system.inc"

CODESEG

usage	db	"usage: renice priority pid",__n
_usagelen equ $-usage
%assign	usagelen _usagelen

START:   
        pop     ebx                     ; argc
        dec     ebx
        pop     ebx                     ; argv[0], program name
        jz      .usage

	pop	esi
	test	esi,esi
	jz	.exit_err
	call	.ascii_to_num
	_mov	[prio],eax		; priority

	pop	esi
	test	esi,esi
	jz	.exit_err
.nextarg:
	call	.ascii_to_num
	_mov	[pid],eax		; pid

	sys_setpriority PRIO_PROCESS,[pid],[prio]
	pop	esi
	test	esi,esi
	jnz	.nextarg
	_mov	ebx,0
.exit:
	sys_exit
.usage:
        sys_write STDOUT,usage,usagelen
.exit_err:
	_mov	ebx,1
	jmps	.exit

;---------------------------------------
; esi = string
; eax = number 
.ascii_to_num:
	push	esi
        xor     eax,eax                 ; zero out regs
        xor     ebx,ebx
	
	cmp     [esi], byte '-'
        jnz     .next_digit
        lodsb

.next_digit:
        lodsb                           ; load byte from esi
        test    al,al
        jz      .done
        sub     al,'0'                  ; '0' is first number in ascii
        imul    ebx,10
        add     ebx,eax
        jmp     .next_digit

.done:
        xchg    ebx,eax
	pop	esi
        cmp     [esi], byte '-'
        jz     .done_neg
        ret
.done_neg:
	neg	eax			;if first char is -, negate
	ret
;---------------------------------------	

UDATASEG
pid:    resd    1
prio:   resd    1

END
