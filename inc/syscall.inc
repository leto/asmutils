; Copyright (C) 1999-2002 Konstantin Boldyshev <konst@linuxassembly.org>
;
; $Id: syscall.inc,v 1.23 2003/05/26 05:03:23 konst Exp $
;
; file		: syscall.inc
; created	: 01-Aug-1999
; modified	: 26-May-2003
; version	: 0.18
; assembler	: nasm 0.98
; description	: system call macros
; author	: Konstantin Boldyshev <konst@linuxassembly.org>
; comment	: included from system.inc
;		  if you're looking for a list of system calls,
;		  better examine http://linuxassembly.org/resources.html

%ifndef	__SYSTEM_INC
%error "this file must be included from system.inc !"
%endif

%ifndef __SYSCALL_INC
%define __SYSCALL_INC

;
;__syscall helpers
;

%macro	__push_syscall_args 1
%assign	P %1
%if P>0
 %if P>1
  %if P>2
   %if P>3
    %if P>4
     %if P>5
	push	ebp
     %endif
	push	edi
    %endif
	push	esi
  %endif
	push	edx
  %endif
	push	ecx
 %endif
	push	ebx
%endif
%endmacro

; system call macro
;
; NEVER USE THIS MACRO DIRECTLY!
;
; %1	syscall name
; %2	number of syscall parameters
; %3	number of registers to prepare
; %4...	parameters

%macro	__syscall 2-9

%if %0>2
%if %3>0
 %if %3>1
  %if %3>2
   %if %3>3
    %if %3>4
     %if %3>5
	_mov	ebp,%9
     %endif
	_mov	edi,%8
    %endif
	_mov	esi,%7
   %endif
	_mov	edx,%6
  %endif
	_mov	ecx,%5
 %endif
	_mov	ebx,%4
%endif
%if %3 < %2
%assign __ARGS %2
%else
%assign __ARGS %3
%endif
%else
%assign __ARGS %2
%endif

%if	__SYSCALL__=__S_KERNEL__

	_mov	eax,SYS_%{1}

%ifdef __LINUX__
	DO_SYSCALL
%elifdef __ATHEOS__
	DO_SYSCALL
%elifdef __V2OS__
	DO_SYSCALL
%else		;__BSD__ & other
;Note:
;BSD related part is optimized for size by moving all 'push'es and
;add 'esp, N' to __syscall_gate. However this could cause problems
;with syscalls with more than 6 args, fortunately there are no such
;monsters yet :)

;%if	__OPTIMIZE__=__O_SPEED__
;	__push_syscall_args __ARGS
;%endif
	call	__syscall_gate	;defined in os_osname.inc
;%if	__OPTIMIZE__=__O_SPEED__
;%if __ARGS > 0
;	add	esp,byte (__ARGS) * 4
;%endif
;%endif

;	push	eax		;older convention
;	call	7:0		;
;	add	esp,byte (%{2} + 1) * 4
%endif	;__BSD__

%elif	__SYSCALL__=__S_LIBC__

;	pusha	;preserve all registers
	__push_syscall_args __ARGS
extern %{1}
	call	%{1}
%if __ARGS > 0
	add	esp,byte (__ARGS) * 4
%endif
;	mov	[esp + 4*7],eax
;	popa	;restore all registers

%else	; unknown syscall convention

	hlt

%endif	;__SYSCALL__

%endmacro

;--------------------------------------------------------------------------
;				System Calls
;--------------------------------------------------------------------------

;
;Fake "generic" syscall
;

%define SYS_eax	eax

%macro sys_generic 0-6
	__syscall eax, 6, %0, %1, %2, %3, %4, %5, %6
%endmacro

;
;unistd.h
;

%macro sys_fork 0-1
	__syscall fork, 1, %0, %1
%endmacro

%macro sys_vfork 0-1
	__syscall vfork, 1, %0, %1
%endmacro

%macro sys_execve 0-3
	__syscall execve, 3, %0, %1, %2, %3
%endmacro

%macro sys_pause 0
	__syscall pause, 0
%endmacro

%macro sys_pipe 0-1
	__syscall pipe, 1, %0, %1
%endmacro

%ifndef __OS_SYSCALL_GETDENTS__
%macro sys_getdents 0-3
	__syscall getdents, 3, %0, %1, %2, %3
%endmacro
%endif

%macro sys_getcwd 0-2
	__syscall getcwd, 2, %0, %1, %2
%endmacro

%macro sys_read 0-3
	__syscall read, 3, %0, %1, %2, %3
%endmacro

%macro sys_write 0-3
	__syscall write, 3, %0, %1, %2, %3
%endmacro

%ifndef __OS_SYSCALL_LSEEK__
%macro sys_lseek 0-3
	__syscall lseek, 3, %0, %1, %2, %3
%endmacro
%endif

%macro sys_pread 0-4
	__syscall pread, 4, %0, %1, %2, %3, %4
%endmacro

%macro sys_pwrite 0-4
	__syscall pwrite, 4, %0, %1, %2, %3, %4
%endmacro

%macro sys_chroot 0-1
	__syscall chroot, 1, %0, %1
%endmacro

%macro sys_chmod 0-2
	__syscall chmod, 2, %0, %1, %2
%endmacro

%macro sys_fchmod 0-2
	__syscall fchmod, 2, %0, %1, %2
%endmacro

%macro sys_access 0-2
	__syscall access, 2, %0, %1, %2
%endmacro

%macro sys_ftruncate 0-2
	__syscall ftruncate, 2, %0, %1, %2
%endmacro

%macro sys_chown 0-3
	__syscall chown, 3, %0, %1, %2, %3
%endmacro

%macro sys_lchown 0-3
	__syscall lchown, 3, %0, %1, %2, %3
%endmacro

%macro sys_chdir 0-1
	__syscall chdir, 1, %0, %1
%endmacro

%macro sys_open 0-3
	__syscall open, 3, %0, %1, %2, %3
%endmacro

%macro sys_close 0-1
	__syscall close, 1, %0, %1
%endmacro

%macro sys_select 0-5
	__syscall select, 5, %0, %1, %2, %3, %4, %5
%endmacro

%macro sys_poll 0-3
	__syscall poll, 3, %0, %1, %2, %3
%endmacro

%macro sys_sync 0
	__syscall sync, 0
%endmacro

%macro sys_fcntl 0-3
    __syscall fcntl, 3, %0, %1, %2, %3
%endmacro

%macro sys_dup 0-1
	__syscall dup, 1, %0, %1, %2
%endmacro

%macro sys_dup2 0-2
	__syscall dup2, 2, %0, %1, %2
%endmacro

%macro sys_mknod 0-3
	__syscall mknod, 3, %0, %1, %2, %3
%endmacro

%macro sys_mkdir 0-2
	__syscall mkdir, 2, %0, %1, %2
%endmacro

%macro sys_rmdir 0-1
	__syscall rmdir, 1, %0, %1
%endmacro

%macro sys_link 0-2
	__syscall link, 2, %0, %1, %2
%endmacro

%macro sys_symlink 0-2
	__syscall symlink, 2, %0, %1, %2
%endmacro

%macro sys_unlink 0-1
	__syscall unlink, 1, %0, %1
%endmacro

%macro sys_rename 0-2
	__syscall rename, 2, %0, %1, %2
%endmacro

%macro sys_readlink 0-3
	__syscall readlink, 3, %0, %1, %2, %3
%endmacro

%macro sys_stat 0-2
	__syscall stat, 2, %0, %1, %2
%endmacro

%macro sys_fstat 0-2
	__syscall fstat, 2, %0, %1, %2
%endmacro

%macro sys_lstat 0-2
	__syscall lstat, 2, %0, %1, %2
%endmacro

%macro sys_alarm 0-1
	__syscall alarm, 1, %0, %1
%endmacro

%macro sys_setsid 0
	__syscall setsid, 0
%endmacro

%macro sys_getuid 0
	__syscall getuid, 0
%endmacro

%macro sys_getgid 0
	__syscall getgid, 0
%endmacro

%macro sys_nice 0-1
	__syscall nice, 1, %0, %1
%endmacro

%macro sys_sethostname 0-2
	__syscall sethostname, 2, %0, %1, %2
%endmacro

%macro sys_setdomainname 0-2
	__syscall setdomainname, 2, %0, %1, %2
%endmacro

%macro sys_gethostname 0-2
	__syscall gethostname, 2, %0, %1, %2
%endmacro

%macro sys_getdomainname 0-2
	__syscall getdomainname, 2, %0, %1, %2
%endmacro

%macro sys_getpid 0
	__syscall getpid, 0
%endmacro

%macro sys_setuid 0-1
	__syscall setuid, 1, %0, %1
%endmacro

%macro sys_setpgid 0-2
	__syscall setpgid, 2, %0, %1, %2
%endmacro

%macro sys_setreuid 0-2
	__syscall setreuid, 2, %0, %1, %2
%endmacro

%macro sys_setregid 0-2
	__syscall setregid, 2, %0, %1, %2
%endmacro

%macro sys_getpgid 0-1
	__syscall setpgid, 1, %0, %1
%endmacro

%macro sys_getgroups 0-2
	__syscall getgroups, 2, %0, %1, %2
%endmacro

%macro sys_umask 0-1
        __syscall umask, 1, %0
%endmacro

%macro sys_brk	0-1
	__syscall brk, 1, %0, %1
%endmacro

%macro sys_exit 0-1
	__syscall exit, 1, %0, %1
%endmacro

%macro sys_exit_true 0
	sys_exit 0
%endmacro

%macro sys_exit_false 0
	sys_exit 1
%endmacro

;
;sys/ptrace.h
;

%macro sys_ptrace 0-4
	__syscall ptrace, 4, %0, %1, %2, %3, %4
%endmacro

;
;signal.h
;

%macro sys_kill 0-2
	__syscall kill, 2, %0, %1, %2
%endmacro

%macro sys_signal 0-2
	__syscall signal, 2, %0, %1, %2
%endmacro

%macro sys_sigaction 0-3
	__syscall sigaction, 3, %0, %1, %2, %3
%endmacro

%macro sys_sigaltstack 0-2
	__syscall sigaltstack, 2, %0, %1, %2
%endmacro

%macro sys_sigreturn 0-1
	__syscall sigreturn, 1 %0, %1
%endmacro

%macro sys_sigsuspend 0-3
	__syscall sigsuspend, 3, %0, %1, %2, %3
%endmacro

;
;sys/utsname.h
;

%macro sys_uname 0-1
	__syscall uname, 1, %0, %1
%endmacro

;
;sys/uio.h
;

%macro sys_readv  0-3
	__syscall readv, 3, %0, %1, %2, %3
%endmacro

%macro sys_writev  0-3
	__syscall writev, 3, %0, %1, %2, %3
%endmacro

;
;sys/vfs.h
;

%macro sys_statfs 0-2
	__syscall statfs, 2, %0, %1, %2
%endmacro

;
;time.h
;

%macro sys_nanosleep 0-2
	__syscall nanosleep, 2, %0, %1, %2
%endmacro

%macro sys_time 0-1
	__syscall time, 1, %0, %1
%endmacro

;
;utime.h
;

%macro sys_utime 0-2
	__syscall utime, 2, %0, %1, %2
%endmacro

%macro sys_utimes 0-2
	__syscall utimes, 2, %0, %1, %2
%endmacro

;
;sys/mount.h
;

%macro sys_mount 0-5
	__syscall mount, 5, %0, %1, %2, %3, %4, %5
%endmacro

%macro sys_umount 0-1
	__syscall umount, 1, %0, %1
%endmacro

;
;sys/ioctl.h
;

%macro sys_ioctl 0-3
	__syscall ioctl, 3, %0, %1, %2, %3
%endmacro

;
;sys/time.h
;

%macro sys_getpriority 0-2
	__syscall getpriority, 2, %0, %1, %2
%endmacro

%macro sys_setpriority 0-3
	__syscall setpriority, 3, %0, %1, %2, %3
%endmacro

%macro sys_gettimeofday 0-2
	__syscall gettimeofday, 2, %0, %1, %2
%endmacro

%macro sys_getitimer 0-2
	__syscall getitimer, 2, %0, %1, %2
%endmacro

%macro sys_setitimer 0-3
	__syscall setitimer, 3, %0, %1, %2, %3
%endmacro

;
;sys/wait.h
;

%macro sys_wait4 0-4
	__syscall wait4, 2, %0, %1, %2, %3, %4
%endmacro

;
;sys/mman.h
;

%macro sys_munmap 0-2
	__syscall munmap, 2, %0, %1, %2
%endmacro

%macro sys_mprotect 0-3
	__syscall mprotect, 3, %0, %1, %2, %3
%endmacro

;
;sys/sendfile.h
;

%macro sys_sendfile 0-4
	__syscall sendfile, 4, %0, %1, %2, %3, %4
%endmacro

;--------------------------------------------------------------------------
;possible OS specific syscalls
;--------------------------------------------------------------------------

;
;sys/reboot.h
;

%ifndef __OS_SYSCALL_REBOOT__
%macro sys_reboot 0-1
	__syscall reboot, 1, %0, %1
%endmacro
%endif

;
;sys/socket.h
;

%ifndef __OS_SYSCALL_NETWORK__

%macro	sys_socket 0-3
	__syscall socket, 3, %0, %1, %2, %3
%endmacro

%macro	sys_accept 0-3
	__syscall accept, 3, %0, %1, %2, %3
%endmacro

%macro	sys_connect 0-3
	__syscall connect, 3, %0, %1, %2, %3
%endmacro

%macro	sys_bind 0-3
	__syscall bind, 3, %0, %1, %2, %3
%endmacro

%macro	sys_setsockopt 0-5
	__syscall setsockopt, 5, %0, %1, %2, %3, %4, %5
%endmacro

%macro	sys_getsockopt 0-5
	__syscall getsockopt, 5, %0, %1, %2, %3, %4, %5
%endmacro

%macro	sys_getsockname 0-3
	__syscall getsockname, 3, %0, %1, %2, %3
%endmacro

%macro	sys_shutdown 0-2
	__syscall shutdown, 2, %0, %1, %2
%endmacro

%macro	sys_listen 0-2
	__syscall listen, 2, %0, %1, %2
%endmacro

%macro	sys_send 0-4
	__syscall send, 6, %0, %1, %2, %3, %4
%endmacro

%macro	sys_recv 0-4
	__syscall recv, 6, %0, %1, %2, %3, %4
%endmacro

%macro	sys_sendto 0-6
	__syscall sendto, 6, %0, %1, %2, %3, %4, %5, %6
%endmacro

%macro	sys_recvfrom 0-6
	__syscall recvfrom, 6, %0, %1, %2, %3, %4, %5, %6
%endmacro

%macro	sys_sendmsg 0-3
	__syscall sendmsg, 6, %0, %1, %2, %3
%endmacro

%macro	sys_recvmsg 0-3
	__syscall recvmsg, 6, %0, %1, %2, %3
%endmacro

%endif	;__OS_SYSCALL_NETWORK__

;
;sys/mman.h
;

%ifndef __OS_SYSCALL_MMAP__
%macro	sys_mmap 0-6
	__syscall mmap, 6, %0, %1, %2, %3, %4, %5, %6
%endmacro
%endif

;--------------------------------------------------------------------------

%endif
