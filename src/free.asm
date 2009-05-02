; Copyright (C) 2002 Thomas M. Ogrisegg
;
; free - display system memory usage
;
; syntax:
;        free
;
; License           :       GNU General Public License
; Author            :       Thomas Ogrisegg
; E-Mail            :       tom@rhadamanthys.org
; Version           :       0.5
; Release-Date      :       03/20/02
; GNU-compatible    :       no
; Operatingsystem   :       Linux/x86
;
; $Id: free.asm,v 1.2 2002/06/11 08:45:10 konst Exp $

%include "system.inc"

CODESEG

;; <- %eax (number to convert)
;; -> %edi (output written to (edi))
ltostr:
		_mov ebx, 0x0a
		_mov ecx, 0x7
		or eax, eax
		jnz .Ldiv
		mov byte [edi+ecx], '0'
		dec ecx
		jmps .Lout
.Ldiv:
		or eax, eax
		jz .Lout
		xor edx, edx
		idiv ebx
		add dl, '0'
		mov byte [edi+ecx], dl
		dec ecx
		jnz .Ldiv
.Lout:
		add edi, ecx
		inc ecx
		std
		mov al, ' '
		repnz stosb
		cld
		_add edi, 0x9
		_mov ecx, 0x3
		repnz stosb
		ret

START:
		sys_write STDOUT, header, headerlen
		mov ebp, esp
		sys_sysinfo ebp
		sub esp, 80
		mov edi, esp
		mov eax, [ebp+sysinfo.totalram]
		shr eax, 0xa		; div 1024
		call ltostr
		mov eax, [ebp+sysinfo.totalram]
		sub eax, [ebp+sysinfo.freeram]
		shr eax, 0xa
		call ltostr
		mov eax, [ebp+sysinfo.freeram]
		shr eax, 0xa
		call ltostr
		mov eax, [ebp+sysinfo.sharedram]
		shr eax, 0xa
		call ltostr
		mov eax, [ebp+sysinfo.bufferram]
		shr eax, 0xa
		call ltostr
		mov byte [edi], __n
		mov edi, esp
		sys_write STDOUT, edi, 60
		sys_write STDOUT, header2, header2len
		mov eax, [ebp+sysinfo.totalswap]
		shr eax, 0xa
		call ltostr
		mov eax, [ebp+sysinfo.totalswap]
		sub eax, [ebp+sysinfo.freeswap]
		shr eax, 0xa
		call ltostr
		mov eax, [ebp+sysinfo.freeswap]
		shr eax, 0xa
		call ltostr
		mov byte [edi], __n
		mov ecx, esp
		sys_write STDOUT, EMPTY, 34
		sys_exit 0x0

tab	db	__t
header	db	"             total       used       free     shared    buffers", __n, "Mem:      "
headerlen	equ	$ - header

header2	db	"Swap:     "
header2len	equ	$ - header2

END
