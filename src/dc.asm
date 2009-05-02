;Copyright (C) 2001 by Joshua Hudson
;
;$Id: dc.asm,v 1.1 2001/08/14 18:55:38 konst Exp $
;
;hacker's dc/revp
;
;usage: dc expression
;
;supports	+,-,*,/,%,xor,or,and,neg
;		x     ^   |  &   ~!
;for debugging, pr will print the top number to stdout
;du dumps the top of the stack
;
;xchg is used frequently to decrease code size

%include "system.inc"

CODESEG

START:
	pop	ebp
	pop	eax
	_mov	edi, stack	; our stack pointer
.next:
	dec	ebp
	jz	.done
	pop	ebx
	cmp	[ebx], byte '0'
	jl	.notnum
	cmp	[ebx], byte '9'
	jg	.notnum
	call	.atoi
	jmps	.next

.done	call	.pop
	xchg	ecx, eax
	call	.itoa
	sys_exit_true

.pr	call	.push
	call	.itoa
	jmps	.next

.neg	neg	eax
	jmp	.nextrelay

; Process all uniary operators
.notnum	call	.pop
	xchg	ecx, eax
	cmp	[ebx], byte 'p'
	je	.pr
	cmp	[ebx], byte '!'
	je	.neg
	cmp	[ebx], byte '~'
	je	.neg
	cmp	[ebx], byte 'n'
	je	.neg
	cmp	[ebx], byte 'd'
	je	.next
; Process all binary operators
	call	.pop
	xchg	ecx, eax
	cmp	[ebx], byte '+'
	je	.plus
	cmp	[ebx], byte '-'
	je	.minux
	cmp	[ebx], byte '*'
	je	.times
	cmp	[ebx], byte 'x'
	je	.times
	cmp	[ebx], byte '/'
	je	.div
	cmp	[ebx], byte '%'
	je	.mod
	cmp	[ebx], byte 'a'
	je	.and
	cmp	[ebx], byte 'o'
	je	.or
	cmp	[ebx], byte 'x'
	je	.xor
	cmp	[ebx], byte 'e'
	je	.xor
	jmp	.bad_op

.nextrelay:
	call	.push
	jmp	.next

.plus	add	eax, ecx
	jmps	.nextrelay

.minux	sub	eax, ecx
	jmps	.nextrelay

.times	xor	edx, edx
	mul	ecx
	jmps	.nextrelay

.and	and	eax, ecx
	jmps	.nextrelay

.or	or	eax, ecx
	jmps	.nextrelay

.xor	xor	eax, ecx
	jmps	.nextrelay

.div	xor	edx, edx
	div	ecx
	jmps	.nextrelay

.mod	xor	edx, edx
	div	ecx
	xchg	edx, eax
	jmps	.nextrelay

;*** itoa: convert eax to number in num_buf and display
.itoa:
	xor	ecx, ecx
	push	edi
	_mov	ebx, 10
	_mov	edi, num_buf
.itoa_again:
	xor	edx, edx
	div	ebx
	push	edx
	inc	ecx
	or	eax, eax
	jnz	.itoa_again
	mov	edx, ecx
	inc	edx
.itoa_pop:
	pop	eax
	add	al, '0'
	stosb
	loop	.itoa_pop
	mov	al, 10
	stosb
	sys_write	STDOUT, num_buf
	pop	edi
	ret

;*** atoi: convert [ebx] to number and push
.atoi:
	xor	eax, eax
	xor	ecx, ecx
.atoi_next:
	mov	cl, [ebx]
	sub	cl, '0'
	cmp	cl, 0
	jl	.atoi_done
	cmp	cl, 9
	jg	.atoi_done
	_mov	edx, 10
	mul	edx		; eax *= 10
	add	eax, ecx
	inc	ebx
	jmps	.atoi_next
.atoi_done:
	jmps	.push

;*** Our small subroutines
.pop	cmp	edi, stack
	jle	.stack_underflow
	sub	edi, byte 4
	mov	ecx, [edi]
	ret

.push	cmp	edi, stack + 128
	jge	.stack_overflow
	mov	[edi], eax
	add	edi, byte 4
	ret

.stack_overflow:
	_mov	ecx, stack_overflow
	_mov	edx, stack_overflow_len
	jmps	.stack_message

.stack_underflow:
	_mov	ecx, stack_underflow
	_mov	edx, stack_underflow_len
	jmps	.stack_message

.bad_op:
	_mov	ecx, bad_op
	_mov	edx, bad_op_len
.stack_message:
	sys_write	STDERR
	sys_exit_false

;*** Error messages

stack_overflow	db "Stack overflow", __n
stack_overflow_len equ 15

stack_underflow	db "Stack underflow", __n
stack_underflow_len equ 16

bad_op	db "Bad op", __n
bad_op_len equ 7

UDATASEG

stack	resd	128
num_buf	resb	13

END
