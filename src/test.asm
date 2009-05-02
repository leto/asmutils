; Copyright (C) 2001, 2002 Thomas M. Ogrisegg
;
; $Id: test.asm,v 1.3 2002/02/14 13:38:15 konst Exp $
;
; test - evaluate expression
;
; syntax:
;		test [expression]
;
; Please see the manual page for a description of
; options and expressions.
;
; License          :     GNU General Public License
; Author           :     Thomas Ogrisegg
; E-Mail           :     tom@rhadamanthys.org
; Version          :     0.4
; Created          :     01/06/02
; SusV2-compliant  :     not yet
; GNU-compatible   :     not yet
;
; Please report all bugs, patches, etc. to the above mentioned
; address.
;
; TODO:
;	Implement -a and -o
;	Implement negating (!) and multiple expressions
;
; Exit Codes:
;	0: Success (condition satisfied)
;	1: Error   (condition not satisfied)
;	2: Syntax error
;	3: Internal error or function not (yet) implemented
;

%include "system.inc"

%assign OP_NOT 0x1
%assign OP_EQU 0x2

CODESEG

syntax_error:
		sys_exit 0x2

todo:
		sys_exit 0x3


;; atoi - Convert a string into an integer ;;
;; expects the string in esi and returns   ;;
;; the result in eax                       ;;

_atoi:
		xor eax, eax
		xor edx, edx
.LSpace:
		lodsb
		cmp al, 0x21
		jng .LSpace
.Lfe2:
		cmp al, 47
		jng .Lout
		cmp al, 58
		jg .Lout
		sub al, '0'
		add edx, eax
		lodsb
		cmp al, 47
		jng .Lout
		cmp al, 58
		jg .Lout
		imul edx, 0xa
		jmp .Lfe2
.Lout:
		mov eax, edx
		ret

START:
		pop ecx
		cmp ecx, 1
		jz near _exit_error

		xor ebp, ebp
		pop edi
		pop edi
		cmp byte [edi], '-'
		jz near do_option
		cmp byte [edi], '!'		 ; negate
		jz todo

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		pop esi
		or esi, esi
		jz syntax_error
		cmp byte  [esi], '='
		jz near strcmp
		cmp word [esi], '!='
		jz near nstrcmp
		lodsb
		cmp al, '-'
		jnz todo
		lodsw
		cmp byte [esi], 0
		jnz near syntax_error
		cmp ax, 'eq'
		jz near strcmp
		cmp ax, 'ne'
		jz near nstrcmp
		cmp ax, 'gt'
		jz near algcmpg
		cmp ax, 'ge'
		jz near ealgcmpg
		cmp ax, 'lt'
		jz near algcmpl
		cmp ax, 'le'
		jz near ealgcmpl
		jmp syntax_error

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ealgcmpg:
		mov ebp, OP_EQU
algcmpg:
		xor edx, edx
		pop esi
		call _atoi
		push eax
		mov esi, edi
		call _atoi
		pop ebx
		cmp ebp, OP_EQU
		jz .Lnext
		cmp eax, ebx
		jg near _exit_success
		jmp _exit_error
.Lnext:
		cmp eax, ebx
		jge near _exit_success
		jmp _exit_error

ealgcmpl:
		mov ebp, OP_EQU
algcmpl:
		xor edx, edx
		pop esi
		call _atoi
		push eax
		mov esi, edi
		call _atoi
		pop ebx
		cmp ebp, OP_EQU
		jz .Lnext
		cmp eax, ebx
		jnge near _exit_success
		jmp _exit_error
.Lnext:
		cmp eax, ebx
		jng near _exit_success
		jmp _exit_error

do_option:
		mov byte bl, [edi+1]
		pop edx
		or edx, edx
		jz near _exit_error
		cmp bl, 'z'
		jz near is_zero_str
		cmp bl, 'n'
		jz near nis_zero_str
		cmp bl, 't'
		jz is_term

		sys_lstat edx, statbuf
		or eax, eax
		js near _exit_error
		mov byte bl, [edi+1]
		;;;;;;;;;;;;;;
		cmp bl, 's'
		jz	has_size
		cmp bl, 'r'
		jz is_readable
		cmp bl, 'w'
		jz is_writeable
		;;;;;;;;;;;;;;
		mov esi, opt_table
.Lfindopt:
		lodsb
		cmp al, bl
		jz .Lfound
		add esi, 0x4
		or al, al
		jnz .Lfindopt
		jmp near syntax_error
.Lfound:
		lodsd
		mov ebx, [statbuf.st_mode]
		and ebx, eax
		cmp eax, ebx
		jz near _exit_success
		jmp near _exit_error

is_term:
		mov esi, edx
		call _atoi
		sys_ioctl eax, TCGETS, termbuf
		or eax, eax
		js near _exit_error
		jmp _exit_success
has_size:
		cmp long [statbuf.st_size], 0
		jz _exit_success
		jmp _exit_error
is_writeable:
		mov ecx, O_WRONLY
		jmp do_open
is_readable:
		mov ecx, O_RDONLY
do_open:
		sys_open edx, ecx
		or eax, eax
		js _exit_error
		jmp _exit_success
nis_zero_str:
		or ebp, OP_NOT
is_zero_str:
		xor eax, eax
		cmp byte [edx], 0
		or ebp, eax
		jz _exit_success
		jmp _exit_error

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

nstrcmp:
		or ebp, OP_NOT
strcmp:
_strcmp:
		xor eax, eax
		xor ecx, ecx
		dec ecx
		pop esi
		push edi
		repnz scasb
		not ecx
		pop edi
		repz cmpsb
		cmp byte [edi-1], 0
		jnz .Lfalse
		cmp byte [esi-1], 0
		jnz .Lfalse
		inc eax
.Lfalse:
		xor eax, ebp
		jz _exit_error

_exit_success:
		sys_exit 0x0

_exit_error:
		sys_exit 0x1

NULL_str:
	db	EOL

opt_table:
db 'b'
dd 0x6000
db 'c'
dd 0x2000
db 'd'
dd 0x4000
db 'e'
dd 0x0
db 'f'
dd 0x8000
db 'g'
dd 0x400
db 'p'
dd 0x1000
db 'u'
dd 0x800
db 'x'
dd 0x40
db 0x0 ; End Of Table

UDATASEG
statbuf	B_STRUC	Stat, .st_mode, .st_size
termbuf	B_STRUC	termios
END
