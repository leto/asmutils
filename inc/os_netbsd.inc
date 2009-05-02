; Copyright (C) 2000-2002 Konstantin Boldyshev <konst@linuxassembly.org>
;
; $Id: os_netbsd.inc,v 1.8 2002/03/14 17:40:13 konst Exp $
;
; file          : os_netbsd.inc
; created       : 10-Aug-2000
; modified      : 14-Mar-2002
; version       : 0.17
; assembler     : nasm 0.98
; description   : NetBSD kernel (1.4+) constants and structures
; author        : Konstantin Boldyshev <konst@linuxassembly.org>
; comment       : included from system.inc

%ifndef __SYSTEM_INC
%error "this file must be included from system.inc !"
%endif

%ifndef __NETBSD_INC
%define __NETBSD_INC

;
;sys/syscall.h
;
;see sys/syscall.h and sys/syscallargs.h to find out arguments for each syscall
;$NetBSD: syscall.h,v 1.118.2.5 2001/11/17 01:15:18 nathanw Exp $
;created from	NetBSD: syscalls.master,v 1.108.2.4 2001/11/17 01:10:17 nathanw Exp 

%assign	SYS_syscall	0
%assign	SYS_exit	1
%assign	SYS_fork	2
%assign	SYS_read	3
%assign	SYS_write	4
%assign	SYS_open	5
%assign	SYS_close	6
%assign	SYS_wait4	7
%assign	SYS_compat_43_ocreat	8
%assign	SYS_link	9
%assign	SYS_unlink	10
;				/* 11 is obsolete execv */
%assign	SYS_chdir	12
%assign	SYS_fchdir	13
%assign	SYS_mknod	14
%assign	SYS_chmod	15
%assign	SYS_chown	16
%assign	SYS_break	17
%assign	SYS_getfsstat	18
%assign	SYS_compat_43_olseek	19
%assign	SYS_getpid	20
%assign	SYS_mount	21
%assign	SYS_unmount	22
%assign	SYS_setuid	23
%assign	SYS_getuid	24
%assign	SYS_geteuid	25
%assign	SYS_ptrace	26
%assign	SYS_recvmsg	27
%assign	SYS_sendmsg	28
%assign	SYS_recvfrom	29
%assign	SYS_accept	30
%assign	SYS_getpeername	31
%assign	SYS_getsockname	32
%assign	SYS_access	33
%assign	SYS_chflags	34
%assign	SYS_fchflags	35
%assign	SYS_sync	36
%assign	SYS_kill	37
%assign	SYS_compat_43_stat43	38
%assign	SYS_getppid	39
%assign	SYS_compat_43_lstat43	40
%assign	SYS_dup	41
%assign	SYS_pipe	42
%assign	SYS_getegid	43
%assign	SYS_profil	44
%assign	SYS_ktrace	45
%assign	SYS_compat_13_sigaction13	46
%assign	SYS_getgid	47
%assign	SYS_compat_13_sigprocmask13	48
%assign	SYS___getlogin	49
%assign	SYS_setlogin	50
%assign	SYS_acct	51
%assign	SYS_compat_13_sigpending13	52
%assign	SYS_compat_13_sigaltstack13	53
%assign	SYS_ioctl	54
%assign	SYS_compat_12_oreboot	55
%assign	SYS_revoke	56
%assign	SYS_symlink	57
%assign	SYS_readlink	58
%assign	SYS_execve	59
%assign	SYS_umask	60
%assign	SYS_chroot	61
%assign	SYS_compat_43_fstat43	62
%assign	SYS_compat_43_ogetkerninfo	63
%assign	SYS_compat_43_ogetpagesize	64
%assign	SYS_compat_12_msync	65
%assign	SYS_vfork	66
;				/* 67 is obsolete vread */
;				/* 68 is obsolete vwrite */
%assign	SYS_sbrk	69
%assign	SYS_sstk	70
%assign	SYS_compat_43_ommap	71
%assign	SYS_vadvise	72
%assign	SYS_munmap	73
%assign	SYS_mprotect	74
%assign	SYS_madvise	75
;				/* 76 is obsolete vhangup */
;				/* 77 is obsolete vlimit */
%assign	SYS_mincore	78
%assign	SYS_getgroups	79
%assign	SYS_setgroups	80
%assign	SYS_getpgrp	81
%assign	SYS_setpgid	82
%assign	SYS_setitimer	83
%assign	SYS_compat_43_owait	84
%assign	SYS_compat_12_oswapon	85
%assign	SYS_getitimer	86
%assign	SYS_compat_43_ogethostname	87
%assign	SYS_compat_43_osethostname	88
%assign	SYS_compat_43_ogetdtablesize	89
%assign	SYS_dup2	90
%assign	SYS_fcntl	92
%assign	SYS_select	93
%assign	SYS_fsync	95
%assign	SYS_setpriority	96
%assign	SYS_socket	97
%assign	SYS_connect	98
%assign	SYS_compat_43_oaccept	99
%assign	SYS_getpriority	100
%assign	SYS_compat_43_osend	101
%assign	SYS_compat_43_orecv	102
%assign	SYS_compat_13_sigreturn13	103
%assign	SYS_bind	104
%assign	SYS_setsockopt	105
%assign	SYS_listen	106
;				/* 107 is obsolete vtimes */
%assign	SYS_compat_43_osigvec	108
%assign	SYS_compat_43_osigblock	109
%assign	SYS_compat_43_osigsetmask	110
%assign	SYS_compat_13_sigsuspend13	111
%assign	SYS_compat_43_osigstack	112
%assign	SYS_compat_43_orecvmsg	113
%assign	SYS_compat_43_osendmsg	114
;				/* 115 is obsolete vtrace */
%assign	SYS_gettimeofday	116
%assign	SYS_getrusage	117
%assign	SYS_getsockopt	118
;				/* 119 is obsolete resuba */
%assign	SYS_readv	120
%assign	SYS_writev	121
%assign	SYS_settimeofday	122
%assign	SYS_fchown	123
%assign	SYS_fchmod	124
%assign	SYS_compat_43_orecvfrom	125
%assign	SYS_setreuid	126
%assign	SYS_setregid	127
%assign	SYS_rename	128
%assign	SYS_compat_43_otruncate	129
%assign	SYS_compat_43_oftruncate	130
%assign	SYS_flock	131
%assign	SYS_mkfifo	132
%assign	SYS_sendto	133
%assign	SYS_shutdown	134
%assign	SYS_socketpair	135
%assign	SYS_mkdir	136
%assign	SYS_rmdir	137
%assign	SYS_utimes	138
;				/* 139 is obsolete 4.2 sigreturn */
%assign	SYS_adjtime	140
%assign	SYS_compat_43_ogetpeername	141
%assign	SYS_compat_43_ogethostid	142
%assign	SYS_compat_43_osethostid	143
%assign	SYS_compat_43_ogetrlimit	144
%assign	SYS_compat_43_osetrlimit	145
%assign	SYS_compat_43_okillpg	146
%assign	SYS_setsid	147
%assign	SYS_quotactl	148
%assign	SYS_compat_43_oquota	149
%assign	SYS_compat_43_ogetsockname	150
%assign	SYS_nfssvc	155
%assign	SYS_compat_43_ogetdirentries	156
%assign	SYS_statfs	157
%assign	SYS_fstatfs	158
%assign	SYS_getfh	161
%assign	SYS_compat_09_ogetdomainname	162
%assign	SYS_compat_09_osetdomainname	163
%assign	SYS_compat_09_ouname	164
%assign	SYS_sysarch	165
%assign	SYS_compat_10_osemsys	169
%assign	SYS_compat_10_omsgsys	170
%assign	SYS_compat_10_oshmsys	171
%assign	SYS_pread	173
%assign	SYS_pwrite	174
%assign	SYS_ntp_gettime	175
%assign	SYS_ntp_adjtime	176
%assign	SYS_setgid	181
%assign	SYS_setegid	182
%assign	SYS_seteuid	183
%assign	SYS_lfs_bmapv	184
%assign	SYS_lfs_markv	185
%assign	SYS_lfs_segclean	186
%assign	SYS_lfs_segwait	187
%assign	SYS_compat_12_stat12	188
%assign	SYS_compat_12_fstat12	189
%assign	SYS_compat_12_lstat12	190
%assign	SYS_pathconf	191
%assign	SYS_fpathconf	192
%assign	SYS_getrlimit	194
%assign	SYS_setrlimit	195
%assign	SYS_compat_12_getdirentries	196
%assign	SYS_mmap	197
%assign	SYS___syscall	198
%assign	SYS_lseek	199
%assign	SYS_truncate	200
%assign	SYS_ftruncate	201
%assign	SYS___sysctl	202
%assign	SYS_mlock	203
%assign	SYS_munlock	204
%assign	SYS_undelete	205
%assign	SYS_futimes	206
%assign	SYS_getpgid	207
%assign	SYS_reboot	208
%assign	SYS_poll	209
;				/* 210-219 are excluded lkmnosys */
%assign	SYS_compat_14___semctl	220
%assign	SYS_semget	221
%assign	SYS_semop	222
%assign	SYS_semconfig	223
%assign	SYS_compat_14_msgctl	224
%assign	SYS_msgget	225
%assign	SYS_msgsnd	226
%assign	SYS_msgrcv	227
%assign	SYS_shmat	228
%assign	SYS_compat_14_shmctl	229
%assign	SYS_shmdt	230
%assign	SYS_shmget	231
%assign	SYS_clock_gettime	232
%assign	SYS_clock_settime	233
%assign	SYS_clock_getres	234
%assign	SYS_timer_create	235
%assign	SYS_timer_delete	236
%assign	SYS_timer_settime	237
%assign	SYS_timer_gettime	238
%assign	SYS_timer_getoverrun	239
%assign	SYS_nanosleep	240
%assign	SYS_fdatasync	241
%assign	SYS_mlockall	242
%assign	SYS_munlockall	243
%assign	SYS___posix_rename	270
%assign	SYS_swapctl	271
%assign	SYS_getdents	272
%assign	SYS_minherit	273
%assign	SYS_lchmod	274
%assign	SYS_lchown	275
%assign	SYS_lutimes	276
%assign	SYS___msync13	277
%assign	SYS___stat13	278
%assign	SYS___fstat13	279
%assign	SYS___lstat13	280
%assign	SYS___sigaltstack14	281
%assign	SYS___vfork14	282
%assign	SYS___posix_chown	283
%assign	SYS___posix_fchown	284
%assign	SYS___posix_lchown	285
%assign	SYS_getsid	286
%assign	SYS___clone	287
%assign	SYS_fktrace	288
%assign	SYS_preadv	289
%assign	SYS_pwritev	290
%assign	SYS___sigaction14	291
%assign	SYS___sigpending14	292
%assign	SYS___sigprocmask14	293
%assign	SYS___sigsuspend14	294
%assign	SYS___sigreturn14	295
%assign	SYS___getcwd	296
%assign	SYS_fchroot	297
%assign	SYS_fhopen	298
%assign	SYS_fhstat	299
%assign	SYS_fhstatfs	300
%assign	SYS_____semctl13	301
%assign	SYS___msgctl13	302
%assign	SYS___shmctl13	303
%assign	SYS_lchflags	304
%assign	SYS_issetugid	305
%assign	SYS_utrace	306
%assign	SYS_getcontext	307
%assign	SYS_setcontext	308
%assign	SYS__lwp_create	309
%assign	SYS__lwp_exit	310
%assign	SYS__lwp_self	311
%assign	SYS__lwp_wait	312
%assign	SYS__lwp_suspend	313
%assign	SYS__lwp_continue	314
%assign	SYS_sa_register	330
%assign	SYS_sa_stacks	331
%assign	SYS_sa_enable	332
%assign	SYS_sa_setconcurrency	333
%assign	SYS_sa_yield	334
%assign	SYS_sa_preempt	335
%assign	SYS_MAXSYSCALL	340
%assign	SYS_NSYSENT	512

;
;loopbacks
;

%assign	SYS_brk		SYS_break
%assign	SYS_umount	SYS_unmount
%assign	SYS_sysctl	SYS___sysctl
%assign	SYS_sigaction	SYS___sigaction14
%assign	SYS_getcwd	SYS___getcwd
%assign	SYS_uname	SYS_compat_09_ouname
%assign	SYS_stat	SYS_compat_43_stat43
%assign	SYS_lstat	SYS_compat_43_lstat43
%assign	SYS_fstat	SYS_compat_43_fstat43
%assign	SYS_sethostname	SYS_compat_43_osethostname
%assign	SYS_gethostname	SYS_compat_43_ogethostname
%assign	SYS_setdomainname	SYS_compat_09_osetdomainname
%assign	SYS_getdomainname	SYS_compat_09_ogetdomainname
%assign	SYS_getdirentries	SYS_compat_43_ogetdirentries
%assign	SYS_signal	SYS_getpid
%assign	SYS_alarm	SYS_getpid

;
;sys/sysctl.h
;
;$NetBSD: sysctl.h,v 1.70 2001/10/05 19:05:06 eeh Exp $

%assign	CTL_MAXNAME	12

struc ctlname
.ctl_name	PCHAR	1	;*char to subsystem name
.ctl_type	INT	1	;type of name
endstruc

%assign	CTLTYPE_NODE	1	;name is a node
%assign	CTLTYPE_INT	2	;name describes an integer
%assign	CTLTYPE_STRING	3	;name describes a string
%assign	CTLTYPE_QUAD	4	;name describes a 64-bit number
%assign	CTLTYPE_STRUCT	5	;name describes a structure

%assign	CTL_UNSPEC	0		;unused
%assign	CTL_KERN	1		;"high kernel": proc, limits
%assign	CTL_VM		2		;virtual memory
%assign	CTL_VFS		3		;file system, mount type is next
%assign	CTL_NET		4		;network, see socket.h
%assign	CTL_DEBUG	5		;debugging parameters
%assign	CTL_HW		6		;generic cpu/io
%assign	CTL_MACHDEP	7		;machine dependent
%assign	CTL_USER	8		;user-level
%assign	CTL_DDB		9		;in-kernel debugger
%assign	CTL_PROC	10		;per-proc attr
%assign	CTL_VENDOR	11		;vendor-specific data
%assign	CTL_MAXID	12		;number of valid top-level ids

%assign	KERN_OSTYPE	 	 1	;string: system version
%assign	KERN_OSRELEASE	 	 2	;string: system release
%assign	KERN_OSREV	 	 3	;int: system revision
%assign	KERN_VERSION	 	 4	;string: compile time info
%assign	KERN_MAXVNODES	 	 5	;int: max vnodes
%assign	KERN_MAXPROC	 	 6	;int: max processes
%assign	KERN_MAXFILES	 	 7	;int: max open files
%assign	KERN_ARGMAX	 	 8	;int: max arguments to exec
%assign	KERN_SECURELVL	 	 9	;int: system security level
%assign	KERN_HOSTNAME		10	;string: hostname
%assign	KERN_HOSTID		11	;int: host identifier
%assign	KERN_CLOCKRATE		12	;struct: struct clockrate
%assign	KERN_VNODE		13	;struct: vnode structures
%assign	KERN_PROC		14	;struct: process entries
%assign	KERN_FILE		15	;struct: file entries
%assign	KERN_PROF		16	;node: kernel profiling info
%assign	KERN_POSIX1		17	;int: POSIX.1 version
%assign	KERN_NGROUPS		18	;int: # of supplemental group ids
%assign	KERN_JOB_CONTROL	19	;int: is job control available
%assign	KERN_SAVED_IDS		20	;int: saved set-user/group-ID
%assign	KERN_BOOTTIME		21	;struct: time kernel was booted
%assign	KERN_DOMAINNAME		22	;string: (YP) domainname
%assign	KERN_MAXPARTITIONS	23	;int: number of partitions/disk
%assign	KERN_RAWPARTITION	24	;int: raw partition number
%assign	KERN_NTPTIME		25	;struct: extended-precision time
%assign	KERN_TIMEX		26	;struct: ntp timekeeping state
%assign	KERN_AUTONICETIME	27	;int: proc time before autonice
%assign	KERN_AUTONICEVAL	28	;int: auto nice value
%assign	KERN_RTC_OFFSET		29	;int: offset of rtc from gmt
%assign	KERN_ROOT_DEVICE	30	;string: root device
%assign	KERN_MSGBUFSIZE		31	;int: max # of chars in msg buffer
%assign	KERN_FSYNC		32	;int: file synchronization support
%assign	KERN_SYSVMSG		33	;int: SysV message queue suppoprt
%assign	KERN_SYSVSEM		34	;int: SysV semaphore support
%assign	KERN_SYSVSHM		35	;int: SysV shared memory support
%assign	KERN_OLDSHORTCORENAME	36	;old, unimplemented
%assign	KERN_SYNCHRONIZED_IO	37	;int: POSIX synchronized I/O
%assign	KERN_IOV_MAX		38	;int: max iovec's for readv(2) etc.
%assign	KERN_MBUF		39	;node: mbuf parameters
%assign	KERN_MAPPED_FILES	40	;int: POSIX memory mapped files
%assign	KERN_MEMLOCK		41	;int: POSIX memory locking
%assign	KERN_MEMLOCK_RANGE	42	;int: POSIX memory range locking
%assign	KERN_MEMORY_PROTECTION	43	;int: POSIX memory protections
%assign	KERN_LOGIN_NAME_MAX	44	;int: max length login name + NUL
%assign	KERN_DEFCORENAME	45	;old: sort core name format
%assign	KERN_LOGSIGEXIT		46	;int: log signalled processes
%assign	KERN_PROC2		47	;struct: process entries
%assign	KERN_PROC_ARGS		48	;struct: process argv/env
%assign	KERN_FSCALE		49	;int: fixpt FSCALE
%assign	KERN_CCPU		50	;int: fixpt ccpu
%assign	KERN_CP_TIME		51	;struct: cpu time counters
%assign	KERN_SYSVIPC_INFO	52	;number of valid kern ids
%assign	KERN_MSGBUF		53	;kernel message buffer
%assign	KERN_CONSDEV		54	;dev_t: console terminal device
%assign	KERN_MAXPTYS		55	;int: maximum number of ptys
%assign	KERN_PIPE		56	;node: pipe limits
%assign	KERN_MAXPHYS		57	;int: kernel value of MAXPHYS
%assign	KERN_SBMAX		58	;int: max socket buffer size
%assign	KERN_MAXID		59	;number of valid kern ids

%assign	KERN_PROC_ALL		 0	;everything
%assign	KERN_PROC_PID		 1	;by process id
%assign	KERN_PROC_PGRP		 2	;by process group id
%assign	KERN_PROC_SESSION	 3	;by session of pid
%assign	KERN_PROC_TTY		 4	;by controlling tty
%assign	KERN_PROC_UID		 5	;by effective uid
%assign	KERN_PROC_RUID		 6	;by real uid
%assign	KERN_PROC_GID		 7	;by effective gid
%assign	KERN_PROC_RGID		 8	;by real gid

%assign	KERN_PROC_ARGV		1	;argv
%assign	KERN_PROC_NARGV		2	;number of strings in above
%assign	KERN_PROC_ENV		3	;environ
%assign	KERN_PROC_NENV		4	;number of strings in above

%assign	HW_MACHINE	 1		;string: machine class
%assign	HW_MODEL	 2		;string: specific machine model
%assign	HW_NCPU		 3		;int: number of cpus
%assign	HW_BYTEORDER	 4		;int: machine byte order
%assign	HW_PHYSMEM	 5		;int: total memory
%assign	HW_USERMEM	 6		;int: non-kernel memory
%assign	HW_PAGESIZE	 7		;int: software page size
%assign	HW_DISKNAMES	 8		;strings: disk drive names
%assign	HW_DISKSTATS	 9		;struct: diskstats[]
%assign	HW_MACHINE_ARCH	10		;string: machine architecture
%assign	HW_ALIGNBYTES	11		;int: ALIGNBYTES for the kernel
%assign	HW_CNMAGIC	12		;string: console magic sequence(s)
%assign	HW_MAXID	13		;number of valid hw ids

%assign	USER_CS_PATH		 1	;string: _CS_PATH
%assign	USER_BC_BASE_MAX	 2	;int: BC_BASE_MAX
%assign	USER_BC_DIM_MAX		 3	;int: BC_DIM_MAX
%assign	USER_BC_SCALE_MAX	 4	;int: BC_SCALE_MAX
%assign	USER_BC_STRING_MAX	 5	;int: BC_STRING_MAX
%assign	USER_COLL_WEIGHTS_MAX	 6	;int: COLL_WEIGHTS_MAX
%assign	USER_EXPR_NEST_MAX	 7	;int: EXPR_NEST_MAX
%assign	USER_LINE_MAX		 8	;int: LINE_MAX
%assign	USER_RE_DUP_MAX		 9	;int: RE_DUP_MAX
%assign	USER_POSIX2_VERSION	10	;int: POSIX2_VERSION
%assign	USER_POSIX2_C_BIND	11	;int: POSIX2_C_BIND
%assign	USER_POSIX2_C_DEV	12	;int: POSIX2_C_DEV
%assign	USER_POSIX2_CHAR_TERM	13	;int: POSIX2_CHAR_TERM
%assign	USER_POSIX2_FORT_DEV	14	;int: POSIX2_FORT_DEV
%assign	USER_POSIX2_FORT_RUN	15	;int: POSIX2_FORT_RUN
%assign	USER_POSIX2_LOCALEDEF	16	;int: POSIX2_LOCALEDEF
%assign	USER_POSIX2_SW_DEV	17	;int: POSIX2_SW_DEV
%assign	USER_POSIX2_UPE		18	;int: POSIX2_UPE
%assign	USER_STREAM_MAX		19	;int: POSIX2_STREAM_MAX
%assign	USER_TZNAME_MAX		20	;int: POSIX2_TZNAME_MAX
%assign	USER_MAXID		21	;number of valid user ids

%assign	DDBCTL_RADIX		1	;int: Input and output radix
%assign	DDBCTL_MAXOFF		2	;int: max symbol offset
%assign	DDBCTL_MAXWIDTH		3	;int: width of the display line
%assign	DDBCTL_LINES		4	;int: number of display lines
%assign	DDBCTL_TABSTOPS		5	;int: tab width
%assign	DDBCTL_ONPANIC		6	;int: DDB on panic if non-zero
%assign	DDBCTL_FROMCONSOLE	7	;int: DDB via console if non-zero
%assign	DDBCTL_MAXID		8	;number of valid DDB ids

%assign	CTL_DEBUG_NAME		0	;string: variable name
%assign	CTL_DEBUG_VALUE		1	;int: variable value
%assign	CTL_DEBUG_MAXID		20

;
;generic BSD stuff
;

%include "os_bsd.inc"

%endif	;__NETBSD_INC
