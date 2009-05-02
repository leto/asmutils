; Copyright (c) 2002 Thomas M. Ogrisegg
;
; scons - serial terminal
;
; syntax:
;       scons serialdevice (e.g. /dev/ttyS1)
;
; License          :     GNU General Public License
; Author           :     Thomas Ogrisegg
; E-Mail           :     tom@rhadamanthys.org
; Version          :     0.8
; Created          :     03/15/02
;
; $Id: scons.asm,v 1.2 2002/08/16 15:07:08 konst Exp $

%include "system.inc"

%assign IOBUF_SIZE 100

CODESEG

init	db	__r, __n

quit:
		sys_ioctl STDIN, TCSETS, term
		sys_exit 0x42

START:
		pop ecx
		dec ecx
		jz near .syntax_error
		pop esi
		pop esi
		sys_signal SIGQUIT, quit
		sys_open esi, O_RDWR | O_NOCTTY
		or eax, eax
		js near .open_error
		mov [fd], eax
		sys_ioctl eax, TCGETS, esp
%ifdef	__LINUX__
		and long [esp+termios.c_cflag], ~(CBAUD | CBAUDEX);~B38400
		or long [esp+termios.c_cflag], B9600	;B38400
%else
		mov dword [esp+termios.c_cflag], B9600
%endif
		sys_ioctl [fd], TCSETS, esp
		sys_ioctl STDIN, TCGETS, term
		sys_ioctl STDIN, TCGETS, esp
		lea edi, [esp+termios.c_cc]
		mov ecx, NCCS
		xor eax, eax
		repnz stosb
		mov byte [esp+termios.c_cc+VQUIT], 0x1c
		and dword [esp+termios.c_lflag], ~(ECHO | ICANON)
		sys_ioctl STDIN, TCSETS, esp
		sys_write [fd], init, 2
.Lread_write:
		push long 0x00000001
		push long STDIN
		push long 0x00000001
		push long [fd]
.Lnext:
		mov edi, esp
		sys_poll edi, 2, 100000
		test long [esp+4], 0x00010000
		jz .Lread_in
		test long [esp+0xc], 0x00010000
		jz .Lexit2
		jmp .Lnext
.Lread_in:
		sys_read STDIN, iobuf, IOBUF_SIZE
		sys_write [fd], iobuf, eax
		jmp .Lnext
.Lexit2:
		sys_read [fd], iobuf, IOBUF_SIZE
		sys_write STDOUT, iobuf, eax
		jmp .Lnext

.open_error:
		sys_write STDOUT, openerr, opelen
		sys_exit 0x1

.syntax_error:
		sys_write STDOUT, syntax, synlen
		sys_exit 0x2

syntax	db	"$@ serialdevice (e.g. /dev/ttyS0)", __n
synlen	equ	$	-	syntax
openerr	db	"Error opening serial device", __n
opelen	equ	$	-	openerr

UDATASEG
iobuf	UCHAR	IOBUF_SIZE
fd		LONG	1
term	B_STRUC	termios,.c_cflag,.c_lflag,.c_cc
END
