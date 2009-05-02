; Copyright (C) 2001, 2002 Thomas M. Ogrisegg
;
; $Id: nohup.asm,v 1.2 2002/02/14 13:38:15 konst Exp $
;
; nohup - invoke a utility immun to hangups
;
; syntax:
;		nohup utility [arguments]
;
; License           :       GNU General Public License
; Author            :       Thomas Ogrisegg
; E-Mail            :       tom@rhadamanthys.org
; Version           :       1.0
; SuSV2-Compliant   :       yes
; GNU-compatible    :       yes
;
; Exit-Codes:
;	  1: nohup.out could not be created, or insufficient arguments were given.
;   127: utility could not be executed
;

%include "system.inc"

CODESEG

_error:
		sys_exit 0x1

check_term:
		push eax
		sys_ioctl eax, TCGETS, termbuf
		pop ebx
		or eax, eax
		js .Lreturn
		sys_close ebx
		sys_dup [nfd]
.Lreturn:
		ret

START:
		pop ecx
		lea ebp, [esp+ecx*4]
		add ebp, 4
		add esp, 4
		dec ecx
		jz _error

		sys_signal SIGHUP, SIG_IGN

		sys_open nohup, O_CREAT | O_RDWR | O_APPEND, 0x180 ; = 0600
		or eax, eax
		jns .Lno_openerr

		xor ecx, ecx
.Lsrch_home:
		mov esi, [ebp+ecx*4]
		inc ecx
		lodsd
		cmp eax, 'HOME'
		jnz .Lsrch_home
		lodsb
		cmp al, '='
		jnz .Lsrch_home
		sys_chdir esi
		sys_open nohup, O_CREAT | O_RDWR | O_APPEND, 0x180 ; = 0600
		or eax, eax
		js near _error

.Lno_openerr:
		mov [nfd], eax

		mov eax, 1
		call check_term
		mov eax, 2
		call check_term

		sys_close [nfd]

;; execvp - search the environment variable PATH for the program specified ;;
;; on top of the stack.                                                    ;;
;; Attention: If the space on the current stack-frame is insufficient to   ;;
;; hold the current $PATH environment variable, the program may crash with ;;
;; a segmentation fault

		xor ecx, ecx
.Lexecvp:
		mov esi, [ebp+ecx*4]
		or esi, esi
		jz near _error
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

nohup	db	"nohup.out"

UDATASEG
termbuf	B_STRUC	termios
nfd		LONG	1
END
