; Copyright (C) 2001 Thomas M. Ogrisegg (thomas.ogrisegg@sbg.ac.at)
;
; $Id: os_unixware.inc,v 1.3 2002/02/02 13:59:59 konst Exp $
;
; file  	: os_unixware.inc
; created	: 08-Nov-2001
; modified	: 14-Nov-2001
; version	: 0.1
; assembler	: nasm
; author	: Thomas M. Ogrisegg
; comment	: included from system.inc
; license	: GNU General Public License
; release	: Alpha/Unstable
; OS		: SCO UnixWare 7.x
;
; THIS IS AN UNSTABLE VERSION! USE AT YOUR OWN RISK!
;
; This Include file defines the asmutils-macros needed to
; assemble asmutils under SCO UnixWare 7.x
;

%ifndef __SYSTEM_INC
%error "this file must be included from system.inc"
%endif

%ifndef __UNIXWARE_INC
%define __UNIXWARE_INC

%macro	DO_SYSCALL 0
	call 0x7:0x0		; Unixware uses call-gates
%endmacro

%macro SYSCALL_GATE 0
__syscall_gate:
	DO_SYSCALL
	ret
%endmacro

%assign	SYS_exit	1
%assign	SYS_fork	2
%assign	SYS_read	3
%assign	SYS_write	4
%assign	SYS_open	5
%assign	SYS_close	6
%assign	SYS_wait	7
%assign	SYS_creat	8
%assign	SYS_link	9
%assign	SYS_unlink	10
%assign	SYS_exec	11
%assign	SYS_chdir	12
%assign	SYS_time	13
%assign	SYS_mknod	14
%assign	SYS_chmod	15
%assign	SYS_chown	16
%assign	SYS_brk		17
%assign	SYS_stat	18
%assign	SYS_lseek	19
%assign	SYS_getpid	20
%assign	SYS_mount	21
%assign	SYS_umount	22
%assign	SYS_setuid	23
%assign	SYS_getuid	24
%assign	SYS_stime	25
%assign	SYS_ptrace	26
%assign	SYS_alarm	27
%assign	SYS_fstat	28
%assign	SYS_pause	29
%assign	SYS_utime	30
%assign	SYS_stty	31
%assign	SYS_gtty	32
%assign	SYS_access	33
%assign	SYS_nice	34
%assign	SYS_statfs	35
%assign	SYS_sync	36
%assign	SYS_kill	37
%assign	SYS_fstatfs	38
%assign	SYS_pgrpsys	39
%assign SYS_sysext	40
%define	SYS_xenix	SYS_sysext
%assign	SYS_dup		41
%assign	SYS_pipe	42
%assign	SYS_times	43
%assign	SYS_profil	44
%assign	SYS_plock	45
%assign	SYS_setgid	46
%assign	SYS_getgid	47
%assign	SYS_signal	48
%assign	SYS_msgsys	49
%assign	SYS_sysi86	50
%assign	SYS_acct	51
%assign	SYS_shmsys	52
%assign	SYS_semsys	53
%assign	SYS_ioctl	54
%assign	SYS_uadmin	55
%assign	SYS_utssys	57
%assign	SYS_fsync	58
%assign	SYS_execve	59
%assign	SYS_umask	60
%assign	SYS_chroot	61
%assign	SYS_fcntl	62
%assign	SYS_ulimit	63
%assign SYS_cg_ids	64
%assign SYS_cg_processors 65
%assign SYS_cg_info	66
%assign SYS_cg_bind	67
%assign SYS_cg_current	68
%assign SYS_cg_memloc	69
%assign	SYS_rfsys	78
%assign	SYS_rmdir	79
%assign	SYS_mkdir	80
%assign	SYS_getdents	81
%assign	SYS_sysfs	84
%assign	SYS_getmsg	85
%assign	SYS_putmsg	86
%assign	SYS_poll	87
%assign	SYS_lstat	88
%assign	SYS_symlink	89
%assign	SYS_readlink	90
%assign	SYS_setgroups	91
%assign	SYS_getgroups	92
%assign	SYS_fchmod	93
%assign	SYS_fchown	94
%assign	SYS_sigprocmask	95
%assign	SYS_sigsuspend	96
%assign	SYS_sigaltstack	97
%assign	SYS_sigaction	98
%assign	SYS_sigpending	99
%assign	SYS_context	100
%assign	SYS_evsys	101
%assign	SYS_evtrapret	102
%assign	SYS_statvfs	103
%assign	SYS_fstatvfs	104
%assign	SYS_nfssys	106
%assign	SYS_waitsys	107
%assign	SYS_sigsendsys	108
%assign	SYS_hrtsys	109
%assign	SYS_acancel	110
%assign	SYS_async	111
%assign	SYS_priocntlsys	112
%assign	SYS_pathconf	113
%assign	SYS_mincore	114
%assign	SYS_mmap	115
%assign	SYS_mprotect	116
%assign	SYS_munmap	117
%assign	SYS_fpathconf	118
%assign	SYS_vfork	119
%assign	SYS_fchdir	120
%assign	SYS_readv	121
%assign	SYS_writev	122
%assign	SYS_xstat	123
%assign	SYS_lxstat	124
%assign	SYS_fxstat	125
%assign	SYS_xmknod	126
%assign	SYS_clocal	127
%assign	SYS_setrlimit	128
%assign	SYS_getrlimit	129
%assign	SYS_lchown	130
%assign	SYS_memcntl	131
%assign	SYS_getpmsg	132
%assign	SYS_putpmsg	133
%assign	SYS_rename	134
%assign	SYS_uname	135
%assign	SYS_setegid	136
%assign	SYS_sysconfig	137
%assign	SYS_adjtime	138
%assign	SYS_systeminfo	139
%assign	SYS_seteuid	141
%assign	SYS_keyctl	143
%assign	SYS_secsys	144
%assign SYS_filepriv	145
%assign SYS_procpriv	146
%assign SYS_devstat	147
%assign SYS_aclipc	148
%assign SYS_fdevstat	149
%assign SYS_flvlfile	150
%assign SYS_lvlfile	151
%assign SYS_sendv	152
%assign SYS_lvlequal	153
%assign SYS_lvlproc	154
%assign SYS_lvlipc	156
%assign SYS_acl		157
%assign SYS_auditevt	158
%assign SYS_auditctl	159
%assign SYS_auditdmp	160
%assign SYS_auditlog	161
%assign SYS_auditbuf	162
%assign SYS_lvldom	163
%assign SYS_lvlvfs	164
%assign SYS_mkmld	165
%assign SYS_mldmode	166
%assign SYS_secadvise	167
%assign	SYS_online	168
%assign	SYS_setitimer	169
%assign	SYS_getitimer	170
%assign	SYS_gettimeofday 171
%assign	SYS_settimeofday 172
%assign SYS_lwpcreate	173
%assign SYS_lwpexit	174
%assign SYS_lwpwait	175
%assign SYS_lwpself	176
%assign SYS_lwpinfo	177
%assign SYS_lwpprivate	178
%assign	SYS_processor_bind	179
%assign	SYS_processor_exbind	180
%assign	SYS_sendv64		182
%assign	SYS_prepblock		183
%assign	SYS_block		184
%assign	SYS_rdblock		185
%assign	SYS_unblock		186
%assign	SYS_cancelblock		187
%assign SYS_pread	189
%assign SYS_pwrite	190
%assign SYS_truncate	191
%assign SYS_ftruncate	192
%assign SYS_lwpkill	193
%assign SYS_sigwait	194
%assign SYS_fork1	195
%assign SYS_forkall	196
%assign SYS_modload	197
%assign SYS_moduload	198
%assign SYS_modpath	199
%assign SYS_modstat	200
%assign SYS_modadm	201
%assign SYS_getksym	202
%assign SYS_lwpsuspend	203
%assign SYS_lwpcontinue	204
%assign SYS_priocntllst	205
%assign SYS_sleep	206
%assign SYS_lwp_sema_wait	207
%assign SYS_lwp_sema_post	208
%assign SYS_lwp_sema_trywait	209
%assign SYS_fstatvfs64		216
%assign SYS_statvfs64		217
%assign SYS_ftruncate64		218
%assign SYS_truncate64		219
%assign SYS_getrlimit64		220
%assign SYS_setrlimit64		221
%assign SYS_lseek64		222
%assign SYS_mmap64		223
%assign SYS_pread64		224
%assign SYS_pwrite64		225
%assign SYS_creat64		226
%assign SYS_dshmsys		227
%assign SYS_invlpg		228

; Special SCO systemcalls

%assign SYS_rfork1              229
%assign SYS_rforkall            230
%assign SYS_rexecve             231
%assign SYS_migrate             232
%assign SYS_kill3               233
%assign SYS_ssisys              234

; Socket systemcalls

%assign SYS_xaccept		235
%assign SYS_xbind		236
%assign SYS_xbindresvport	237
%assign SYS_xconnect		238
%assign SYS_xgetsockaddr	239
%assign SYS_xgetsockopt		240
%assign SYS_xlisten		241
%assign SYS_xrecvmsg		242
%assign SYS_xsendmsg		243
%assign SYS_xsetsockaddr	244
%assign SYS_xsetsockopt		245
%assign SYS_xshutdown		246
%assign SYS_xsocket		247
%assign SYS_xsocketpair		248

%endif	;_UNIXWARE_INC
