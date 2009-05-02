;; factor.asm: Copyright (C) 2001 by Brian Raiter, under the GNU
;; General Public License. No warranty. See COPYING for details.
;;
;; Usage: factor [N]...
;; Prints the prime factors of each N. With no arguments, reads N
;; from standard input. The valid range is 0 <= N < 2^64.
;;
;; $Id: factor.asm,v 1.4 2001/08/20 15:22:03 konst Exp $

%include "system.inc"

%define	iobuf_size	96

CODESEG


;; The factorconst subroutine, called by factorize, repeatedly divides
;; the number at the top of the floating-point stack by the integer
;; stored in buf as long as the number continues to divide evenly. For
;; each successful division, the number is also displayed on standard
;; output. Upon return, the quotient of the failed division is at the
;; top of the floating-point stack, just above the factored number.

factorconst:						; num  +
		fild	dword [edi]			; div  num  +
.loop:		fld	st1				; num  div  num  +
		fdiv	st0, st1			; quot div  num  +
		fld	st0				; quot quot div  num  +
		frndint					; quoi quot div  num  +
		fcomp	st1				; quot div  num  +
		fnstsw	ax
		and	ah, 0x40
		jz	factorize.return
		fstp	st2				; div  quot +
		call	itoa64
		jmp	short .loop


;; factorize is the main subroutine of the program. It is called with esi
;; pointing to an NUL-terminated string representing the number to factor.
;; Upon return, eax contains a nonzero value if an error occurred (i.e.,
;; an invalid number stored at esi).

factorize:

;; The first step is to translate the string into a number. 10.0 and 0.0
;; are pushed onto the floating-point stack.

		xor	eax, eax
		fild	dword [ten]			; 10.0
		fldz					; num  10.0

;; Each character in the string is checked; if it is not in the range
;; of '0' to '9' inclusive, an error message is displayed and the
;; subroutine aborts. Otherwise, the top of the stack is multiplied by
;; ten and the value of the digit is added to the product. The loop
;; exits when a NUL byte is found.

.atoiloop:
		lodsb
		or	al, al
		jz	.atoiloopend
		fmul	st0, st1			; n10  10.0
		sub	al, '0'
		jc	.errbadnum
		cmp	al, 10
		jnc	.errbadnum
		mov	[byte edi + buf], eax
		fiadd	dword [byte edi + buf]		; num  10.0
		jmp	short .atoiloop
.errbadnum:
		mov	al, 1
.return:	fcompp
		ret
.atoiloopend:

;; The number's exponent is examined, and if the number is 2^64 or
;; greater, it is rejected.

		fld	st0				; num  num  10.0
		fstp	tword [byte edi + buf]		; num  10.0
		mov	eax, [byte edi + buf + 8]
		cmp	ax, 64 + 0x3FFF
		jge	.errbadnum

;; The number is displayed, followed by a colon. If the number is one
;; or zero, no factoring should be done and the subroutine skips ahead
;; to the end.
							; num  junk
		mov	bl, ':'
		call	itoa64nospc
		fxch	st1				; junk num
		fld1					; 1.0  junk num
		fcom	st2
		fstsw	ax
		and	ah, 0x45
		cmp	ah, 1
		jnz	.earlyout
		fcompp					; num

;; The factorconst subroutine is called three times, with the number
;; in buf set to two, three, and five, respectively.

		mov	esi, factorconst
		xor	edx, edx
		mov	dl, 2
		mov	[edi], edx
		call	esi
		inc	dword [edi]
		call	esi
		mov	byte [edi], 5
		call	esi

;; If the number is now equal to one, the subroutine is finished and
;; exits immediately.

		fld1					; 1.0  num
		fcom	st1
		fnstsw	ax
		and	ah, 0x40
		jnz	.quitfactorize

;; factor is initialized to 7, and edi is initialized with a sequence
;; of eight four-bit values that represent the cycle of differences
;; between subsequent integers not divisible by 2, 3, or 5. The
;; subroutine then enters its main loop.
							; junk num
		mov	byte [edi], 7
		fild	qword [edi]			; fact junk num
		fdivr	st0, st2			; quot junk num
		mov	ebp, 0x42424626

;; The loop returns to this point when the last tested value was not a
;; factor. The next value to test (for which the division operation
;; should just be finishing up) is moved into esi, and factor is
;; incremented by the value at the bottom of ebp, which is first
;; advanced to the next four-bit value. If it overflows, then we have
;; exhausted all possible factors, and end.

.notafactor:
		mov	esi, [edi]
		rol	ebp, 4
		mov	eax, ebp
		and	eax, byte 0x0F
		add	[edi], eax
		jc	.earlyout

;; The main loop of the factorize subroutine. The quotient from the
;; division of the number by the next potential factor is stored, and
;; the division for the next iteration is started.

.mainloop:						; quot quo0 num
		fst	st1				; quot quot num
		fstp	tword [byte edi + buf]		; quot num
		fild	qword [edi]			; fact quot num
		fdivr	st0, st2			; quo2 quot num

;; The integer portion of the quotient is isolated and tested against
;; the divisor (i.e., the potential factor). If the quotient is
;; smaller, then the loop has passed the number's square root, and no
;; more factors will be found. In this case, the program prints out
;; the current value for the number as the last factor, followed by a
;; newline character, and the subroutine ends.

		mov	edx, [byte edi + buf + 4]
		mov	ecx, 31 + 0x3FFF
		sub	ecx, [byte edi + buf + 8]
		js	.keepgoing
		mov	eax, edx
		shr	eax, cl
		cmp	eax, esi
		jnc	.keepgoing
.earlyout:	fxch	st2
		call	itoa64
		fstp	st0
.quitfactorize:	fcompp
		xor	edx, edx
		inc	edx
		mov	ecx, ten
		jmp	short finalwrite

;; Now the integer portion of the quotient is shifted out. If any
;; nonzero bits are left, then the number being tested is not a
;; factor, and the program loops back.

.keepgoing:	mov	eax, [byte edi + buf]
		neg	ecx
		js	.shift32
		xchg	eax, edx
		xor	eax, eax
.shift32:	shld	edx, eax, cl
		shl	eax, cl
		or	eax, edx
		jnz	.notafactor

;; Otherwise, a new factor has been found. The number being factored
;; is therefore replaced with the quotient, and the result of the
;; division in progress is junked. The new factor is displayed, and
;; then is tested again. If this was the first time this factor was
;; tested, then ebp is reset back.
							; junk num  num0
		cmp	[edi], esi
		jz	.repeating
		ror	ebp, 4
		mov	[edi], esi
.repeating:	ffree	st2				; junk num
		fild	qword [edi]			; fact junk num
		call	itoa64
		fdivr	st0, st2			; quot junk num
		mov	esi, [edi]
		jmp	short .mainloop


;; itoa64 is the numeric output subroutine. When the subroutine is
;; called, the number to be displayed should be on the top of the
;; floating-point stack, and there should be no more than four other
;; numbers on the stack. A space is prefixed to the output, unless
;; itoa64nospc is called, in which case the character in dl is
;; suffixed to the output.

itoa64:
		mov	bl, ' '
itoa64nospc:

;; A copy of the number is made, and 10 is placed on the stack. esi is
;; pointed to the end of the buffer that will hold the decimal
;; representation, with ecx pointing just past the end.
							; num  +
		fld	st0				; num  num  +
		fild	dword [ten]			; 10.0 num  num  +
		lea	ecx, [byte edi + iobuf + 32]
		mov	edx, ecx
		dec	ecx

;; At each iteration, the number is reduced modulo 10. This remainder
;; is subtracted from the number (and stored in iobuf as an ASCII
;; digit). The difference is then divided by ten, and if the quotient
;; is zero the loop exits. Otherwise, the quotient replaces the number
;; for the next iteration.

.loop:
		fld	st1				; num  10.0 num  num  +
		fprem					; rem  10.0 num  num  +
		fist	dword [edx]			; rem  10.0 num  num  +
		fsubr	st0, st2			; 10n2 10.0 num  num  +
		ftst
		fstsw	ax
		fstp	st2				; 10.0 10n2 num  +
		fdiv	st1, st0			; 10.0 num2 num  +
		mov	al, '0'
		add	al, [edx]
		mov	[ecx], al
		dec	ecx
		and	ah, 0x40
		jz	.loop
		fcompp					; num  +

;; If al contains a space, it is added to the start of the string.
;; Otherwise, the character is added to the end.

		mov	[ecx], bl
		cmp	bl, ' '
		jz	.prefix
		mov	[edx], bl
		inc	edx
		inc	ecx
.prefix:

;; The string is written to standard output, and the subroutine ends.

		sub	edx, ecx
finalwrite:	sys_write STDOUT
		dec	eax
		ret


;; Here is the program's entry point.

START:

;; argc and argv[0] are removed from the stack and discarded. ebp is
;; initialized to point to the data.

		pop	esi
		pop	edi
		mov	edi, factor

;; If argv[1] is NULL, then the program proceed to the input loop. If
;; argv[1] begins with a dash, then the help message is displayed.
;; Otherwise, the program begins readings the command-line arguments.

		pop	esi
		or	esi, esi
		jz	.inputloop

;; The factorize subroutine is called once for each command-line
;; argument, and then the program exits, with the exit code being
;; the return value from the last call to factorize.

.argloop:
		call	factorize
		pop	esi
		or	esi, esi
		jnz	.argloop
.mainexit:	xchg	eax, ebx
		sys_exit

;; The input loop routine. edi is pointed to iobuf, and esi is
;; initialized to one less than the size of iobuf.

.inputloop:
		lea	ecx, [byte edi + iobuf]
		push	byte iobuf_size - 1
		pop	esi

;; The program reads and discards one character at a time, until a
;; non-whitespace character is seen (or until no more input is
;; available, in which case the program exits).

.preinloop:
		xor	edx, edx
		inc	edx
		sys_read STDIN
		neg	eax
		jns	.mainexit
		mov	al, [ecx]
		cmp	al, ' '
		jz	.preinloop
		cmp	al, 9
		jc	.incharloop
		cmp	al, 14
		jc	.preinloop

;; The first non-whitespace character is stored at the beginning of
;; iobuf. The program continues to read characters until there is no
;; more input, there is no more room in iobuf, or until another
;; whitespace character is found.

.incharloop:
		inc	ecx
		dec	esi
		jz	.infinish
		sys_read STDIN
		neg	eax
		jns	.infinish
		mov	al, [ecx]
		cmp	al, ' '
		jz	.infinish
		cmp	al, 9
		jc	.incharloop
		cmp	al, 14
		jnc	.incharloop
.infinish:

;; A NUL is appended to the string obtained from standard input, the
;; factorize subroutine is called, and the program loops.

		mov	byte [ecx], 0
		lea	esi, [byte edi + iobuf]
		call	factorize
		jmp	short .inputloop

;; This value acts both as the number 10 and an ASCII newline.

ten:		db	10


;; zero-initialized data

UDATASEG

resb 3
ALIGNB 4

factor:		resd	2		; number being tested for factorhood

ALIGNB 16

buf		equ	$ - factor
		resd	3		; general-purpose numerical buffer

iobuf		equ	$ - factor
		resb	iobuf_size	; buffer for I/O

END
