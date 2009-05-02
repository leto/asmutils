; Copyright (C) 2002 Thomas M. Ogrisegg
;
; $Id: sysctl.asm,v 1.1 2002/02/14 17:46:22 konst Exp $
;
; sysctl - configure kernel parameters at runtime
;
; syntax:
;       sysctl [-n] [-w variable=value] [-p filename]
;
; License           :       GNU General Public License
; Author            :       Thomas Ogrisegg
; E-Mail            :       tom@rhadamanthys.org
; Version           :       0.7
; SUSV2-Compliant   :       not in SUSV2
; GNU-compatible    :       not yet
;

%include "system.inc"

%assign BUF_SIZE 0xf000

CODESEG

START:
		pop ecx
		dec ecx
		jz near _exit
		sys_chdir proc_sys
		pop esi
		xor ebp, ebp

argv_loop:
		pop esi
		or esi, esi
		jz near _exit
		xor ecx, ecx
		lodsb
		cmp al, '-'
		jnz near show_value
		lodsb
		cmp al, 'n'
		jz add_n
		cmp al, 'w'
		jz near set_value
		cmp al, 'p'
		jz read_config
opt_error:
		sys_write STDOUT, uo, ul
		sys_exit 0x1

uo	db	"Unknown option", __n
ul	equ	$ - uo

add_n:	inc ebp
		jmp argv_loop

read_config:
		pop esi
		or esi, esi
		jz .Lopen_other
		sys_open esi, O_RDONLY
		jmp .Lnext
.Lopen_other:
		sys_open syscconf, O_RDONLY
.Lnext:
		mov edx, eax
		push edx
		sys_lseek eax, 0, SEEK_END
		or eax, eax
		js near _error
		pop edx
		sys_mmap NULL, eax, PROT_READ | PROT_WRITE, MAP_PRIVATE, edx, 0x0
		or eax, eax
		js near _error
		mov esi, eax
.Lcheck_loop:
		lodsb
		cmp al, ';'
		jz .Lnext_line
		cmp al, '#'
		jz .Lnext_line
		or al, al
		jz .Lexit
		cmp al, ' '
		jng .Lcheck_loop
		jmp .Lout
.Lnext_line:
		lodsb
		or al, al
		jz .Lout
		cmp al, __n
		jnz .Lnext_line
		jmp .Lcheck_loop
.Lout:
		dec esi
		mov edi, buffer
		call do_next_value
		jmp .Lcheck_loop
.Lexit:
		sys_exit 0x0

set_value:
		pop esi
		or esi, esi
		jz near _exit
		mov edi, buffer
do_next_value:
		lodsb
		cmp al, '.'
		jz .Lstos_slash
		cmp al, '='
		jz .Lnext
		cmp al, ' '
		jng .Lnext
		stosb
		or al, al
		jnz do_next_value
		jmp opt_error
.Lstos_slash:
		mov al, '/'
		stosb
		jmp do_next_value
.Lnext:
		dec esi
		xor eax, eax
		stosb
.Lnext1:
		lodsb
		or al, al
		jz near .Lout
		cmp al, '='
		jnz .Lnext1

.Lnext1_half:
		lodsb
		cmp al, ' '
		jng .Lnext1_half

		dec esi
		mov ecx, edi
		xor edx, edx
.Lnext2:
		lodsb
		inc edx
		cmp al, ' '
		jng .Lnext3
		cmp al, ';'
		jz .Lnext3
		cmp al, '#'
		jz .Lnext3
		stosb
		jmp .Lnext2
.Lnext3:
		xor eax, eax
		stosb
		push ecx
		sys_open buffer, O_RDWR
		or eax, eax
		jns .Lall_rights
		sys_write STDOUT, noperm, nopermlen
.Lall_rights:
		pop ecx
		dec edx
		sys_write eax, ecx, edx
.Lout:
		jmp argv_loop

show_value:
		dec esi
		mov edi, buffer
.Lcopy_loop:
		lodsb
		cmp al, '.'
		jz .Lstos_slash
		stosb
		or al, al
		jnz .Lcopy_loop
		jmp .Lnext
.Lstos_slash:
		mov al, '/'
		stosb
		jmp .Lcopy_loop
.Lnext:
		sys_open buffer, O_RDONLY
		or eax, eax
		js _error
		sys_read eax, buffer, BUF_SIZE
		sys_write STDOUT, buffer, eax
		sys_exit 0x0

_error:
		sys_exit 0x1

_exit:
		sys_exit 0xff

proc_sys	db	"/proc/sys/", EOL
syscconf	db	"/etc/sysctl.conf", EOL

ig	db	" = "

noperm	db	"Could not write to key", __n, EOL
nopermlen equ $ - noperm

UDATASEG
buffer	UCHAR	BUF_SIZE
END
