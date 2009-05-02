; Copyright (c) 2001, 2002  Thomas M. Ogrisegg
;
; $Id: nice.asm,v 1.2 2002/02/14 13:38:15 konst Exp $
;
; nice - invoke a utility with an altered system scheduling priority
;
; syntax:
;		nice [-n priority|-priority] utility [arguments]
;
; License           :       GNU General Public License
; Author            :       Thomas Ogrisegg
; E-Mail            :       tom@rhadamanthys.org
; Version           :       1.0
; SuSV2-Compliant   :       yes
; GNU-compatible    :       no
;
; Exit-Codes:
;	127: utility could not be executed
;

%include "system.inc"

CODESEG

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
		lea ebp, [esp+ecx*4]
		add ebp, 4
		cmp ecx, 1
		jz near error
		pop esi
		pop esi
		lodsb
		cmp al, '-'
		jnz near run_default

		lodsb
		dec esi
		cmp al, 'n'
		jnz .Ldo_atoi
		pop esi

.Ldo_atoi:
		call _atoi

priority:
		sys_setpriority 0, 0, eax

;; The SuSV2 says that the utility must be invoked even if the setpriority ;;
;; syscall fails. GNU nice handles this different, but this implementation ;;
;; follows the SuSV2-description, so we do not check the return value.     ;;


;; execvp - search the environment variable PATH for the program specified ;;
;; on top of the stack and try to execute it.                              ;;
;; Attention: If the space on the current stack-frame is insufficient to   ;;
;; hold the current $PATH environment variable, the program may crash with ;;
;; a segmentation fault

		xor ecx, ecx
.Lexecvp:
		mov esi, [ebp+ecx*4]
		or esi, esi
		jz near error
		lodsd
		inc ecx
		cmp eax, 'PATH'
		jnz .Lexecvp
		lodsb
		cmp al, '='
		jnz .Lexecvp
		xor eax, eax
		xor ecx, ecx
		dec ecx
		mov edi, esi
		repnz scasb
		mov edx, ecx
		xor ecx, ecx
		dec ecx
		mov edi, [esp]
		repnz scasb
		add ecx, edx

.Lexecv_next:
		lea edi, [esp+ecx]
.Lcopy_loop:
		lodsb
		cmp al, ':'
		jz .Lpath_end
		stosb
		or al, al
		jnz .Lcopy_loop

.Lpath_end:
		push esi
		mov esi, [esp+4]
		mov al, '/'
		stosb

.Lcopy_loop2:
		lodsb
		stosb
		or al, al
		jnz .Lcopy_loop2
		lea ebx, [esp+ecx+4]
		mov edi, ecx
		pop esi
		sys_execve ebx, esp, ebp
		mov ecx, edi
		jmp .Lexecv_next
		sys_exit 0x0

error:
		sys_exit 127

run_default:
		sub esp, 4
		mov eax, 0xa
		jmp priority

END
