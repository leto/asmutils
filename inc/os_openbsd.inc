; Copyright (C) 2000-2002 Konstantin Boldyshev <konst@linuxassembly.org>
; Copyright (C) 2000 Tani Hosokawa <unknown@riverstyx.net>
;
; $Id: os_openbsd.inc,v 1.8 2002/03/14 17:40:13 konst Exp $
;
; file          : os_openbsd.inc
; created       : 18-Aug-2000
; modified      : 14-Mar-2002
; version       : 0.17
; assembler     : nasm 0.98
; description   : OpenBSD kernel (2.7+) constants and structures
; author        : Tani Hosokawa <unknown@riverstyx.net>
; comment       : included from system.inc

%ifndef __SYSTEM_INC
%error "this file must be included from system.inc !"
%endif

%ifndef __OPENBSD_INC
%define __OPENBSD_INC

;
;sys/syscall.h
;
;see sys/syscall.h and sys/syscallargs.h to find out arguments for each syscall
;$OpenBSD: syscall.h,v 1.53 2001/08/26 04:11:12 deraadt Exp $
;created from;	OpenBSD: syscalls.master,v 1.47 2001/06/26 19:56:52 dugsong Exp 

%assign	SYS_syscall	0
%assign	SYS_exit	1
%assign	SYS_fork	2
%assign	SYS_read	3
%assign	SYS_write	4
%assign	SYS_open	5
%assign	SYS_close	6
%assign	SYS_wait4	7
;				/* 8 is compat_43 ocreat */
%assign	SYS_link	9
%assign	SYS_unlink	10
;				/* 11 is obsolete execv */
%assign	SYS_chdir	12
%assign	SYS_fchdir	13
%assign	SYS_mknod	14
%assign	SYS_chmod	15
%assign	SYS_chown	16
%assign	SYS_break	17
;				/* 18 is compat_25 ogetfsstat */
;				/* 19 is compat_43 olseek */
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
;				/* 38 is compat_43 ostat */
%assign	SYS_getppid	39
;				/* 40 is compat_43 olstat */
%assign	SYS_dup	41
%assign	SYS_opipe	42
%assign	SYS_getegid	43
%assign	SYS_profil	44
%assign	SYS_ktrace	45
%assign	SYS_sigaction	46
%assign	SYS_getgid	47
%assign	SYS_sigprocmask	48
%assign	SYS_getlogin	49
%assign	SYS_setlogin	50
%assign	SYS_acct	51
%assign	SYS_sigpending	52
%assign	SYS_sigaltstack	53
%assign	SYS_ioctl	54
%assign	SYS_reboot	55
%assign	SYS_revoke	56
%assign	SYS_symlink	57
%assign	SYS_readlink	58
%assign	SYS_execve	59
%assign	SYS_umask	60
%assign	SYS_chroot	61
;				/* 62 is compat_43 ofstat */
;				/* 63 is compat_43 ogetkerninfo */
;				/* 64 is compat_43 ogetpagesize */
%assign	SYS_omsync	65
%assign	SYS_vfork	66
;				/* 67 is obsolete vread */
;				/* 68 is obsolete vwrite */
%assign	SYS_sbrk	69
%assign	SYS_sstk	70
;				/* 71 is compat_43 ommap */
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
;				/* 84 is compat_43 owait */
%assign	SYS_swapon	85
%assign	SYS_getitimer	86
;				/* 87 is compat_43 ogethostname */
;				/* 88 is compat_43 osethostname */
;				/* 89 is compat_43 ogetdtablesize */
%assign	SYS_dup2	90
%assign	SYS_fcntl	92
%assign	SYS_select	93
%assign	SYS_fsync	95
%assign	SYS_setpriority	96
%assign	SYS_socket	97
%assign	SYS_connect	98
;				/* 99 is compat_43 oaccept */
%assign	SYS_getpriority	100
;				/* 101 is compat_43 osend */
;				/* 102 is compat_43 orecv */
%assign	SYS_sigreturn	103
%assign	SYS_bind	104
%assign	SYS_setsockopt	105
%assign	SYS_listen	106
;				/* 107 is obsolete vtimes */
;				/* 108 is compat_43 osigvec */
;				/* 109 is compat_43 osigblock */
;				/* 110 is compat_43 osigsetmask */
%assign	SYS_sigsuspend	111
;				/* 112 is compat_43 osigstack */
;				/* 113 is compat_43 orecvmsg */
;				/* 114 is compat_43 osendmsg */
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
;				/* 125 is compat_43 orecvfrom */
;				/* 126 is compat_43 osetreuid */
;				/* 127 is compat_43 osetregid */
%assign	SYS_rename	128
;				/* 129 is compat_43 otruncate */
;				/* 130 is compat_43 oftruncate */
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
;				/* 141 is compat_43 ogetpeername */
;				/* 142 is compat_43 ogethostid */
;				/* 143 is compat_43 osethostid */
;				/* 144 is compat_43 ogetrlimit */
;				/* 145 is compat_43 osetrlimit */
;				/* 146 is compat_43 okillpg */
%assign	SYS_setsid	147
%assign	SYS_quotactl	148
;				/* 149 is compat_43 oquota */
;				/* 150 is compat_43 ogetsockname */
%assign	SYS_nfssvc	155
;				/* 156 is compat_43 ogetdirentries */
;				/* 157 is compat_25 ostatfs */
;				/* 158 is compat_25 ostatfs */
%assign	SYS_getfh	161
;				/* 162 is compat_09 ogetdomainname */
;				/* 163 is compat_09 osetdomainname */
;				/* 164 is compat_09 ouname */
%assign	SYS_sysarch	165
;				/* 169 is compat_10 osemsys */
;				/* 170 is compat_10 omsgsys */
;				/* 171 is compat_10 oshmsys */
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
%assign	SYS_stat	188
%assign	SYS_fstat	189
%assign	SYS_lstat	190
%assign	SYS_pathconf	191
%assign	SYS_fpathconf	192
%assign	SYS_swapctl	193
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
%assign	SYS_xfspioctl	208
;				/* 220 is compat_23 __osemctl */
%assign	SYS_semget	221
%assign	SYS_semop	222
;				/* 223 is obsolete sys_semconfig */
;				/* 224 is compat_23 omsgctl */
%assign	SYS_msgget	225
%assign	SYS_msgsnd	226
%assign	SYS_msgrcv	227
%assign	SYS_shmat	228
;				/* 229 is compat_23 oshmctl */
%assign	SYS_shmdt	230
%assign	SYS_shmget	231
%assign	SYS_clock_gettime	232
%assign	SYS_clock_settime	233
%assign	SYS_clock_getres	234
%assign	SYS_nanosleep	240
%assign	SYS_minherit	250
%assign	SYS_rfork	251
%assign	SYS_poll	252
%assign	SYS_issetugid	253
%assign	SYS_lchown	254
%assign	SYS_getsid	255
%assign	SYS_msync	256
%assign	SYS___semctl	257
%assign	SYS_shmctl	258
%assign	SYS_msgctl	259
%assign	SYS_getfsstat	260
%assign	SYS_statfs	261
%assign	SYS_fstatfs	262
%assign	SYS_pipe	263
%assign	SYS_fhopen	264
%assign	SYS_fhstat	265
%assign	SYS_fhstatfs	266
%assign	SYS_preadv	267
%assign	SYS_pwritev	268
%assign	SYS_kqueue	269
%assign	SYS_kevent	270
%assign	SYS_mlockall	271
%assign	SYS_munlockall	272
%assign	SYS_getpeereid	273
%assign	SYS_MAXSYSCALL	274

;
;loopbacks
;

%assign	SYS_brk		SYS_break
%assign	SYS_umount	SYS_unmount
%assign	SYS_sysctl	SYS___sysctl
;%assign	SYS_setdomainname SYS_compat_09_osetdomainname
;%assign	SYS_getdomainname SYS_compat_09_ogetdomainname
;%assign	SYS_sethostname	SYS_compat_43_osethostname
;%assign	SYS_gethostname	SYS_compat_43_ogethostname
;%assign	SYS_uname	SYS_compat_09_ouname
%assign	SYS_getdents	SYS_getdirentries
%assign	SYS_getcwd	SYS_getpid
%assign	SYS_signal	SYS_getpid
%assign	SYS_alarm	SYS_getpid

;
;sys/sysctl.h
;
;$OpenBSD: sysctl.h,v 1.43 2001/09/28 01:42:54 millert Exp $
;$NetBSD: sysctl.h,v 1.16 1996/04/09 20:55:36 cgd Exp $

%assign CTL_MAXNAME	12	;largest number of components supported

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
%assign	CTL_FS		3		;file system, mount type is next
%assign	CTL_NET		4		;network, see socket.h
%assign	CTL_DEBUG	5		;debugging parameters
%assign	CTL_HW		6		;generic cpu/io
%assign	CTL_MACHDEP	7		;machine dependent
%assign	CTL_USER	8		;user-level
%assign	CTL_DDB		9		;DDB user interface, see db_var.h
%assign CTL_VFS         10              ;VFS sysctl's
%assign	CTL_MAXID	11		;number of valid top-level ids

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
%assign KERN_RAWPARTITION	24	;int: raw partition number
%assign	KERN_NTPTIME		25	;struct: extended-precision time
%assign	KERN_TIMEX		26	;struct: ntp timekeeping state
%assign	KERN_OSVERSION		27	;string: kernel build version
%assign	KERN_SOMAXCONN		28	;int: listen queue maximum
%assign	KERN_SOMINCONN		29	;int: half-open controllable param
%assign	KERN_USERMOUNT		30	;int: users may mount filesystems
%assign KERN_RND		31	;struct: rnd(4) statistics
%assign KERN_NOSUIDCOREDUMP	32	;int: no setuid coredumps ever */ 
%assign	KERN_FSYNC		33      ;int: file synchronization support
%assign	KERN_SYSVMSG		34      ;int: SysV message queue suppoprt
%assign	KERN_SYSVSEM		35      ;int: SysV semaphore support
%assign	KERN_SYSVSHM		36      ;int: SysV shared memory support
%assign	KERN_ARND		37	;int: random integer from arc4rnd
%assign	KERN_MSGBUFSIZE		38	;int: size of message buffer
%assign KERN_MALLOCSTATS	39	;node: malloc statistics
%assign KERN_CPTIME		40	;array: cp_time
%assign KERN_NCHSTATS		41	;struct: vfs cache statistics
%assign KERN_FORKSTAT		42	;struct: fork statistics
%assign KERN_NSELCOLL		43	;int: select(2) collisions
%assign KERN_TTY		44	;node: tty information
%assign	KERN_CCPU		45	;int: ccpu
%assign	KERN_FSCALE		46	;int: fscale
%assign	KERN_NPROCS		47	;int: number of processes
%assign	KERN_MSGBUF		48	;message buffer, KERN_MSGBUFSIZE
%assign	KERN_POOL		49	;struct: pool information
%assign	KERN_STACKGAPRANDOM	50	;int: stackgap_random
%assign	KERN_SYSVIPC_INFO	51	;struct: SysV sem/shm/msg info
%assign	KERN_MAXID		52	;number of valid kern ids

%assign KERN_PROC_ALL		0	;everything
%assign	KERN_PROC_PID		1	;by process id
%assign	KERN_PROC_PGRP		2	;by process group id
%assign	KERN_PROC_SESSION	3	;by session of pid
%assign	KERN_PROC_TTY		4	;by controlling tty
%assign	KERN_PROC_UID		5	;by effective uid
%assign	KERN_PROC_RUID		6	;by real uid
%assign	KERN_PROC_KTHREAD	7	;also return kernel threads

%assign	WMESGLEN	7
%assign	EPROC_CTTY	0x01	;controlling tty vnode active
%assign	EPROC_SLEADER	0x02	;session leader
%assign EMULNAMELEN	7

%assign	FS_POSIX	1		;POSIX flags
%assign	FS_MAXID	2

%assign	FS_POSIX_SETUID	1		;int: always clear SGID/SUID bit when owner change
%assign	FS_POSIX_MAXID	2

%assign	HW_MACHINE	 1		;string: machine class
%assign	HW_MODEL	 2		;string: specific machine model
%assign	HW_NCPU		 3		;int: number of cpus
%assign	HW_BYTEORDER	 4		;int: machine byte order
%assign	HW_PHYSMEM	 5		;int: total memory
%assign	HW_USERMEM	 6		;int: non-kernel memory
%assign	HW_PAGESIZE	 7		;int: software page size
%assign	HW_DISKNAMES	 8		;strings: disk drive names
%assign	HW_DISKSTATS	 9		;struct: diskstats[]
%assign	HW_DISKCOUNT	10		;int: number of disks
%assign	HW_MAXID	11		;number of valid hw ids

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

%assign	CTL_DEBUG_NAME		0	;string: variable name
%assign	CTL_DEBUG_VALUE		1	;int: variable value
%assign	CTL_DEBUG_MAXID		20

;
;generic BSD stuff
;

%include "os_bsd.inc"

%endif	;__OPENBSD_INC
