; Copyright (c) 2002 Thomas M. Ogrisegg
;
; uptime - show system uptime
;
; syntax:
;     uptime
;
; License           :       GNU General Public License
; Author            :       Thomas Ogrisegg
; E-Mail            :       tom@rhadamanthys.org
; Version           :       1.0
; SuSV2-Compliant   :       not in SUSV2 (why?)
; GNU-compatible    :       yes
;
; $Id: uptime.asm,v 1.2 2002/06/11 08:45:10 konst Exp $

%include "system.inc"

CODESEG

%assign UTMP_RECSIZE utmp_size

%macro mdiv 1
	xor edx, edx
	_mov ebx, %1
	idiv ebx
%endmacro

ltostr1:
		xor edx, edx
		_mov ebx, 0xa
		idiv ebx
		or eax, eax
		jz .Lnext
		add al, '0'
		stosb
.Lnext:
		lea eax, [edx+'0']
		stosb
		ret

ltostr2:
		xor edx, edx
		_mov ebx, 0xa
		idiv ebx
		add al, '0'
		stosb
		lea eax, [edx+'0']
		stosb
		ret

average:
		shr eax, 0x5
		_add eax, 0xa
		push eax
		sar eax, 0xb
		call ltostr1
		mov al, '.'
		stosb
		pop eax
		and eax, 0x7ff
		imul eax, eax, 100
		sar eax, 0xb
		call ltostr2
		ret

START:
		mov ebx, esp
		sys_gettimeofday EMPTY, NULL
		mov eax, [ebx]
		mov edi, buf+1
		mov byte [edi-1], ' '
		xor ebp, ebp
		mdiv 31536000
		mov eax, edx
		mdiv 86400
		mov eax, edx
		mdiv 3600
		cmp eax, 0xc
		jng .pm
		sub eax, 0xc
		inc ebp
.pm:
		push edx
		call ltostr1
		mov al, ':'
		stosb
		pop eax
		mdiv 60
		call ltostr2
		or ebp, ebp
		mov ax, 'am'
		jz .Lam
		mov ax, 'pm'
.Lam:
		stosw
		mov eax, '  up'
		stosd
		mov ax, '  '
		stosw
		mov ebx, esp
		sys_sysinfo
		mov eax, [ebx]				; uptime
		mdiv 31536000
		mov eax, edx
		mdiv 86400
		push edx
		or eax, eax
		jz .Lnext2
		call ltostr1
		mov eax, ' day'
		stosd
		mov eax, 's,  '
		stosd
.Lnext2:
		pop eax
		mdiv 3600
		push edx
		call ltostr1
		mov al, ':'
		stosb
		pop eax
		mdiv 60
		call ltostr2
		mov ax, ', '
		stosw
		xor ebp, ebp
		sys_open utmpfile, O_RDONLY
		or eax, eax
		js .Lno_utmp
		mov [ufd], eax
		sub esp, UTMP_RECSIZE
.Lread_next:
		mov ecx, esp
		sys_read [ufd], EMPTY, UTMP_RECSIZE
		cmp long [esp+utmp.ut_type], USER_PROCESS
		jnz .Lnext
		inc ebp
.Lnext:
		or eax, eax
		jnz .Lread_next
.Lno_utmp:
		add esp, UTMP_RECSIZE
		mov eax, ebp
		call ltostr1
		mov long [edi+0x00], ' use'
		mov long [edi+0x04], 'rs, '
		mov long [edi+0x08], 'load'
		mov long [edi+0x0c], ' ave'
		mov long [edi+0x10], 'rage'
		mov word [edi+0x15], ': '
		add edi, 0x17
		mov eax, [esp+sysinfo.loads]
		call average
		mov ax, ', '
		stosw
		mov eax, [esp+sysinfo.loads+4]
		call average
		mov ax, ', '
		stosw
		mov eax, [esp+sysinfo.loads+8]
		call average
		mov al, __n
		stosb
		sys_write STDOUT, buf, 80
		sys_exit eax

utmpfile	db	_PATH_UTMP, EOL

UDATASEG

buf	UCHAR	80
ufd	ULONG	1

END
