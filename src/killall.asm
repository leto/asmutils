; Copyright (C) 2002 Thomas M. Ogrisegg
;
; $Id: killall.asm,v 1.3 2002/02/14 13:38:15 konst Exp $
;
; hackers' killall/killall5/pidof
;
; killall - kill processes by name 
;
; syntax:
;        killall [options] [-SIGNAL] processname
;
; options:
;        -e   ignored (this implementation of killall isnt buggy!)
;        -g   kill process group
;        -i   ask for confirmation
;        -l   list signals (currently unimplemented)
;        -q   quiet (dont report signal sending errors)
;        -v   verbose (report if signal successfully sent)
;        -V   Display version information
;        -w   currently unimplemented
;
; see signal(7) for a complete list of signal numbers.
;
; License            :        GNU General Public License
; Author             :        Thomas Ogrisegg
; E-Mail             :        tom@rhadamanthys.org
; Version            :        0.6
; SUSV2-Compliant    :        not in SUSV2
; GNU-compatible     :        nearly
;
; Exit-Codes:
;     0: killed successfully
;     1: process not found or unable to kill process
;
; pidof - find process ID of a running program
;
; syntax:
;        pidof [options] processname
;
; options:
;         -s   return only one pid
;         -x   currently unimplemented
;         -o   currently unimplemented
;
; Note:
; The original pidof prints the found pids (erroneously) in reverse order
;
; Exit-Codes:
;     0: found pid for process
;     1: process wasnt found.
;
; Version            :        0.3
; SUSV2-Compliant    :        not in SUSV2
; GNU-compatible     :        not yet
;
; killall5 - send a signal to all processes
;
; syntax:
;        killall5 [-SIGNAL]
;
; Version            :        1.0
; SUSV2-Compliant    :        not in SUSV2
; GNU-compatible     :        yes
;
; Note:
;   Most of this code is platform dependent and was only tested under
;   Linux/2.4

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
	
_error:
		sys_exit 0x2

START:
		pop ebx
		pop edi
		mov long [signal], SIGTERM
		xor eax, eax
		xor ecx, ecx
		dec ecx
		repnz scasb
		cmp long [edi-5], 'idof'
		jz near pid_of
		cmp byte [edi-2], '5'
		jz near killall_5

		mov ebp, .Lnext
		jmp parse_opts
.Lnext:
		mov long [func], enum_killall
		mov long [efunc], exit_killall
		jmp init_proc

;; This function does the actual kill of the processes. It gets ;;
;; called from within find_next_proc.                           ;;
enum_killall:
		mov edi, [opts]
		mov esi, rbuf
		call _atoi
		bt edi, 0x8		; check -g (process group)
		jnc .Lnext_kill
		neg eax
.Lnext_kill:
		push eax
		bt edi, 0x7		; check -i (interactive)
		jnc .Lkill
		sys_write STDOUT, kill_quest, killq_len
		xor ecx, ecx
		dec ecx
		mov al, ' '
		xchg esi, edi
		repnz scasb
		xchg esi, edi
		lea esi, [esi+ecx]
		not ecx
		sys_write STDOUT, esi, ecx
		sys_write STDOUT, yesno, ynlen
		sys_read STDIN, rbuf, 0x100
		cmp byte [rbuf], 'y'
		jnz .Lret
.Lkill:
		pop eax
		sys_kill eax, [signal]
		or eax, eax
		jz .Lok_killed
		bt edi, 0x6		; check -q (quiet)
		jc .Lret
		sys_write STDOUT, kill_err, kill_errlen
		ret
.Lok_killed:
		bt edi, 0x5		; check -v (verbose)
		jnc .Lret
		sys_write STDOUT, kill_success, kill_slen
.Lret:
		ret

;; init_proc opens the /proc directory and changes the current ;;
;; directory to /proc.                                         ;;
init_proc:
		sys_open proc, O_RDONLY | O_DIRECTORY
		or eax, eax
		js near _error
		mov [pfd], eax
		sys_chdir proc

;; find_next_proc pops the arguments supplied to the program     ;;
;; from the stack, tries to find an entry in the process table   ;;
;; for this and then calls func from the .bss segment which must ;;
;; have been set by an other function.                           ;;
find_next_proc:
		cmp long [edi], 0x0
		jz near _error

.Lread_dir:
		;; Clear dir buffer ;;
		xor eax, eax
		mov edi, dir
		mov ecx, 0x600
		repnz stosb

		sys_getdents [pfd], dir, 0x600
		or eax, eax
		jz near .Lout

		mov ebp, dir
.Lread_next_ent:
		cmp byte [ebp+8], 0
		jz .Lread_dir
		add bp,  [ebp+8]
		lea esi, [ebp+10]
		mov edi, rbuf
		
		lodsb
		cmp al, '0'
		jng .Lread_next_ent
		cmp al, '9'
		jg  .Lread_next_ent
.Lstrcopy_loop:
		stosb
		lodsb
		or al, al
		jnz .Lstrcopy_loop

		mov esi, _stat
.Lstrcopy_loop2:
		lodsb
		stosb
		or al, al
		jnz .Lstrcopy_loop2

		sys_open rbuf, O_RDONLY
		or eax, eax
		js .Lread_next_ent
		mov [fd], eax
		sys_read eax, rbuf, 0x100
		mov esi, rbuf
.Lfind_loop:
		lodsb
		cmp al, '('
		jnz .Lfind_loop
		xor ecx, ecx
		dec ecx
		mov edi, [esp]
		repz cmpsb
		dec esi
		lodsb
		cmp al, ')'
		jnz .Lread_next_ent
		call [func]			;; call the target function ;;
		jmp .Lread_next_ent
.Lout:
		jmp [efunc]			;; jump to exit function ;;		

;; optimize: merge with set_signal ;;
parse_opts:

.Lnext_opt:
		pop esi
		or esi, esi
		jz near .Lret
.Lsrch_loop:
		xor ecx, ecx
		lodsb
		cmp al, '-'
		jnz near .Lret_err
		lodsb
		cmp al, '-'			;; dont parse arguments after a -- ;;
		jz near .Lret_err
		cmp al, '9'
		jng near .Lint3
		cmp al, 'e'
		jz .Lnext_opt
		cmp al, 'g'
		jz near .Lset_g
		cmp al, 'i'
		jz near .Lset_i
		cmp al, 'l'
		jz near .Lint3
		cmp al, 'q'
		jz near .Lset_q
		cmp al, 'v'
		jz near .Lset_v
		cmp al, 'V'
		jz near .Lset_V
		cmp al, 'w'
		jz .Lnext_opt
		cmp al, 's'
		jz .Lset_s
		cmp al, 'x'
		jz .Lset_x
		cmp al, 'o'
		jz .Lset_o
		;;;;;;;;;;;;;;
		lea edi, [esi-1]
		mov esi, signals
.Lloadloop:
		lodsd
		or eax, eax
		jz .Lerror
		inc esi
		cmp eax, [edi]
		jnz .Lloadloop
		dec esi
		lodsb
		mov byte [signal], al
		jmp .Lret
.Lnumber:
		dec esi
		call _atoi
		mov long [signal], eax
		jmp .Lret
		;;;;;;;;;;;;;;
.Lerror:
		sys_write STDOUT, unknown_opt, uo_len
		lea esi, [edi+1]
		mov byte [esi], __n
		sub esi, 3
		sys_write STDOUT, esi, 4
		sys_exit 0x1

.Lset_g:
		inc ecx
.Lset_i:
		inc ecx
.Lset_q:
		inc ecx
.Lset_v:
		inc ecx
.Lset_V:
		inc ecx
.Lset_s:
		inc ecx
.Lset_x:
		inc ecx
.Lset_o:
		inc ecx
		bts [opts], ecx
		jmp .Lnext_opt
.Lint3:
		int3
		db 0xcc
.Lret_err:
		sub esp, 4
.Lret:
		jmp ebp

killall_5:
		mov ebp, .Lnext
		jmp parse_opts
.Lnext:
		sys_kill -1, [signal]
		sys_exit 0x0

pid_of:
		mov byte [retval], 0x1
		mov ebp, .Lnext
		jmp parse_opts
.Lnext:
		mov long [func], enum_pidof
		mov long [efunc], exit_pidof
		jmp init_proc

enum_pidof:
		mov edi, rbuf
		mov al,  ' '
		xor ecx, ecx
		dec ecx
		repnz scasb
		not ecx
		sys_write STDOUT, rbuf, ecx
		mov byte [retval], 0x0
		bt long [opts], 0x3
		jc exit_pidof
		ret
exit_pidof:
		sys_write STDOUT, NL, 1
exit_killall:
		sys_exit [retval]

proc	db	"/proc", EOL
_stat	db	"/stat", EOL
unknown_opt	db	"Unknown option: "
uo_len	equ	$ - unknown_opt
kill_quest	db "Really kill "
killq_len equ $ - kill_quest
kill_err	db	"Killing of process failed", __n
kill_errlen equ $ - kill_err
kill_success db "Successfully killed a process", __n
kill_slen equ $ - kill_success
yesno	db	"(y/n)"
ynlen equ $ - yesno
NL	db	__n

signals:
db		'HUP',0, SIGHUP,
db		'INT',0, SIGINT,
db		'QUIT',  SIGQUIT,
db		'ILL',0, SIGILL,
db		'ABRT',  SIGABRT,
db		'FPE',0, SIGFPE,
db		'KILL',  SIGKILL,
db		'SEGV',  SIGSEGV,
db		'PIPE',  SIGPIPE,
db		'ALRM',  SIGALRM,
db		'TERM',  SIGTERM,
db		'USR1',  SIGUSR1,
db		'USR2',  SIGUSR2,
db		'CHLD',  SIGCHLD,
db		'CONT',  SIGCONT,
db		'STOP',  SIGSTOP,
db		'TSTP',  SIGTSTP,
db		'TTIN',  SIGTTIN,
db		'TTOU',  SIGTTOU,
db		'BUS',0, SIGBUS,
db		'POLL',  SIGPOLL,
db		'PROF',  SIGPROF,
db		'TRAP',  SIGTRAP,
db		'URG',0, SIGURG,
db		'VTAL',  SIGVTALRM,
db		'XCPU',  SIGXCPU,
db		'XFSZ',  SIGXFSZ,
db		'IOT',0, SIGIOT,
db		'STKF',  SIGSTKFLT,
db		'IO',0,0,SIGIO,
db		'CLD',0, SIGCLD,
db		'PWR',0, SIGPWR,
db		'WINC',  SIGWINCH,
db		'UNUS',  SIGUNUSED,
db		0,0,0,0, 0

siglen equ $ - signals

UDATASEG
retval	LONG	1
opts	LONG	1
func	LONG	1
efunc	LONG	1
signal	LONG	1
fd		LONG	1
pfd		LONG	1
dir		UCHAR	0x600
rbuf	UCHAR	0x100
END
