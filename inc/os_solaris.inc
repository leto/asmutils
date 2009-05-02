; Copyright (C) 2001 Thomas M. Ogrisegg (thomas.ogrisegg@sbg.ac.at)
; 
; $Id: os_solaris.inc,v 1.4 2002/02/02 13:59:59 konst Exp $
;
; file		: os_solaris.inc
; created	: 04-Nov-2001
; modified	: 24-Nov-2001
; version	: 0.16
; assembler	: nasm
; author	: Thomas M. Ogrisegg
; comment	: included from system.inc
; license	: GNU General Public License
; release	: Alpha/Unstable
; OS		: Sun Solaris for x86 (7+8)
;
; THIS IS AN UNSTABLE VERSION! USE AT YOUR OWN RISK!
;
; Macros and definitions for Sun Solaris/x86

%ifndef __SYSTEM_INC
%error "this file must be included from system.inc"
%endif

%ifndef __SOLARIS_INC
%define __SOLARIS_INC

%macro	DO_SYSCALL 0
	call 0x27:0x0
%endmacro

%macro SYSCALL_GATE 0
__syscall_gate:
	DO_SYSCALL
	ret
%endmacro

%assign SYS_syscall 0
%assign SYS_exit    1
%assign SYS_fork    2
%assign SYS_read    3
%assign SYS_write   4
%assign SYS_open    5
%assign SYS_close   6
%assign SYS_wait    7
%assign SYS_creat   8
%assign SYS_link    9
%assign SYS_unlink  10
%assign SYS_exec    11
%assign SYS_chdir   12
%assign SYS_time    13
%assign SYS_mknod   14
%assign SYS_chmod   15
%assign SYS_chown   16
%assign SYS_brk     17
%assign SYS_stat    18
%assign SYS_lseek   19
%assign SYS_getpid  20
%assign SYS_mount   21
%assign SYS_umount  22
%assign SYS_setuid  23
%assign SYS_getuid  24
%assign SYS_stime   25
%assign SYS_pcsample    26
%assign SYS_alarm   27
%assign SYS_fstat   28
%assign SYS_pause   29
%assign SYS_utime   30
%assign SYS_stty    31
%assign SYS_gtty    32
%assign SYS_access  33
%assign SYS_nice    34
%assign SYS_statfs  35
%assign SYS_sync    36
%assign SYS_kill    37
%assign SYS_fstatfs 38
%assign SYS_pgrpsys 39
%assign SYS_xenix   40
%assign SYS_dup     41
%assign SYS_pipe    42
%assign SYS_times   43
%assign SYS_profil  44
%assign SYS_plock   45
%assign SYS_setgid  46
%assign SYS_getgid  47
%assign SYS_signal  48
%assign SYS_msgsys  49
%assign SYS_syssun  50
%assign SYS_sysi86  50
%assign SYS_acct    51
%assign SYS_shmsys  52
%assign SYS_semsys  53
%assign SYS_ioctl   54
%assign SYS_uadmin  55
%assign SYS_utssys  57
%assign SYS_fdsync  58
%assign SYS_execve  59
%assign SYS_umask   60
%assign SYS_chroot  61
%assign SYS_fcntl   62
%assign SYS_ulimit  63
%assign SYS_rmdir   79
%assign SYS_mkdir   80
%assign SYS_getdents    81
%assign SYS_sysfs   84
%assign SYS_getmsg  85
%assign SYS_putmsg  86
%assign SYS_poll    87
%assign SYS_lstat   88
%assign SYS_symlink 89
%assign SYS_readlink    90
%assign SYS_setgroups   91
%assign SYS_getgroups   92
%assign SYS_fchmod  93
%assign SYS_fchown  94
%assign SYS_sigprocmask 95
%assign SYS_sigsuspend  96
%assign SYS_sigaltstack 97
%assign SYS_sigaction   98
%assign SYS_sigpending  99
%assign SYS_context 100
%assign SYS_evsys   101
%assign SYS_evtrapret   102
%assign SYS_statvfs 103
%assign SYS_fstatvfs    104
%assign SYS_getloadavg  105
%assign SYS_nfssys  106
%assign SYS_waitsys 107
%assign SYS_sigsendsys  108
%assign SYS_hrtsys  109
%assign SYS_acancel 110
%assign SYS_async   111
%assign SYS_priocntlsys 112
%assign SYS_pathconf    113
%assign SYS_mincore 114
%assign SYS_mmap    115
%assign SYS_mprotect    116
%assign SYS_munmap  117
%assign SYS_fpathconf   118
%assign SYS_vfork   119
%assign SYS_fchdir  120
%assign SYS_readv   121
%assign SYS_writev  122
%assign SYS_xstat   123
%assign SYS_lxstat  124
%assign SYS_lxstat  124
%assign SYS_fxstat  125
%assign SYS_xmknod  126
%assign SYS_clocal  127
%assign SYS_setrlimit   128
%assign SYS_getrlimit   129
%assign SYS_lchown  130
%assign SYS_memcntl 131
%assign SYS_getpmsg 132
%assign SYS_putpmsg 133
%assign SYS_rename  134
%assign SYS_uname   135
%assign SYS_setegid 136
%assign SYS_sysconfig   137
%assign SYS_adjtime 138
%assign SYS_systeminfo  139
%assign SYS_seteuid 141
%assign SYS_vtrace  142
%assign SYS_fork1   143
%assign SYS_sigtimedwait    144
%assign SYS_lwp_info    145
%assign SYS_yield   146
%assign SYS_lwp_sema_wait   147
%assign SYS_lwp_sema_post   148
%assign SYS_lwp_sema_trywait    149
%assign SYS_corectl 151
%assign SYS_modctl  152
%assign SYS_fchroot 153
%assign SYS_utimes  154
%assign SYS_vhangup 155
%assign SYS_gettimeofday    156
%assign SYS_getitimer       157
%assign SYS_setitimer       158
%assign SYS_lwp_create      159
%assign SYS_lwp_exit        160
%assign SYS_lwp_suspend     161
%assign SYS_lwp_continue    162
%assign SYS_lwp_kill        163
%assign SYS_lwp_self        164
%assign SYS_lwp_setprivate  165
%assign SYS_lwp_getprivate  166
%assign SYS_lwp_wait        167
%assign SYS_lwp_mutex_wakeup    168
%assign SYS_lwp_mutex_lock  169
%assign SYS_lwp_cond_wait   170
%assign SYS_lwp_cond_signal 171
%assign SYS_lwp_cond_broadcast  172
%assign SYS_pread       173
%assign SYS_pwrite      174
%assign SYS_llseek      175
%assign SYS_inst_sync       176
%assign SYS_kaio        178
%assign SYS_tsolsys     184
%assign SYS_acl         185
%assign SYS_auditsys        186
%assign SYS_processor_bind  187
%assign SYS_processor_info  188
%assign SYS_p_online        189
%assign SYS_sigqueue        190
%assign SYS_clock_gettime   191
%assign SYS_clock_settime   192
%assign SYS_clock_getres    193
%assign SYS_timer_create    194
%assign SYS_timer_delete    195
%assign SYS_timer_settime   196
%assign SYS_timer_gettime   197
%assign SYS_timer_getoverrun    198
%assign SYS_nanosleep       199
%assign SYS_facl        200
%assign SYS_door        201
%assign SYS_setreuid        202
%assign SYS_setregid        203
%assign SYS_install_utrap   204
%assign SYS_signotify       205
%assign SYS_schedctl        206
%assign SYS_pset        207
%assign SYS_sparc_utrap_install 208
%assign SYS_resolvepath     209
%assign SYS_signotifywait   210
%assign SYS_lwp_sigredirect 211
%assign SYS_lwp_alarm       212
%assign SYS_getdents64      213
%assign SYS_mmap64      214
%assign SYS_stat64      215
%assign SYS_lstat64     216
%assign SYS_fstat64     217
%assign SYS_statvfs64       218
%assign SYS_fstatvfs64      219
%assign SYS_setrlimit64     220
%assign SYS_getrlimit64     221
%assign SYS_pread64     222
%assign SYS_pwrite64        223
%assign SYS_creat64     224
%assign SYS_open64      225
%assign SYS_rpcsys      226
%assign SYS_so_socket       230
%assign SYS_so_socketpair   231
%assign SYS_bind        232
%assign SYS_listen      233
%assign SYS_accept      234
%assign SYS_connect     235
%assign SYS_shutdown        236
%assign SYS_recv        237
%assign SYS_recvfrom        238
%assign SYS_recvmsg     239
%assign SYS_send        240
%assign SYS_sendmsg     241
%assign SYS_sendto      242
%assign SYS_getpeername     243
%assign SYS_getsockname     244
%assign SYS_getsockopt      245
%assign SYS_setsockopt      246
%assign SYS_sockconfig      247
%assign SYS_ntp_gettime     248
%assign SYS_ntp_adjtime     249
%assign SYS_lwp_mutex_unlock    250
%assign SYS_lwp_mutex_trylock   251
%assign SYS_lwp_mutex_init  252
%assign SYS_cladm       253

; System constants (Solaris/2.7)

%assign SOL_SOCKET	0xffff
%assign SO_REUSEADDR	0x0004

%assign F_DUP2FD	0x9

;-----------------------------------------------------;
; Special Systemcall macros for Solaris/x86           ;
;-----------------------------------------------------;

; need to emulate dup2 through fcntl
%macro sys_dup2 0-2
	__syscall fcntl, 1, %0, %1, F_DUP2FD, %2
%endmacro

%macro sys_socket 3
	__syscall so_socket, 1, %0, %1, %1, %3, 0, %2
%error %1, %1, %3, 0, %2
%endmacro

%macro sys_wait 0-2
	__syscall wait, 1, %1
%endmacro

; brk-Compatibility fix
; Doesnt work currently...

%macro sys_brk 0-1
%error "sys_brk doesnt work correctly under Solaris"
%endmacro

struc Stat
.st_dev		ULONG	1
.st_pad1	ULONG	3
.st_ino		ULONG	1
.st_mode	ULONG	1
.st_nlink	ULONG	1
.st_uid		ULONG	1
.st_gid		ULONG	1
.st_rdev	ULONG	1
.st_pad2	ULONG	2
.st_size	ULONG	1
.st_pad3	ULONG	1
.st_atime	ULONG	2
.st_mtime	ULONG	2
.st_ctime	ULONG	2
.st_blksize	ULONG	1
.st_blocks	ULONG	1
.st_fstype	UCHAR	16
.st_pad4	ULONG	8
endstruc

%endif
