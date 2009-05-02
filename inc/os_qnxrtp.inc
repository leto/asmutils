; Copyright (C) 2001 Konstantin Boldyshev <konst@linuxassembly.org>
;
; $Id: os_qnxrtp.inc,v 1.2 2002/02/02 12:33:39 konst Exp $
;
; file          : os_qnxrtp.inc
; created       : 16-Aug-2001
; modified      : 20-Aug-2001
; version       : 0.15
; assembler     : nasm 0.98
; description   : QNX RTP 6.1.0 kernel constants
; author        : Konstantin Boldyshev <konst@linuxassembly.org>
; comment       : included from system.inc

%ifndef __SYSTEM_INC
%error "this file must be included from system.inc !"
%endif

%ifndef __QNXRTP_INC
%define __QNXRTP_INC

%macro DO_SYSCALL 0
%if __OPTIMIZE__=__O_SIZE__
	push	ebp
	push	edi
	push	esi
	push	edx
	push	ecx
	push	ebx
	push	eax
%endif
	int	0x28
%if __OPTIMIZE__=__O_SIZE__
	add	esp,byte 7*4
%endif
%endmacro

%macro	SYSCALL_GATE 0
__syscall_gate:

	DO_SYSCALL
	ret
%endmacro

%endif
