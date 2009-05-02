; Copyright (C) 2002 Thomas M. Ogrisegg
;
; truss - trace systemcalls of other processes
;
; syntax:
;       truss program
;
; License           :       GNU General Public License
; Author            :       Thomas Ogrisegg
; E-Mail            :       tom@rhadamanthys.org
; Created           :       05/05/02
; Last updated      :       06/09/02
; Version           :       0.1
; SuSV2-Compliant   :       not in SUSV2
; GNU-compatible    :       no GNU pendant
;
; $Id: truss.asm,v 1.2 2002/08/18 14:58:37 konst Exp $
;
; TODO:
;     trace pid's (PTRACE_ATTACH)
;     show parameters of syscall
;
; Notes:
;
; The following Shell-Script was used to extract the systemcall names:
; (a smiliar script should work with FreeBSD)
;
;#! /bin/sh
;
;grep "^#define __NR_" /usr/include/asm/unistd.h | \
;sed -e 's/^#define __NR_//' | awk '
;BEGIN   {
;		FS=" "
;}
;{
;		F = $1;
;		B = $2;
;		print $1 "  db  " "\""$1"\", EOL";
;}'
;
; The following Shell-Script was used to print the systemcall index:
;
;#! /bin/sh
;
;grep "^#define __NR_" /usr/include/asm/unistd.h | \
;sed -e 's/^#define __NR_//' | awk '
;BEGIN   {
;		FS=" "
;		print "syscall_table:"
;}
;{
;		F = $1;
;		B = $2;
;		print "  dd  " $1;
;}'
;
; General Notes on porting:
;
; SystemV-Unices (Solaris + Unixware) use proc(5)fs and do not provide a
; ptrace(2) Systemcall.
;
; At the BSD-Side it's a bit different. NetBSD and OpenBSD only provide
; a ktrace(2) Systemcall, but FreeBSD's ptrace is very similiar to  the
; Linux one. (Actually, the Net- and OpenBSD both have a ptrace System-
; call, but it doesn't "understand" the PTRACE_SYSCALL parameter)
;

%include "system.inc"

%ifdef __LINUX__
%assign PTRACE_TRACEME 0
%assign PTRACE_PEEKUSR 3
%assign PTRACE_SYSCALL 24
%assign PTRACE_GETREGS 12

struc user_regs
.ebx    LONG    1
.ecx    LONG    1
.edx    LONG    1
.esi    LONG    1
.edi    LONG    1
.ebp    LONG    1
.eax    LONG    1
.ds     USHORT  1
.__ds   USHORT  1
.es     USHORT  1
.__es   USHORT  1
.fs     USHORT  1
.__fs   USHORT  1
.gs     USHORT  1
.__gs   USHORT  1
.orig_eax   LONG    1
.eip    LONG    1
.cs     USHORT  1
.__cs   USHORT  1
.eflags LONG    1
.esp    LONG    1
.ss     USHORT  1
.__ss   USHORT  1
endstruc
%endif

CODESEG

_exit  db  "exit", EOL
_fork  db  "fork", EOL
_read  db  "read", EOL
_write  db  "write", EOL
_open  db  "open", EOL
_close  db  "close", EOL
_waitpid  db  "waitpid", EOL
_creat  db  "creat", EOL
_link  db  "link", EOL
_unlink  db  "unlink", EOL
_execve  db  "execve", EOL
_chdir  db  "chdir", EOL
_time  db  "time", EOL
_mknod  db  "mknod", EOL
_chmod  db  "chmod", EOL
_lchown  db  "lchown", EOL
_break  db  "break", EOL
_oldstat  db  "oldstat", EOL
_lseek  db  "lseek", EOL
_getpid  db  "getpid", EOL
_mount  db  "mount", EOL
_umount  db  "umount", EOL
_setuid  db  "setuid", EOL
_getuid  db  "getuid", EOL
_stime  db  "stime", EOL
_ptrace  db  "ptrace", EOL
_alarm  db  "alarm", EOL
_oldfstat  db  "oldfstat", EOL
_pause  db  "pause", EOL
_utime  db  "utime", EOL
_stty  db  "stty", EOL
_gtty  db  "gtty", EOL
_access  db  "access", EOL
_nice  db  "nice", EOL
_ftime  db  "ftime", EOL
_sync  db  "sync", EOL
_kill  db  "kill", EOL
_rename  db  "rename", EOL
_mkdir  db  "mkdir", EOL
_rmdir  db  "rmdir", EOL
_dup  db  "dup", EOL
_pipe  db  "pipe", EOL
_times  db  "times", EOL
_prof  db  "prof", EOL
_brk  db  "brk", EOL
_setgid  db  "setgid", EOL
_getgid  db  "getgid", EOL
_signal  db  "signal", EOL
_geteuid  db  "geteuid", EOL
_getegid  db  "getegid", EOL
_acct  db  "acct", EOL
_umount2  db  "umount2", EOL
_lock  db  "lock", EOL
_ioctl  db  "ioctl", EOL
_fcntl  db  "fcntl", EOL
_mpx  db  "mpx", EOL
_setpgid  db  "setpgid", EOL
_ulimit  db  "ulimit", EOL
_oldolduname  db  "oldolduname", EOL
_umask  db  "umask", EOL
_chroot  db  "chroot", EOL
_ustat  db  "ustat", EOL
_dup2  db  "dup2", EOL
_getppid  db  "getppid", EOL
_getpgrp  db  "getpgrp", EOL
_setsid  db  "setsid", EOL
_sigaction  db  "sigaction", EOL
_sgetmask  db  "sgetmask", EOL
_ssetmask  db  "ssetmask", EOL
_setreuid  db  "setreuid", EOL
_setregid  db  "setregid", EOL
_sigsuspend  db  "sigsuspend", EOL
_sigpending  db  "sigpending", EOL
_sethostname  db  "sethostname", EOL
_setrlimit  db  "setrlimit", EOL
_getrlimit  db  "getrlimit", EOL
_getrusage  db  "getrusage", EOL
_gettimeofday  db  "gettimeofday", EOL
_settimeofday  db  "settimeofday", EOL
_getgroups  db  "getgroups", EOL
_setgroups  db  "setgroups", EOL
_select  db  "select", EOL
_symlink  db  "symlink", EOL
_oldlstat  db  "oldlstat", EOL
_readlink  db  "readlink", EOL
_uselib  db  "uselib", EOL
_swapon  db  "swapon", EOL
_reboot  db  "reboot", EOL
_readdir  db  "readdir", EOL
_mmap  db  "mmap", EOL
_munmap  db  "munmap", EOL
_truncate  db  "truncate", EOL
_ftruncate  db  "ftruncate", EOL
_fchmod  db  "fchmod", EOL
_fchown  db  "fchown", EOL
_getpriority  db  "getpriority", EOL
_setpriority  db  "setpriority", EOL
_profil  db  "profil", EOL
_statfs  db  "statfs", EOL
_fstatfs  db  "fstatfs", EOL
_ioperm  db  "ioperm", EOL
_socketcall  db  "socketcall", EOL
_syslog  db  "syslog", EOL
_setitimer  db  "setitimer", EOL
_getitimer  db  "getitimer", EOL
_stat  db  "stat", EOL
_lstat  db  "lstat", EOL
_fstat  db  "fstat", EOL
_olduname  db  "olduname", EOL
_iopl  db  "iopl", EOL
_vhangup  db  "vhangup", EOL
_idle  db  "idle", EOL
_vm86old  db  "vm86old", EOL
_wait4  db  "wait4", EOL
_swapoff  db  "swapoff", EOL
_sysinfo  db  "sysinfo", EOL
_ipc  db  "ipc", EOL
_fsync  db  "fsync", EOL
_sigreturn  db  "sigreturn", EOL
_clone  db  "clone", EOL
_setdomainname  db  "setdomainname", EOL
_uname  db  "uname", EOL
_modify_ldt  db  "modify_ldt", EOL
_adjtimex  db  "adjtimex", EOL
_mprotect  db  "mprotect", EOL
_sigprocmask  db  "sigprocmask", EOL
_create_module  db  "create_module", EOL
_init_module  db  "init_module", EOL
_delete_module  db  "delete_module", EOL
_get_kernel_syms  db  "get_kernel_syms", EOL
_quotactl  db  "quotactl", EOL
_getpgid  db  "getpgid", EOL
_fchdir  db  "fchdir", EOL
_bdflush  db  "bdflush", EOL
_sysfs  db  "sysfs", EOL
_personality  db  "personality", EOL
_afs_syscall  db  "afs_syscall", EOL
_setfsuid  db  "setfsuid", EOL
_setfsgid  db  "setfsgid", EOL
_llseek  db  "_llseek", EOL
_getdents  db  "getdents", EOL
_newselect  db  "_newselect", EOL
_flock  db  "flock", EOL
_msync  db  "msync", EOL
_readv  db  "readv", EOL
_writev  db  "writev", EOL
_getsid  db  "getsid", EOL
_fdatasync  db  "fdatasync", EOL
_sysctl  db  "_sysctl", EOL
_mlock  db  "mlock", EOL
_munlock  db  "munlock", EOL
_mlockall  db  "mlockall", EOL
_munlockall  db  "munlockall", EOL
_sched_setparam  db  "sched_setparam", EOL
_sched_getparam  db  "sched_getparam", EOL
_sched_setscheduler  db  "sched_setscheduler", EOL
_sched_getscheduler  db  "sched_getscheduler", EOL
_sched_yield  db  "sched_yield", EOL
_sched_get_priority_max  db  "sched_get_priority_max", EOL
_sched_get_priority_min  db  "sched_get_priority_min", EOL
_sched_rr_get_interval  db  "sched_rr_get_interval", EOL
_nanosleep  db  "nanosleep", EOL
_mremap  db  "mremap", EOL
_setresuid  db  "setresuid", EOL
_getresuid  db  "getresuid", EOL
_vm86  db  "vm86", EOL
_query_module  db  "query_module", EOL
_poll  db  "poll", EOL
_nfsservctl  db  "nfsservctl", EOL
_setresgid  db  "setresgid", EOL
_getresgid  db  "getresgid", EOL
_prctl  db  "prctl", EOL
_rt_sigreturn  db  "rt_sigreturn", EOL
_rt_sigaction  db  "rt_sigaction", EOL
_rt_sigprocmask  db  "rt_sigprocmask", EOL
_rt_sigpending  db  "rt_sigpending", EOL
_rt_sigtimedwait  db  "rt_sigtimedwait", EOL
_rt_sigqueueinfo  db  "rt_sigqueueinfo", EOL
_rt_sigsuspend  db  "rt_sigsuspend", EOL
_pread  db  "pread", EOL
_pwrite  db  "pwrite", EOL
_chown  db  "chown", EOL
_getcwd  db  "getcwd", EOL
_capget  db  "capget", EOL
_capset  db  "capset", EOL
_sigaltstack  db  "sigaltstack", EOL
_sendfile  db  "sendfile", EOL
_getpmsg  db  "getpmsg", EOL
_putpmsg  db  "putpmsg", EOL
_vfork  db  "vfork", EOL
_ugetrlimit  db  "ugetrlimit", EOL
_mmap2  db  "mmap2", EOL
_truncate64  db  "truncate64", EOL
_ftruncate64  db  "ftruncate64", EOL
_stat64  db  "stat64", EOL
_lstat64  db  "lstat64", EOL
_fstat64  db  "fstat64", EOL
_lchown32  db  "lchown32", EOL
_getuid32  db  "getuid32", EOL
_getgid32  db  "getgid32", EOL
_geteuid32  db  "geteuid32", EOL
_getegid32  db  "getegid32", EOL
_setreuid32  db  "setreuid32", EOL
_setregid32  db  "setregid32", EOL
_getgroups32  db  "getgroups32", EOL
_setgroups32  db  "setgroups32", EOL
_fchown32  db  "fchown32", EOL
_setresuid32  db  "setresuid32", EOL
_getresuid32  db  "getresuid32", EOL
_setresgid32  db  "setresgid32", EOL
_getresgid32  db  "getresgid32", EOL
_chown32  db  "chown32", EOL
_setuid32  db  "setuid32", EOL
_setgid32  db  "setgid32", EOL
_setfsuid32  db  "setfsuid32", EOL
_setfsgid32  db  "setfsgid32", EOL
_pivot_root  db  "pivot_root", EOL
_mincore  db  "mincore", EOL
_madvise  db  "madvise", EOL
_madvise1  db  "madvise1", EOL
_getdents64  db  "getdents64", EOL
_fcntl64  db  "fcntl64", EOL

%ifdef __LINUX__
syscall_table:
  dd  _exit
  dd  _fork
  dd  _read
  dd  _write
  dd  _open
  dd  _close
  dd  _waitpid
  dd  _creat
  dd  _link
  dd  _unlink
  dd  _execve
  dd  _chdir
  dd  _time
  dd  _mknod
  dd  _chmod
  dd  _lchown
  dd  _break
  dd  _oldstat
  dd  _lseek
  dd  _getpid
  dd  _mount
  dd  _umount
  dd  _setuid
  dd  _getuid
  dd  _stime
  dd  _ptrace
  dd  _alarm
  dd  _oldfstat
  dd  _pause
  dd  _utime
  dd  _stty
  dd  _gtty
  dd  _access
  dd  _nice
  dd  _ftime
  dd  _sync
  dd  _kill
  dd  _rename
  dd  _mkdir
  dd  _rmdir
  dd  _dup
  dd  _pipe
  dd  _times
  dd  _prof
  dd  _brk
  dd  _setgid
  dd  _getgid
  dd  _signal
  dd  _geteuid
  dd  _getegid
  dd  _acct
  dd  _umount2
  dd  _lock
  dd  _ioctl
  dd  _fcntl
  dd  _mpx
  dd  _setpgid
  dd  _ulimit
  dd  _oldolduname
  dd  _umask
  dd  _chroot
  dd  _ustat
  dd  _dup2
  dd  _getppid
  dd  _getpgrp
  dd  _setsid
  dd  _sigaction
  dd  _sgetmask
  dd  _ssetmask
  dd  _setreuid
  dd  _setregid
  dd  _sigsuspend
  dd  _sigpending
  dd  _sethostname
  dd  _setrlimit
  dd  _getrlimit
  dd  _getrusage
  dd  _gettimeofday
  dd  _settimeofday
  dd  _getgroups
  dd  _setgroups
  dd  _select
  dd  _symlink
  dd  _oldlstat
  dd  _readlink
  dd  _uselib
  dd  _swapon
  dd  _reboot
  dd  _readdir
  dd  _mmap
  dd  _munmap
  dd  _truncate
  dd  _ftruncate
  dd  _fchmod
  dd  _fchown
  dd  _getpriority
  dd  _setpriority
  dd  _profil
  dd  _statfs
  dd  _fstatfs
  dd  _ioperm
  dd  _socketcall
  dd  _syslog
  dd  _setitimer
  dd  _getitimer
  dd  _stat
  dd  _lstat
  dd  _fstat
  dd  _olduname
  dd  _iopl
  dd  _vhangup
  dd  _idle
  dd  _vm86old
  dd  _wait4
  dd  _swapoff
  dd  _sysinfo
  dd  _ipc
  dd  _fsync
  dd  _sigreturn
  dd  _clone
  dd  _setdomainname
  dd  _uname
  dd  _modify_ldt
  dd  _adjtimex
  dd  _mprotect
  dd  _sigprocmask
  dd  _create_module
  dd  _init_module
  dd  _delete_module
  dd  _get_kernel_syms
  dd  _quotactl
  dd  _getpgid
  dd  _fchdir
  dd  _bdflush
  dd  _sysfs
  dd  _personality
  dd  _afs_syscall
  dd  _setfsuid
  dd  _setfsgid
  dd  _llseek
  dd  _getdents
  dd  _newselect
  dd  _flock
  dd  _msync
  dd  _readv
  dd  _writev
  dd  _getsid
  dd  _fdatasync
  dd  _sysctl
  dd  _mlock
  dd  _munlock
  dd  _mlockall
  dd  _munlockall
  dd  _sched_setparam
  dd  _sched_getparam
  dd  _sched_setscheduler
  dd  _sched_getscheduler
  dd  _sched_yield
  dd  _sched_get_priority_max
  dd  _sched_get_priority_min
  dd  _sched_rr_get_interval
  dd  _nanosleep
  dd  _mremap
  dd  _setresuid
  dd  _getresuid
  dd  _vm86
  dd  _query_module
  dd  _poll
  dd  _nfsservctl
  dd  _setresgid
  dd  _getresgid
  dd  _prctl
  dd  _rt_sigreturn
  dd  _rt_sigaction
  dd  _rt_sigprocmask
  dd  _rt_sigpending
  dd  _rt_sigtimedwait
  dd  _rt_sigqueueinfo
  dd  _rt_sigsuspend
  dd  _pread
  dd  _pwrite
  dd  _chown
  dd  _getcwd
  dd  _capget
  dd  _capset
  dd  _sigaltstack
  dd  _sendfile
  dd  _getpmsg
  dd  _putpmsg
  dd  _vfork
  dd  _ugetrlimit
  dd  _mmap2
  dd  _truncate64
  dd  _ftruncate64
  dd  _stat64
  dd  _lstat64
  dd  _fstat64
  dd  _lchown32
  dd  _getuid32
  dd  _getgid32
  dd  _geteuid32
  dd  _getegid32
  dd  _setreuid32
  dd  _setregid32
  dd  _getgroups32
  dd  _setgroups32
  dd  _fchown32
  dd  _setresuid32
  dd  _getresuid32
  dd  _setresgid32
  dd  _getresgid32
  dd  _chown32
  dd  _setuid32
  dd  _setgid32
  dd  _setfsuid32
  dd  _setfsgid32
  dd  _pivot_root
  dd  _mincore
  dd  _madvise
  dd  _madvise1
  dd  _getdents64
  dd  _fcntl64
%endif

hextostr:
		std
		push edi
		add edi, 0x7
		mov edx, 0x8
.Lloop:
		mov al, cl
		and al, 0xf
		add al, '0'
		cmp al, '9'
		jng .Lstos
		add al, 0x27
.Lstos:
		stosb
		shr ecx, 0x4
		jz .Lout
		dec edx
		jnz .Lloop
.Lout:
		cld
		mov esi, edi
		pop edi
		dec edi
		mov ecx, edx
		lea eax, [edx-0x9]
		neg eax
		lea ecx, [eax+1]
		repnz movsb
		mov byte [edi+eax],0
		ret

		foo	db	"Hello", __n
START:
		pop ecx
		lea ebp, [esp+ecx*4+4]
		dec ecx
		jz near .Lexit
		pop esi

		sys_fork

		mov [pid], eax
		or   eax, eax
		js   near .Lexit
		jz   near .trace

.Lnext:
		sys_wait4 -1, NULL, NULL, NULL
		or eax, eax
		js near .Lexit
		sys_ptrace PTRACE_SYSCALL, [pid], 0x1, NULL

.wait_loop:
		sys_wait4 -1, NULL, NULL, NULL
		or eax, eax
		js near .Lexit
		sys_ptrace PTRACE_GETREGS, [pid], NULL, regs

		mov ecx, [regs.orig_eax]
		mov edi, [syscall_table+ecx*4-4]
		xor eax, eax
		xor ecx, ecx
		dec ecx
		repnz scasb
		lea edi, [edi+ecx+1]
		not ecx
		dec ecx
		sys_write STDOUT, edi, ecx
		sys_write STDOUT, pfeil, 4

		sys_ptrace PTRACE_SYSCALL, [pid], 0x1, NULL
		sys_wait4 -1, NULL, NULL, NULL

		sys_ptrace PTRACE_GETREGS, [pid], NULL, regs
		mov edi, buf+80
		mov ecx, [regs.eax]
		call hextostr
		sys_write STDOUT, buf+80, eax
		sys_write STDOUT, nl,  1
		sys_ptrace PTRACE_SYSCALL, [pid], 0x1, NULL
		jmp .wait_loop

.trace:
		sys_ptrace PTRACE_TRACEME, NULL, NULL, NULL
		xor ecx, ecx

		mov esi, [esp]
		cmp byte [esi], '/'
		jz .Ldirect_exec
		cmp byte [esi], '.'
		jz .Ldirect_exec
.Lexecvp:
		mov esi, [ebp+ecx*4]
		or esi, esi
		jz near .Lexit
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

.Ldirect_exec:
		sys_execve esi, esp, ebp

.Lexit:
		sys_exit 0x1

nl	db	__n
pfeil	db	" -> "

UDATASEG
pid	ULONG	1
buf	UCHAR	800
%ifdef __LINUX__
regs	B_STRUC	user_regs,.ebx,.ecx,.edx,.eax,.orig_eax,.eip
%endif
END
