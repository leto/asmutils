; Copyright (C) 2000-2002 Konstantin Boldyshev <konst@linuxassembly.org>
;
; $Id: os_freebsd.inc,v 1.9 2002/03/14 17:40:13 konst Exp $
;
; file          : os_freebsd.inc
; created       : 08-Feb-2000
; modified      : 14-Mar-2002
; version       : 0.17
; assembler     : nasm 0.98
; description   : FreeBSD kernel (3.2+) defined constants and structures
; author        : Konstantin Boldyshev <konst@linuxassembly.org>
; comment       : included from system.inc

%ifndef __SYSTEM_INC
%error "this file must be included from system.inc !"
%endif

%ifndef __FREEBSD_INC
%define __FREEBSD_INC

;
;sys/syscall.h
;
;see sys/sysproto.h to find out arguments for each syscall
;$FreeBSD: src/sys/sys/syscall.h,v 1.69.2.8 2001/06/16 20:41:40 tegge Exp $
;created from FreeBSD: src/sys/kern/syscalls.master,v 1.72.2.6 2000/11/02 04:25:15 marcel Exp 

%assign	SYS_syscall	0
%assign	SYS_exit	1
%assign	SYS_fork	2
%assign	SYS_read	3
%assign	SYS_write	4
%assign	SYS_open	5
%assign	SYS_close	6
%assign	SYS_wait4	7
;				/* 8 is old creat */
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
;				/* 19 is old lseek */
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
;				/* 38 is old stat */
%assign	SYS_getppid	39
;				/* 40 is old lstat */
%assign	SYS_dup	41
%assign	SYS_pipe	42
%assign	SYS_getegid	43
%assign	SYS_profil	44
%assign	SYS_ktrace	45
%if __KERNEL__ < 40
%assign	SYS_sigaction	46
%endif
%assign	SYS_getgid	47
%if __KERNEL__ < 40
%assign	SYS_sigprocmask	48
%endif
%assign	SYS_getlogin	49
%assign	SYS_setlogin	50
%assign	SYS_acct	51
%if __KERNEL__ < 40
%assign	SYS_sigpending	52
%endif
%assign	SYS_sigaltstack	53
%assign	SYS_ioctl	54
%assign	SYS_reboot	55
%assign	SYS_revoke	56
%assign	SYS_symlink	57
%assign	SYS_readlink	58
%assign	SYS_execve	59
%assign	SYS_umask	60
%assign	SYS_chroot	61
;				/* 62 is old fstat */
;				/* 63 is old getkerninfo */
;				/* 64 is old getpagesize */
%assign	SYS_msync	65
%assign	SYS_vfork	66
;				/* 67 is obsolete vread */
;				/* 68 is obsolete vwrite */
%assign	SYS_sbrk	69
%assign	SYS_sstk	70
;				/* 71 is old mmap */
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
;				/* 84 is old wait */
%assign	SYS_swapon	85
%assign	SYS_getitimer	86
%if __KERNEL__ < 40
%assign	SYS_gethostname 87
%assign	SYS_sethostname 88
%endif
%assign	SYS_getdtablesize	89
%assign	SYS_dup2	90
%assign	SYS_fcntl	92
%assign	SYS_select	93
%assign	SYS_fsync	95
%assign	SYS_setpriority	96
%assign	SYS_socket	97
%assign	SYS_connect	98
;				/* 99 is old accept */
%assign	SYS_getpriority	100
;				/* 101 is old send */
;				/* 102 is old recv */
%if __KERNEL__ < 40
%assign	SYS_sigreturn	103
%endif
%assign	SYS_bind	104
%assign	SYS_setsockopt	105
%assign	SYS_listen	106
;				/* 107 is obsolete vtimes */
;				/* 108 is old sigvec */
;				/* 109 is old sigblock */
;				/* 110 is old sigsetmask */
%if __KERNEL__ < 40
%assign	SYS_sigsuspend	111
%endif
;				/* 112 is old sigstack */
;				/* 113 is old recvmsg */
;				/* 114 is old sendmsg */
;				/* 115 is obsolete vtrace */
%assign	SYS_gettimeofday	116
%assign	SYS_getrusage	117
%assign	SYS_getsockopt	118
%assign	SYS_readv	120
%assign	SYS_writev	121
%assign	SYS_settimeofday	122
%assign	SYS_fchown	123
%assign	SYS_fchmod	124
;				/* 125 is old recvfrom */
%assign	SYS_setreuid	126
%assign	SYS_setregid	127
%assign	SYS_rename	128
;				/* 129 is old truncate */
;				/* 130 is old ftruncate */
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
;				/* 141 is old getpeername */
;				/* 142 is old gethostid */
;				/* 143 is old sethostid */
;				/* 144 is old getrlimit */
;				/* 145 is old setrlimit */
;				/* 146 is old killpg */
%assign	SYS_setsid	147
%assign	SYS_quotactl	148
;				/* 149 is old quota */
;				/* 150 is old getsockname */
%assign	SYS_nfssvc	155
;				/* 156 is old getdirentries */
%assign	SYS_statfs	157
%assign	SYS_fstatfs	158
%assign	SYS_getfh	161
%assign	SYS_getdomainname	162
%assign	SYS_setdomainname	163
%assign	SYS_uname	164
%assign	SYS_sysarch	165
%assign	SYS_rtprio	166
%assign	SYS_semsys	169
%assign	SYS_msgsys	170
%assign	SYS_shmsys	171
%assign	SYS_pread	173
%assign	SYS_pwrite	174
%assign	SYS_ntp_adjtime	176
%assign	SYS_setgid	181
%assign	SYS_setegid	182
%assign	SYS_seteuid	183
%assign	SYS_stat	188
%assign	SYS_fstat	189
%assign	SYS_lstat	190
%assign	SYS_pathconf	191
%assign	SYS_fpathconf	192
%assign	SYS_getrlimit	194
%assign	SYS_setrlimit	195
%assign	SYS_getdirentries	196
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
%assign	SYS_poll	209
%assign	SYS___semctl	220
%assign	SYS_semget	221
%assign	SYS_semop	222
;%assign	SYS_semconfig	223
%assign	SYS_msgctl	224
%assign	SYS_msgget	225
%assign	SYS_msgsnd	226
%assign	SYS_msgrcv	227
%assign	SYS_shmat	228
%assign	SYS_shmctl	229
%assign	SYS_shmdt	230
%assign	SYS_shmget	231
%assign	SYS_clock_gettime	232
%assign	SYS_clock_settime	233
%assign	SYS_clock_getres	234
%assign	SYS_nanosleep	240
%assign	SYS_minherit	250
%assign	SYS_rfork	251
%assign	SYS_openbsd_poll	252
%assign	SYS_issetugid	253
%assign	SYS_lchown	254
%assign	SYS_getdents	272
%assign	SYS_lchmod	274
%assign	SYS_netbsd_lchown	275
%assign	SYS_lutimes	276
%assign	SYS_netbsd_msync	277
%assign	SYS_nstat	278
%assign	SYS_nfstat	279
%assign	SYS_nlstat	280
%if __KERNEL__ >= 40
%assign	SYS_fhstatfs	297
%assign	SYS_fhopen	298
%assign	SYS_fhstat	299
%endif
%assign	SYS_modnext	300
%assign	SYS_modstat	301
%assign	SYS_modfnext	302
%assign	SYS_modfind	303
%assign	SYS_kldload	304
%assign	SYS_kldunload	305
%assign	SYS_kldfind	306
%assign	SYS_kldnext	307
%assign	SYS_kldstat	308
%assign	SYS_kldfirstmod	309
%assign	SYS_getsid	310
%if __KERNEL__ >= 40
%assign	SYS_setresuid	311
%assign	SYS_setresgid	312
%endif
;				/* 313 is obsolete signanosleep */
%assign	SYS_aio_return	314
%assign	SYS_aio_suspend	315
%assign	SYS_aio_cancel	316
%assign	SYS_aio_error	317
%assign	SYS_aio_read	318
%assign	SYS_aio_write	319
%assign	SYS_lio_listio	320
%assign	SYS_yield	321
%assign	SYS_thr_sleep	322
%assign	SYS_thr_wakeup	323
%assign	SYS_mlockall	324
%assign	SYS_munlockall	325
%assign	SYS___getcwd	326
%assign	SYS_sched_setparam	327
%assign	SYS_sched_getparam	328
%assign	SYS_sched_setscheduler	329
%assign	SYS_sched_getscheduler	330
%assign	SYS_sched_yield	331
%assign	SYS_sched_get_priority_max	332
%assign	SYS_sched_get_priority_min	333
%assign	SYS_sched_rr_get_interval	334
%assign	SYS_utrace	335
%assign	SYS_sendfile	336
%assign	SYS_kldsym	337

%if __KERNEL__ >= 40
%assign	SYS_jail	338
%assign	SYS_sigprocmask	340
%assign	SYS_sigsuspend	341
%assign	SYS_sigaction	342
%assign	SYS_sigpending	343
%assign	SYS_sigreturn	344
%assign	SYS___acl_get_file	347
%assign	SYS___acl_set_file	348
%assign	SYS___acl_get_fd	349
%assign	SYS___acl_set_fd	350
%assign	SYS___acl_delete_file	351
%assign	SYS___acl_delete_fd	352
%assign	SYS___acl_aclcheck_file	353
%assign	SYS___acl_aclcheck_fd	354
%assign	SYS_extattrctl	355
%assign	SYS_extattr_set_file	356
%assign	SYS_extattr_get_file	357
%assign	SYS_extattr_delete_file	358
%assign	SYS_aio_waitcomplete	359
%assign	SYS_getresuid	360
%assign	SYS_getresgid	361
%assign	SYS_kqueue	362
%assign	SYS_kevent	363
%endif

;
;loopbacks
;

%assign	SYS_brk		SYS_break
%assign	SYS_sysctl	SYS___sysctl
%assign	SYS_umount	SYS_unmount
%assign	SYS_getcwd	SYS___getcwd
%assign	SYS_alarm	SYS_getpid
%assign	SYS_signal	SYS_getpid

;
;sys/sysctl.h
;
;$FreeBSD: src/sys/sys/sysctl.h,v 1.81.2.7 2001/07/18 15:36:56 pirzyk Exp $

%assign CTL_MAXNAME	12	;largest number of components supported

struc ctlname
.ctl_name	PCHAR	1	;*char to subsystem name
.ctl_type	INT	1	;type of name
endstruc

%assign CTLTYPE		0xf	;Mask for the type
%assign	CTLTYPE_NODE	1	;name is a node
%assign	CTLTYPE_INT	2	;name describes an integer
%assign	CTLTYPE_STRING	3	;name describes a string
%assign	CTLTYPE_QUAD	4	;name describes a 64-bit number
%assign	CTLTYPE_OPAQUE	5	;name describes a structure
%assign	CTLTYPE_STRUCT	CTLTYPE_OPAQUE	;name describes a structure
%assign	CTLTYPE_UINT	6	;name describes an unsigned integer
%assign	CTLTYPE_LONG	7	;name describes a long
%assign	CTLTYPE_ULONG	8	;name describes an unsigned long

%assign CTLFLAG_RD	0x80000000	;Allow reads of variable
%assign CTLFLAG_WR	0x40000000	;Allow writes to the variable
%assign CTLFLAG_RW	(CTLFLAG_RD|CTLFLAG_WR)
%assign CTLFLAG_NOLOCK	0x20000000	;XXX Don't Lock
%assign CTLFLAG_ANYBODY	0x10000000	;All users can set this var
%assign CTLFLAG_SECURE	0x08000000	;Permit set only if securelevel<=0
%assign CTLFLAG_PRISON	0x04000000	;Prisoned roots can fiddle
%assign CTLFLAG_DYN	0x02000000	;Dynamic oid - can be freed

%assign	CTL_UNSPEC	0		;unused
%assign	CTL_KERN	1		;"high kernel": proc, limits
%assign	CTL_VM		2		;virtual memory
%assign	CTL_VFS		3		;file system, mount type is next
%assign	CTL_NET		4		;network, see socket.h
%assign	CTL_DEBUG	5		;debugging parameters
%assign	CTL_HW		6		;generic cpu/io
%assign	CTL_MACHDEP	7		;machine dependent
%assign	CTL_USER	8		;user-level
%assign	CTL_P1003_1B	9		;POSIX 1003.1B
%assign	CTL_MAXID	10		;number of valid top-level ids

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
%assign KERN_NISDOMAINNAME	22	;string: YP domain name
%assign KERN_DOMAINNAME		KERN_NISDOMAINNAME	;loopback
%assign KERN_UPDATEINTERVAL	23	;int: update process sleep time
%assign KERN_OSRELDATE		24	;int: OS release date
%assign KERN_NTP_PLL		25	;node: NTP PLL control
%assign	KERN_BOOTFILE		26	;string: name of booted kernel
%assign	KERN_MAXFILESPERPROC	27	;int: max open files per proc
%assign	KERN_MAXPROCPERUID 	28	;int: max processes per uid
%assign KERN_DUMPDEV		29	;dev_t: device to dump on
%assign	KERN_IPC		30	;node: anything related to IPC
%assign	KERN_DUMMY		31	;unused
%assign	KERN_PS_STRINGS		32	;int: address of PS_STRINGS
%assign	KERN_USRSTACK		33	;int: address of USRSTACK
%assign	KERN_LOGSIGEXIT		34	;int: do we log sigexit procs?
%assign KERN_MAXID		35      ;number of valid kern ids

%assign KERN_PROC_ALL		0	;everything
%assign	KERN_PROC_PID		1	;by process id
%assign	KERN_PROC_PGRP		2	;by process group id
%assign	KERN_PROC_SESSION	3	;by session of pid
%assign	KERN_PROC_TTY		4	;by controlling tty
%assign	KERN_PROC_UID		5	;by effective uid
%assign	KERN_PROC_RUID		6	;by real uid
%assign	KERN_PROC_ARGS		7	;get/set arguments/proctitle

%assign	HW_MACHINE	 1		;string: machine class
%assign	HW_MODEL	 2		;string: specific machine model
%assign	HW_NCPU		 3		;int: number of cpus
%assign	HW_BYTEORDER	 4		;int: machine byte order
%assign	HW_PHYSMEM	 5		;int: total memory
%assign	HW_USERMEM	 6		;int: non-kernel memory
%assign	HW_PAGESIZE	 7		;int: software page size
%assign	HW_DISKNAMES	 8		;strings: disk drive names
%assign	HW_DISKSTATS	 9		;struct: diskstats[]
%assign HW_FLOATINGPT	10		;int: has HW floating point?
%assign HW_MACHINE_ARCH	11		;string: machine architecture
%assign	HW_MAXID	12		;number of valid hw ids

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

;
;sys/linker.h
;

%assign MODINFO_END		0x0000		;End of list
%assign MODINFO_NAME		0x0001		;Name of module (string)
%assign MODINFO_TYPE		0x0002		;Type of module (string)
%assign MODINFO_ADDR		0x0003		;Loaded address
%assign MODINFO_SIZE		0x0004		;Size of module
%assign MODINFO_EMPTY		0x0005		;Has been deleted
%assign MODINFO_ARGS		0x0006		;Parameters string
%assign MODINFO_METADATA	0x8000		;Module-specfic

%assign MODINFOMD_AOUTEXEC	0x0001		;a.out exec header
%assign MODINFOMD_ELFHDR	0x0002		;ELF header
%assign MODINFOMD_SSYM		0x0003		;start of symbols
%assign MODINFOMD_ESYM		0x0004		;end of symbols
%assign MODINFOMD_DYNAMIC	0x0005		;_DYNAMIC pointer
%assign MODINFOMD_NOCOPY	0x8000		;don't copy this metadata to the kernel

%assign	MAXPATHLEN	1024

struc kld_file_stat
.version	INT	1		;set to sizeof(linker_file_stat)
.name		CHAR	MAXPATHLEN
.refs		INT	1
.id		INT	1
.address	PCHAR	1		;load address
.size		SIZE_T	1		;size in bytes
endstruc

%macro	sys_kldload 0-1
	__syscall kldload, 1, %0, %1
%endmacro

%macro	sys_kldunload 0-1
	__syscall kldunload, 1, %0, %1
%endmacro

%macro	sys_kldfind 0-1
	__syscall kldfind, 1, %0, %1
%endmacro

%macro	sys_kldnext 0-1
	__syscall kldnext, 1, %0, %1
%endmacro

%macro	sys_kldstat 0-2
	__syscall kldstat, 2, %0, %1, %2
%endmacro

%macro	sys_kldfirstmod 0-1
	__syscall kldfirstmod, 1, %0, %1
%endmacro

%macro	sys_kldsym 0-3
	__syscall kldload, 3, %0, %1, %2, %3
%endmacro

;
;generic BSD stuff
;

%include "os_bsd.inc"

%endif	;__FREEBSD_INC
