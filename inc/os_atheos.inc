; Copyright (C) 2000-2001 Konstantin Boldyshev <konst@linuxassembly.org>
;
; $Id: os_atheos.inc,v 1.5 2002/03/14 17:40:13 konst Exp $
;
; file          : os_atheos.inc
; created       : 23-Oct-2000
; modified      : 14-Mar-2002
; version       : 0.17
; assembler     : nasm 0.98
; description   : atheos kernel constants
; author        : Konstantin Boldyshev <konst@linuxassembly.org>
; comment       : included from system.inc

%ifndef __SYSTEM_INC
%error "this file must be included from system.inc !"
%endif

%ifndef __ATHEOS_INC
%define __ATHEOS_INC

%macro	DO_SYSCALL 0
	int	0x80
%endmacro

%macro	SYSCALL_GATE 0
%endmacro

;
;
;

%assign	SYS_idle			0
%assign	SYS_open			1
%assign	SYS_close			2
%assign	SYS_read			3
%assign	SYS_write			4
%assign	SYS_Fork			5
%assign	SYS_exit			6
%assign	SYS_rename			7
%assign	SYS_getdents			8
%assign	SYS_alarm			9
%assign	SYS_wait4			10
%assign	SYS_fstat			11
%assign	SYS_FileLength			12
%assign	SYS_Seek			13
%assign	SYS_mkdir			14
%assign	SYS_rmdir			15
%assign	SYS_dup			16
%assign	SYS_dup2			17
%assign	SYS_fchdir			18
%assign	SYS_chdir			19
%assign	SYS_unlink			20
%assign	SYS_rewinddir			21
%assign	SYS_get_thread_info		22
%assign	SYS_get_thread_proc		23
%assign	SYS_get_next_thread		24
%assign	SYS_get_thread_id		25
%assign	SYS_send_data			26
%assign	SYS_receive_data		27
%assign	SYS_thread_data_size		28
%assign	SYS_has_data			29
%assign	SYS_SetThreadExitCode		30
%assign	SYS_old_spawn_thread		31
%assign	SYS_spawn_thread		32
%assign	SYS_get_raw_system_time	33
%assign	SYS_get_raw_real_time		34
%assign	SYS_get_raw_idle_time		35
%assign	SYS_umask			36
%assign	SYS_mknod			37
%assign	SYS_reboot			38
%assign	SYS_GetToken			39
;%assign	SYS_FlushCaches		40
%assign	SYS_utime			41
%assign	SYS_select			42
%assign	SYS_exit_thread		43
%assign	SYS_initialize_fs		44
%assign	SYS_DebugPrint			45
%assign	SYS_realint			46
%assign	SYS_get_system_path		47
%assign	SYS_get_app_server_port	48
;%assign	SYS_MemClear			49
%assign	SYS_mount			50
%assign	SYS_unmount			51
%assign	SYS_create_area		52
%assign	SYS_remap_area			53
%assign	SYS_get_area_info		54
%assign	SYS_sbrk			55
%assign	SYS_get_vesa_info		56
%assign	SYS_get_vesa_mode_info		57
%assign	SYS_new_waitpid_mode		58
%assign	SYS_create_port		59
%assign	SYS_delete_port		60
%assign	SYS_send_msg			61
%assign	SYS_get_msg			62
%assign	SYS_raw_send_msg_x		63
%assign	SYS_raw_get_msg_x		64
%assign	SYS_debug_write		65
%assign	SYS_debug_read			66
%assign	SYS_get_system_info		67
%assign	SYS_create_semaphore		68
%assign	SYS_delete_semaphore		69
%assign	SYS_lock_semaphore		70
%assign	SYS_raw_lock_semaphore_x	71
%assign	SYS_unlock_semaphore_x		72
%assign	SYS_get_semaphore_info		73
%assign	SYS_clone_area			74
%assign	SYS_execve			75
%assign	SYS_delete_area		76
%assign	SYS_chmod			77
%assign	SYS_fchmod			78
%assign	SYS_GetTime			79
%assign	SYS_SetTime			80
%assign	SYS_old_load_library		81
%assign	SYS_unload_library		82
%assign	SYS_load_library		83
%assign	SYS_get_symbol_address		84
%assign	SYS_chown			85
%assign	SYS_fchown			86
%assign	SYS_raw_read_pci_config	87
%assign	SYS_raw_write_pci_config	88
%assign	SYS_get_pci_info			89
%assign	SYS_signal			90
%assign	SYS_sig_return			91
%assign	SYS_kill			92
%assign	SYS_sigaction			93
%assign	SYS_sigaddset			94
%assign	SYS_sigdelset			95
%assign	SYS_sigemptyset		96
%assign	SYS_sigfillset			97
%assign	SYS_sigismember		98
%assign	SYS_sigpending			99
%assign	SYS_sigprocmask		100
%assign	SYS_sigsuspend			101
;%assign	SYS_Delay			102
%assign	SYS_set_thread_priority	103
%assign	SYS_suspend_thread		104
%assign	SYS_resume_thread		105
%assign	SYS_wait_for_thread		106
%assign	SYS_snooze			107
;%assign	SYS_Permit			108
%assign	SYS_killpg			109
%assign	SYS_kill_proc			110
%assign	SYS_get_process_id		111
%assign	SYS_sync			112
%assign	SYS_fsync_bad			113
%assign	SYS_isatty			114
%assign	SYS_fcntl			115
%assign SYS_ioctl			116
%assign SYS_pipe			117
%assign SYS_access			118
%assign SYS_set_strace_level		119
%assign	SYS_symlink			120
%assign	SYS_readlink			121
%assign	SYS_call_v86			122
%assign	SYS_stat			123
%assign	SYS_lstat			124
%assign	SYS_setpgid			125
%assign	SYS_getpgid			126
%assign	SYS_getpgrp			127
%assign SYS_getppid			128
%assign	SYS_getsid			129
%assign	SYS_setsid			130
%assign	SYS_getegid			131
%assign	SYS_geteuid			132
%assign	SYS_getgid			133
%assign	SYS_getgroups			134
%assign	SYS_getuid			135
%assign	SYS_setgid			136
%assign	SYS_setuid			137
%assign	SYS_set_app_server_port	138
%assign	SYS_rename_thread		139
;%assign	SYS_get_image_destructor_count		140
;%assign	SYS_get_image_constructors		141
;%assign	SYS_get_image_destructors		142
%assign	SYS_open_attrdir			143
%assign	SYS_close_attrdir			144
%assign	SYS_rewind_attrdir			145
%assign	SYS_read_attrdir			146
%assign	SYS_remove_attr			147
%assign SYS_rename_attr			148
%assign	SYS_stat_attr				149
%assign	SYS_write_attr				150
%assign	SYS_read_attr				151
%assign SYS_get_image_info			152
;%assign SYS_socket_read			153
%assign SYS_net_config				154
%assign SYS_socket				155
%assign SYS_closesocket			156
%assign SYS_bind				157
%assign SYS_sendmsg				158
%assign SYS_recvmsg				159
%assign SYS_connect				160
%assign SYS_listen				161
%assign SYS_accept				162
%assign SYS_setsockopt				163
%assign SYS_getsockopt				164
%assign SYS_getpeername			165
%assign SYS_shutdown				166
%assign SYS_config_net_dev			167
%assign SYS_getsockname			168
%assign SYS_setregid				169
%assign SYS_setgroups				170
%assign SYS_setreuid				171
%assign SYS_setresuid				172
%assign SYS_getresuid				173
%assign SYS_setresgid				174
%assign SYS_getresgid				175
%assign SYS_setfsuid				176
%assign SYS_setfsgid				177
%assign SYS_chroot				178
%assign SYS_open_indexdir			179
%assign SYS_rewind_indexdir			180
%assign SYS_read_indexdir			181
%assign SYS_create_index			182
%assign SYS_remove_index			183
%assign SYS_stat_index				184

;
;
;

%assign	SYS_umount		SYS_unmount
%assign SYS_nanosleep		SYS_snooze	;?? or SYS_idle?
%assign SYS_lseek		SYS_Seek
%assign SYS_fork		SYS_Fork
%assign SYS_link		SYS_symlink
%assign SYS_uname		SYS_getuid
%assign SYS_sethostname		SYS_getuid
%assign SYS_setdomainname	SYS_getuid
%assign	SYS_brk			SYS_sbrk

;
;net/socket.h
;

%assign SOL_SOCKET	1

%assign SO_DEBUG	1
%assign SO_REUSEADDR	2
%assign SO_TYPE		3
%assign SO_ERROR	4
%assign SO_DONTROUTE	5
%assign SO_BROADCAST	6
%assign SO_SNDBUF	7
%assign SO_RCVBUF	8
%assign SO_KEEPALIVE	9
%assign SO_OOBINLINE	10
%assign SO_NO_CHECK	11
%assign SO_PRIORITY	12
%assign SO_LINGER	13
%assign SO_BSDCOMPAT	14

%endif
