; Copyright (C) 2000 Konstantin Boldyshev <konst@linuxassembly.org>
;
; $Id: os_v2os.inc,v 1.2 2002/02/02 12:33:39 konst Exp $
;
; file          : os_v2os.inc
; created       : 13-Oct-2000
; modified      : 13-Oct-2000
; version       : 0.11
; assembler     : nasm 0.98
; description   : v2os kernel constants
; author        : Konstantin Boldyshev <konst@linuxassembly.org>
; comment       : included from system.inc

%ifndef __SYSTEM_INC
%error "this file must be included from system.inc !"
%endif

%ifndef __V2OS_INC
%define __V2OS_INC

%assign SYS_open		0
%assign SYS_close		1
%assign SYS_read		2
%assign SYS_write		3
%assign SYS_ioctl		4
%assign SYS_lseek		5
%assign SYS_time		7
%assign SYS_opendir		0x0c
%assign SYS_closedir		0x0f
%assign SYS_rewinddir		0x17
%assign SYS_reboot		0x18
%assign SYS_readdir		0x1c
%assign SYS_mkdir		0x1e
%assign SYS_symlink		0x1f
%assign SYS_readlink		0x23
%assign SYS_rename		0x26
%assign SYS_unlink		0x27
%assign SYS_mount		0x31
%assign SYS_exit		0x3f
%assign SYS_umount		0x40
%assign SYS_dup2		0x4a
%assign SYS_chdir		0x57
%assign SYS_access		0x58
%assign SYS_statfs		0x5f
%assign SYS_rmdir		0x60
%assign SYS_link		0x6e
%assign SYS_sync		0x6f
%assign SYS_sigaction		0x70
%assign SYS_sigpending		0x71
%assign SYS_pause		0x72
%assign SYS_sigsuspend		0x72
%assign SYS_kill		0x74
%assign SYS_stime		0x76
%assign SYS_getgid		0x77
%assign SYS_getpgrp		0x78
%assign SYS_alarm		0x79
%assign SYS_getppid		0x7a
%assign SYS_getuid		0x7b
%assign SYS_setgid		0x7c
%assign SYS_setpgid		0x7d
%assign SYS_setsid		0x7e
%assign SYS_setuid		0x7f

%assign SYS_fork		0xa1
%assign SYS_execve		0xa2
%assign SYS_waitpid		0xa3
%assign SYS_gettimeofday	0xa6

%assign SYS_readv		0xbf
%assign SYS_writev		0xc0


%endif
