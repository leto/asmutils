; Copyright (C) 2002 Thomas M. Ogrisegg
;
; $Id: cmp.asm,v 1.3 2002/08/16 15:07:08 konst Exp $
;
; cmp - compare two files
;
; syntax:
;        cmp [ -l | -s ] file1 file2
;
; Note: -l and -s are currently ignored
;
; License           :       GNU General Public License
; Author            :       Thomas Ogrisegg
; E-Mail            :       tom@rhadamanthys.org
; Version           :       0.91
; Release-Date      :       02/12/02
; Last updated      :       03/15/02
; SuSV2-Compliant   :       not yet
; GNU-compatible    :       not yet
;
; 0.91:	15-Mar-2001	bugfixes and size improvements (KB)
;
; TODO: modify compare algorithm - do not read entire file into memory,
;	use static buffer and compare chunk after chunk.

%include "system.inc"

CODESEG

ltostr:
		_mov ebx, 0x0a
		_mov ecx, 0x10
		mov edi, esi
		add esi, ecx
.Ldiv:
		xor edx, edx
		idiv ebx
		add dl, '0'
		mov byte [esi+ecx], dl
		dec ecx
		or  eax, eax
		jnz .Ldiv

		add esi, ecx
		sub ecx, byte 0x10
		neg ecx
		inc esi
		repnz movsb
		ret

lstrcpy:
		lodsb
.Llabel:
		stosb
		lodsb
		or al, al
		jnz .Llabel
		mov al, ' '
		stosb
		ret

START:
		pop ecx
		cmp ecx, byte 0x2
		jng near .Lsyntax_error
		pop esi
		xor ebp, ebp

.Larg_loop:
		pop esi
		or esi, esi
		jz near .Lcommit
		lodsb
		cmp al, '-'
		jnz .Lopen_file
		lodsb
		or al, al
		jz .Lopen_term
		cmp al, 's'
		jz .Lset_s
		cmp al, 'l'
		jnz near .Lsyntax_error
		or long [opts], 0x10
		jmps .Larg_loop
.Lset_s:
		or long [opts], 0x8
		jmps .Larg_loop

.Lopen_term:
		dec esi
		dec esi
		mov [fname1+ebp*4], esi
		or ebp, ebp
		jnz .Lcommit
		inc ebp
		jmps .Larg_loop
.Lopen_file:
		dec esi
		mov [fname1+ebp*4], esi
		sys_open esi, O_RDONLY
		or eax, eax
		js near .Lsyntax_error
		mov [ffd1+ebp*4], eax
		or ebp, ebp
		jnz .Lcommit
		inc ebp
		jmp .Larg_loop

.Lcommit:
		mov dword [cbrk],_end
		xor ebp, ebp
		dec ebp
.Lloop2:
		inc ebp
		sys_lseek [ffd1+ebp*4], 0, SEEK_END
		or eax, eax
		jz .Lread_to_mem	;could be non-regular file
.Lmmap:
		mov edi,[ffd1+ebp*4]
		push ebp
		sys_mmap NULL, eax, PROT_READ, MAP_PRIVATE, EMPTY, 0
		pop ebp
		xchg eax,ecx
		or ecx, ecx
		jns .Lnext		;file mmaped ok

.Lread_to_mem:
		mov esi, [cbrk]
		push esi
.Lalloc:
		mov ecx, esi
		mov edx, 0x1000
		add esi, edx
		sys_brk esi
.Lread:
		sys_read [ffd1+ebp*4]
		cmp edx, eax
		jz  .Lalloc
.Lread_done:
		mov [cbrk],esi
		add eax, ecx
		pop ecx
		sub eax, ecx

.Lnext:
		mov [map1+ebp*4], ecx
		mov [len1+ebp*4], eax
		or ebp, ebp
		jz near .Lloop2
		
		push long map1
		mov esi, [map1]
		mov edi, [map2]
		mov ecx, [len1]
		cmp ecx, [len2]
		jnge .Lnext2
		pop ecx
		push long map2
		mov ecx, [len2]
.Lnext2:
		repz cmpsb
		pop edi
		mov edx, ecx
		or ecx, ecx
		jnz .Lnope

		mov ecx, [len1]
		cmp ecx, [len2]
		jz .Lexit_ok

.Lcheck_next:
		sys_write STDOUT, EOF, eoflen

		mov edi, [edi-0x10]
		mov esi, edi
.n0:
		lodsb
		or al, al
		jnz .n0
		
		mov byte [esi-1], __n
		sub esi, edi
		sys_write EMPTY, edi, esi

.Lexit_err:
		_mov ebx, 1
.Lexit:
		sys_exit
.Lexit_ok:
		_mov ebx, 0
		jmps .Lexit
.Lsyntax_error:
		_mov ebx, 2
		jmps .Lexit

.Lnope:
		mov ecx, [edi+8]
		sub ecx, edx
		push ecx
		mov edi, [edi]
		mov al, __n
		xor ebx, ebx

.Lfind_crs:
		inc ebx
		repnz scasb
		or ecx, ecx
		jnz .Lfind_crs

		mov edi, buffer
		mov esi, [fname1]
		call lstrcpy
		mov esi, [fname2]
		call lstrcpy
		mov esi, differ
		call lstrcpy
		pop eax
		push ebx
		mov esi, edi
		call ltostr
		mov esi, line
		call lstrcpy
		pop eax
		mov esi, edi
		call ltostr
		mov al, __n
		stosb
		sub edi, buffer
		sys_write STDOUT, buffer, edi
		jmp .Lexit_err

EOF	db	"cmp: EOF on "
eoflen	equ $ - EOF
differ	db	"differ: char", EOL
line	db	", line", EOL

UDATASEG

fname1	LONG	1
fname2	LONG	1
ffd1	LONG	1
ffd2	LONG	1
map1	LONG	1
map2	LONG	1
len1	LONG	1
len2	LONG	1
cbrk	LONG	1
opts	LONG	1
buffer	UCHAR	0x200

END

%ifdef __VIM__
vi:syntax=nasm
%endif
