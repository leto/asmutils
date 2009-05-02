;; hexdump.asm: Copyright (C) 2001 Brian Raiter <breadbox@muppetlabs.com>,
;; under the terms of the GNU General Public License.
;;
;; Usage: hexdump [FILE]...
;; With no parameters, hexdump reads from standard input.
;; hexdump returns zero on success, or an error code otherwise.
;;
;; $Id: hexdump.asm,v 1.3 2001/09/24 16:49:19 konst Exp $

%include "system.inc"

;; The traditional hexdump utility only displays the graphic
;; characters in the standard ASCII set (32-126). By uncommenting this
;; line, hexdump will display all graphic characters in ISO-8859
;; (presuming your terminal supports such characters).

;%define ISO_8859

;; Number of bytes displayed per line.

%define linesize	16

CODESEG

START:

;; Remove argc and argv[0] from the stack. If argc is one, then use
;; stdin as the input file.

		pop	eax
		pop	ebx
		_mov	ebx, STDIN
		dec	eax
		jz	usestdin

;; Loop once for each file specified.

fileloop:

;; Get the next argument from the stack; if it is NULL, then the
;; program exits. Otherwise the open system call is used to get a
;; file descriptor, which is saved in ebx. ebp, which is used to
;; hold the current file offset, is reset to zero.

		pop	ebx
		or	ebx, ebx
%ifdef	__LONG_JUMPS__
		jz	near finish
%else
		jz	finish
%endif
		sys_open EMPTY,O_RDONLY
		or	eax, eax
%ifdef	__LONG_JUMPS__
		js	near quit
%else
		js	quit
%endif
		xchg	eax, ebx
usestdin:	xor	ebp, ebp

;; Loop once for each line of output.

lineloop:

;; The left-hand side of the output buffer is initialized with spaces.
;; This will also move edi to the start of the input buffer. esi
;; retains a copy of the start of the output buffer.

		mov	edi, format
		mov	esi, edi
		push	byte leftsize
		pop	ecx
		mov	al, ' '
		rep stosb

;; (Up to) 16 bytes are read from the file; if no input is available,
;; the program exits the loop. After the system call, eax will will
;; contain the number of bytes actually read. The current values of
;; all the registers are saved on the stack.

		mov	ecx, edi
		push	byte linesize
		pop	edx
		sys_read
		or	eax, eax
		js	quit
		jz	eof
		pusha

;; ecx is loaded with the address of the hexoutr subroutine. esi and
;; edi are swapped, so that esi points to the input buffer and edi to
;; the output buffer. ebp, which holds the current offset, is moved
;; into eax, and ebp gets the size of the input instead.

		cdq
		mov	ecx, hexoutr
		xchg	esi, edi
		xchg	eax, ebp

;; The offset is stored, in ASCII, at the far left of the output
;; buffer. The call to hexoutr executes hexout three times in a row,
;; storing the highest three bytes of eax and destroying eax in the
;; process. eax is then restored from the stack, ecx is advanced to
;; point directly to the hexout subroutine, and the final byte is
;; stored in the output buffer. Finally, a colon is appended.

		push	eax
		call	ecx
		pop	eax
		inc	ecx
		inc	ecx
		call	ecx
		mov	al, ':'
		stosb

;; Loop once for each byte in the input.

byteloop:

;; At every other iteration, edi is incremented, leaving a space in
;; the output buffer. Each byte is examined, and non-graphic values
;; are replaced in the input buffer with a dot. The byte is then given
;; to hexout, to add the hexadecimal representation to the output
;; buffer. When ebp reaches zero, the loop is done, and a newline is
;; appended.

		xor	edx, byte 1
		add	edi, edx
		lodsb
		cmp	al, 0x7F
		jz	dot
%ifdef ISO_8859
		test	al, 0x60
		jnz	nodot
%else
		cmp	al, ' '
		jge	nodot
%endif
dot:		mov	byte [byte esi - 1], '.'
nodot:		call	ecx
		dec	ebp
		jnz	byteloop
		mov	byte [esi], 10

;; The old register values are retrieved from the stack. eax (the size
;; of the input) is added to ebp (updating the current offset), esi
;; (the start of the output buffer) is copied into ecx, and the full
;; size of the output is calculated and stored in edx. The program
;; then write the contents of the buffer to standard output.

		popa
		add	ebp, eax
		lea	edx, [byte eax + leftsize + 1]
		mov	ecx, esi
		push	ebx
		sys_write STDOUT
		pop	ebx
		or	eax, eax
		jg	lineloop

;; When the program arrives here, nothing is left to read from the
;; current input file. The descriptor is closed and the program
;; moves on to the next file.

eof:		sys_close
%ifdef	__LONG_JUMPS__
		jmp	fileloop
%else
		jmp	short fileloop
%endif

;; When the program arrives here, eax will contain a negative value
;; if an error occurred, or zero if the program ran to completion.

quit:		neg	eax
		xchg	eax, ebx
finish:		sys_exit

;; hexoutr is called via ecx, so by pushing ecx before falling through
;; to the actual subroutine, hexout, it will return to this spot. ecx
;; will then be pushed again; however, this time ecx will have been
;; incremented, so when it returns the second time, the stack will
;; remain unmodified, and the next return will actually return to the
;; caller. As a result, hexout is executed three times in a row, and
;; ecx will have been advanced a total of three bytes. eax is rotated
;; left one byte before each execution, so hexout operates on
;; successively less significant bytes of eax. (hexoutr only runs
;; through three of the bytes since the first execution destroys the
;; value of the fourth byte of eax.)

hexoutr:
		push	ecx
		inc	ecx
		rol	eax, 8

;; The hexout subroutine stores at edi an ASCII representation of the
;; hexadecimal value in al. Both al and ah are destroyed in the
;; process. edi is advanced two bytes.

hexout:

;; The first instruction breaks apart al into two separate nybbles,
;; one each in ah and al. The high nybble is handled first, then when
;; the hexout0 "subroutine" returns, the low nybble is handled, and
;; hexout returns to the real caller.

		aam	16
		call	hexout0
hexout0:	xchg	al, ah
		cmp	al, 9
		jbe	under10
		add	al, 'A' - ('9' + 1)
under10:	add	al, '0'
		stosb
		ret

;; The program ends here. The next 64 bytes in memory is where the
;; data is stored.

UDATASEG

;; Each line of the program's output is formatted as follows:
;;
;; FILEOFFS: HEXL HEXL HEXL HEXL HEXL HEXL HEXL HEXL  ASCII-CHARACTERS
;;
;; The ASCII region of the output, at far right, also doubles as the
;; input buffer.

format:
		resb	8			; 8 characters for the offset
		resb	2			; a colon and a space
		resb	5 * (linesize / 2)	; the hex byte display
		resb	1			; a space
leftsize	equ	$ - format
		resb	linesize		; the ASCII characters
		resb	1			; newline character

END
