; Copyright (C) 1999-2002 Konstantin Boldyshev <konst@linuxassembly.org>
;
; $Id: includes.inc,v 1.18 2002/03/14 07:08:55 konst Exp $
;
; file          : includes.inc
; created       : 04-Jul-1999
; modified      : 14-Mar-2002
; version       : 0.17
; assembler     : nasm 0.98
; description   : generic constants and structures from (libc) header files
; author        : Konstantin Boldyshev <konst@linuxassembly.org>
; comment       : included from system.inc

%ifndef	__SYSTEM_INC
%error "this file must be included from system.inc !"
%endif

%ifndef __INCLUDES_INC
%define __INCLUDES_INC

%assign	NULL	0

%assign TRUE	1
%assign FALSE	0

%assign	STDIN	0
%assign	STDOUT	1
%assign	STDERR	2

%assign	EOL	0

%assign	__a	0x07
%assign	__b	0x08
%assign	__e	0x1b
%assign	__f	0x0c
%assign	__n	0x0a
%assign	__r	0x0d
%assign	__t	0x09
%assign	__v	0x0b
%assign	__s	0x20

;
;datatypes
;

%define		INT		resd
%define		UINT		resd
%define		LONG		resd
%define		ULONG		resd
%define 	SHORT		resw
%define		USHORT		resw
%define		CHAR		resb
%define		UCHAR		resb
%define		BYTE		resb
%define		WORD		resw
%define		DWORD		resd
%define		U8		resb
%define		U16		resw
%define		U32		resd

%define		TIME_T		LONG
%define		MODE_T		UINT
%define		SIZE_T		ULONG
%define		OFF_T		ULONG

%define		PCHAR		resd
%define		PINT		resd
%define		PLONG		resd

%define		_INT		dd
%define		_UINT		dd
%define		_LONG		dd
%define		_ULONG		dd
%define 	_SHORT		dw
%define		_USHORT		dw
%define		_CHAR		db
%define		_UCHAR		db
%define		_BYTE		db
%define		_WORD		dw
%define		_DWORD		dd
%define		_U8		db
%define		_U16		dw
%define		_U32		dd

%define		_TIME_T		_LONG
%define		_MODE_T		_UINT
%define		_SIZE_T		_ULONG
%define		_OFF_T		_ULONG

;
;please provide corresponding include file when adding new entries
;

;
;fcntl.h
;

%assign SEEK_SET	0
%assign SEEK_CUR	1
%assign SEEK_END	2

%assign O_RDONLY	0
%assign O_WRONLY	1
%assign O_RDWR		2
%assign O_ACCMODE	3
%assign O_CREAT		100q
%assign O_EXCL		200q
%assign O_NOCTTY	400q
%assign O_TRUNC		1000q
%assign O_APPEND	2000q
%assign O_NONBLOCK	4000q
%assign O_NDELAY	O_NONBLOCK
%assign O_SYNC		 10000q
%assign FASYNC		 20000q
%assign O_DIRECT	 40000q
%assign O_LARGEFILE	100000q
%assign O_DIRECTORY	200000q
%assign O_NOFOLLOW	400000q

%assign F_DUPFD		0	;Duplicate file descriptor
%assign F_GETFD		1	;Get file descriptor flags
%assign F_SETFD		2	;Set file descriptor flags
%assign F_GETFL		3	;Get file status flags
%assign F_SETFL		4	;Set file status flags
%assign F_GETLK		5	;Get record locking info
%assign F_SETLK		6	;Set record locking info (non-blocking)
%assign F_SETLKW	7	;Set record locking info (blocking)


;
;unistd.h
;

%assign	R_OK	4	; read
%assign W_OK	2	; write
%assign X_OK	1	; execute
%assign F_OK	0	; existence

;
;signal.h
;

%assign SIG_DFL		0
%assign SIG_IGN		1
%assign SIG_ERR		-1

%assign	SIGHUP		1	;Hangup (POSIX)
%assign	SIGINT		2	;Interrupt (ANSI)
%assign	SIGQUIT		3	;Quit (POSIX)
%assign	SIGILL		4	;Illegal instruction (ANSI)
%assign	SIGTRAP		5	;Trace trap (POSIX)
%assign	SIGABRT		6	;Abort (ANSI)
%assign	SIGIOT		6	;IOT trap (4.2 BSD)
%assign	SIGBUS		7	;BUS error (4.2 BSD)
%assign	SIGFPE		8	;Floating-point exception (ANSI)
%assign	SIGKILL		9	;Kill, unblockable (POSIX)
%assign	SIGUSR1		10	;User-defined signal 1 (POSIX)
%assign	SIGSEGV		11	;Segmentation violation (ANSI)
%assign	SIGUSR2		12	;User-defined signal 2 (POSIX)
%assign	SIGPIPE		13	;Broken pipe (POSIX)
%assign	SIGALRM		14	;Alarm clock (POSIX)
%assign	SIGTERM		15	;Termination (ANSI)
%assign	SIGSTKFLT	16	;Stack fault
%assign	SIGCHLD		17	;Child status has changed (POSIX)
%assign	SIGCLD		SIGCHLD	;Same as SIGCHLD (System V)
%assign	SIGCONT		18	;Continue (POSIX)
%assign	SIGSTOP		19	;Stop, unblockable (POSIX)
%assign	SIGTSTP		20	;Keyboard stop (POSIX)
%assign	SIGTTIN		21	;Background read from tty (POSIX)
%assign	SIGTTOU		22	;Background write to tty (POSIX)
%assign	SIGURG		23	;Urgent condition on socket (4.2 BSD)
%assign	SIGXCPU		24	;CPU limit exceeded (4.2 BSD)
%assign	SIGXFSZ		25	;File size limit exceeded (4.2 BSD)
%assign	SIGVTALRM	26	;Virtual alarm clock (4.2 BSD)
%assign	SIGPROF		27	;Profiling alarm clock (4.2 BSD)
%assign	SIGWINCH	28	;Window size change (4.3 BSD, Sun)
%assign	SIGIO		29	;I/O now possible (4.2 BSD)
%assign	SIGPOLL		SIGIO	;Pollable event occurred (System V)
%assign	SIGPWR		30	;Power failure restart (System V)
%assign SIGUNUSED	31
%assign	_NSIG		64	;Biggest signal number + 1

;
;limits.h
;

%assign	NAME_MAX	255
%assign	PATH_MAX	4095

;
;wait.h
;

%assign WNOHANG		1
%assign WUNTRACED	2

;
;sys/ptrace.h
;

%assign PT_TRACEME 0
%assign PT_PEEKDATA 2
%assign PT_GETREGS 012
%assign PT_SETREGS 013
%assign PT_POKEDATA 5
%assign PT_CONT 7
%assign PT_KILL 8
%assign PT_DETACH 0x11
%assign PT_SINGLESTEP 9

;
;sys/socket.h
;

%assign AF_UNSPEC	0
%assign AF_UNIX		1	; Unix domain sockets
%assign AF_LOCAL	1	; POSIX name for AF_UNIX
%assign AF_INET		2	; Internet IP Protocol
%assign AF_AX25		3	; Amateur Radio AX.25
%assign AF_IPX		4	; Novell IPX
%assign AF_APPLETALK	5	; AppleTalk DDP
%assign AF_NETROM	6	; Amateur Radio NET/ROM
%assign AF_BRIDGE	7	; Multiprotocol bridge
%assign AF_ATMPVC	8	; ATM PVCs
%assign AF_X25		9	; Reserved for X.25 project
%assign AF_INET6	10	; IP version 6
%assign AF_ROSE		11	; Amateur Radio X.25 PLP
%assign AF_DECnet	12	; Reserved for DECnet project
%assign AF_NETBEUI	13	; Reserved for 802.2LLC project
%assign AF_SECURITY	14	; Security callback pseudo AF
%assign AF_KEY		15	; PF_KEY key management API
%assign AF_NETLINK	16
%assign AF_ROUTE	AF_NETLINK 	; Alias to emulate 4.4BSD
%assign AF_PACKET	17	; Packet family
%assign AF_ASH		18	; Ash
%assign AF_ECONET	19	; Acorn Econet
%assign AF_ATMSVC	20	; ATM SVCs
%assign AF_SNA		22	; Linux SNA Project (nutters!)
%assign AF_IRDA		23	; IRDA sockets
%assign AF_MAX		32	; For now..

%assign PF_UNSPEC	AF_UNSPEC
%assign PF_UNIX		AF_UNIX
%assign PF_LOCAL	AF_LOCAL
%assign PF_INET		AF_INET
%assign PF_AX25		AF_AX25
%assign PF_IPX		AF_IPX
%assign PF_APPLETALK	AF_APPLETALK
%assign	PF_NETROM	AF_NETROM
%assign PF_BRIDGE	AF_BRIDGE
%assign PF_ATMPVC	AF_ATMPVC
%assign PF_X25		AF_X25
%assign PF_INET6	AF_INET6
%assign PF_ROSE		AF_ROSE
%assign PF_DECnet	AF_DECnet
%assign PF_NETBEUI	AF_NETBEUI
%assign PF_SECURITY	AF_SECURITY
%assign PF_KEY		AF_KEY
%assign PF_NETLINK	AF_NETLINK
%assign PF_ROUTE	AF_ROUTE
%assign PF_PACKET	AF_PACKET
%assign PF_ASH		AF_ASH
%assign PF_ECONET	AF_ECONET
%assign PF_ATMSVC	AF_ATMSVC
%assign PF_SNA		AF_SNA
%assign PF_IRDA		AF_IRDA
%assign PF_MAX		AF_MAX

%assign SOCK_STREAM    1	;stream (connection) socket
%assign SOCK_DGRAM     2	;datagram (conn.less) socket
%assign SOCK_RAW       3	;raw socket
%assign SOCK_RDM       4	;reliably-delivered message
%assign SOCK_SEQPACKET 5	;sequential packet socket
%assign SOCK_PACKET    10	;linux specific way of getting packets at the dev level

%assign IPPROTO_IP		0		; Dummy protocol for TCP
%assign IPPROTO_HOPOPTS		0		; IPv6 Hop-by-Hop options
%assign IPPROTO_ICMP		1		; Internet Control Message Protocol
%assign IPPROTO_IGMP		2		; Internet Group Management Protocol
%assign IPPROTO_IPIP		4		; IPIP tunnels (older KA9Q tunnels use 94)
%assign IPPROTO_TCP		6		; Transmission Control Protocol
%assign IPPROTO_EGP		8		; Exterior Gateway Protocol
%assign IPPROTO_PUP		12		; PUP protocol
%assign IPPROTO_UDP		17		; User Datagram Protocol
%assign IPPROTO_IDP		22		; XNS IDP protocol
%assign IPPROTO_TP		29		; SO Transport Protocol Class 4
%assign IPPROTO_IPV6		41		; IPv6 header
%assign IPPROTO_ROUTING		43		; IPv6 routing header
%assign IPPROTO_FRAGMENT 	44		; IPv6 fragmentation header
%assign IPPROTO_RSVP		46		; Reservation Protocol
%assign IPPROTO_GRE		47		; General Routing Encapsulation
%assign IPPROTO_ESP		50		; encapsulating security payload
%assign IPPROTO_AH		51		; authentication header
%assign IPPROTO_ICMPV6		58		; ICMPv6
%assign IPPROTO_NONE		59		; IPv6 no next header
%assign IPPROTO_DSTOPTS		60		; IPv6 destination options
%assign IPPROTO_MTP		92		; Multicast Transport Protocol
%assign IPPROTO_ENCAP		98		; Encapsulation Header
%assign IPPROTO_PIM		103		; Protocol Independent Multicast
%assign IPPROTO_RAW		255		; Raw IP packets

;
; netinet/ip_icmp.h
;

%assign ICMP_ECHOREPLY          0       ; Echo Reply                   
%assign ICMP_DEST_UNREACH       3       ; Destination Unreachable      
%assign ICMP_SOURCE_QUENCH      4       ; Source Quench                
%assign ICMP_REDIRECT           5       ; Redirect (change route)      
%assign ICMP_ECHO               8       ; Echo Request                 
%assign ICMP_TIME_EXCEEDED      11      ; Time Exceeded                
%assign ICMP_PARAMETERPROB      12      ; Parameter Problem            
%assign ICMP_TIMESTAMP          13      ; Timestamp Request            
%assign ICMP_TIMESTAMPREPLY     14      ; Timestamp Reply              
%assign ICMP_INFO_REQUEST       15      ; Information Request          
%assign ICMP_INFO_REPLY         16      ; Information Reply            
%assign ICMP_ADDRESS            17      ; Address Mask Request         
%assign ICMP_ADDRESSREPLY       18      ; Address Mask Reply           
%assign NR_ICMP_TYPES           18

; Codes for UNREACH. 
%assign ICMP_NET_UNREACH        0       ; Network Unreachable          
%assign ICMP_HOST_UNREACH       1       ; Host Unreachable             
%assign ICMP_PROT_UNREACH       2       ; Protocol Unreachable         
%assign ICMP_PORT_UNREACH       3       ; Port Unreachable             
%assign ICMP_FRAG_NEEDED        4       ; Fragmentation Needed/DF set  
%assign ICMP_SR_FAILED          5       ; Source Route failed          
%assign ICMP_NET_UNKNOWN        6
%assign ICMP_HOST_UNKNOWN       7
%assign ICMP_HOST_ISOLATED      8
%assign ICMP_NET_ANO            9
%assign ICMP_HOST_ANO           10
%assign ICMP_NET_UNR_TOS        11
%assign ICMP_HOST_UNR_TOS       12
%assign ICMP_PKT_FILTERED       13      ; Packet filtered 
%assign ICMP_PREC_VIOLATION     14      ; Precedence violation 
%assign ICMP_PREC_CUTOFF        15      ; Precedence cut off 
%assign NR_ICMP_UNREACH         15      ; instead of hardcoding immediate value 

; Codes for REDIRECT. 
%assign ICMP_REDIR_NET          0       ; Redirect Net                 
%assign ICMP_REDIR_HOST         1       ; Redirect Host                
%assign ICMP_REDIR_NETTOS       2       ; Redirect Net for TOS         
%assign ICMP_REDIR_HOSTTOS      3       ; Redirect Host for TOS        

; Codes for TIME_EXCEEDED. 
%assign ICMP_EXC_TTL            0       ; TTL count exceeded           
%assign ICMP_EXC_FRAGTIME       1       ; Fragment Reass time exceeded 

;
;time.h
;

struc timespec
.tv_sec		ULONG	1
.tv_nsec	ULONG	1
endstruc

struc timeval
.tv_sec		ULONG	1
.tv_usec	ULONG	1
endstruc

struc tm
.tm_sec		INT	1
.tm_min		INT	1
.tm_hour	INT	1
.tm_mday	INT	1
.tm_mon		INT	1
.tm_year	INT	1
.tm_wday	INT	1
.tm_yday	INT	1
.tm_isdst	INT	1
.tm_gmtoff	LONG	1	;Seconds east of UTC
.tm_zone	PCHAR	1	;Timezone abbreviation
endstruc

;
;sys/utsname.h
;

%ifdef __BSD__
%assign SYS_NMLN 32
%assign MAXHOSTNAMELEN 256
%else
%assign SYS_NMLN 65
%assign MAXHOSTNAMELEN SYS_NMLN - 1
%endif

struc utsname
.sysname	CHAR	SYS_NMLN
.nodename	CHAR	SYS_NMLN
.release	CHAR	SYS_NMLN
.version	CHAR	SYS_NMLN
.machine	CHAR	SYS_NMLN
.domainname	CHAR	SYS_NMLN
endstruc

;
;sys/mman.h
;

%assign PROT_READ	0x1
%assign PROT_WRITE	0x2
%assign PROT_EXEC	0x4
%assign PROT_NONE	0x0

%assign MAP_SHARED	0x01
%assign MAP_PRIVATE	0x02
%assign MAP_TYPE	0x0f
%assign MAP_FIXED	0x10
%assign MAP_ANONYMOUS	0x20

;
;sys/stat.h
;

%assign	S_ISUID	0004000q	;set user id on execution
%assign	S_ISGID	0002000q	;set group id on execution
%assign	S_ISTXT	0001000q	;sticky bit

%assign	S_IRWXU	0000700q	;RWX mask for owner
%assign	S_IRUSR	0000400q	;R for owner
%assign	S_IWUSR	0000200q	;W for owner
%assign	S_IXUSR	0000100q	;X for owner

%assign	S_IREAD		S_IRUSR
%assign	S_IWRITE	S_IWUSR
%assign	S_IEXEC		S_IXUSR

%assign	S_IRWXG	0000070q	;RWX mask for group
%assign	S_IRGRP	0000040q	;R for group
%assign	S_IWGRP	0000020q	;W for group
%assign	S_IXGRP	0000010q	;X for group

%assign	S_IRWXO	0000007q	;RWX mask for other
%assign	S_IROTH	0000004q	;R for other
%assign	S_IWOTH	0000002q	;W for other
%assign	S_IXOTH	0000001q	;X for other

%assign	S_IFMT	 0170000q	;type of file mask
%assign	S_IFIFO	 0010000q	;named pipe (fifo)
%assign	S_IFCHR	 0020000q	;character special
%assign	S_IFDIR	 0040000q	;directory
%assign	S_IFBLK	 0060000q	;block special
%assign	S_IFREG	 0100000q	;regular
%assign	S_IFLNK	 0120000q	;symbolic link
%assign	S_IFSOCK 0140000q	;socket
%assign	S_IFWHT  0160000q	;whiteout
%assign	S_ISVTX	 0001000q	;save swapped text even after use

;
;sys/poll.h
;

%assign POLLIN      0x0001   ;There is data to read
%assign POLLPRI     0x0002   ;There is urgent data to read
%assign POLLOUT     0x0004   ;Writing now will not block
%assign POLLERR     0x0008   ;Error condition
%assign POLLHUP     0x0010   ;Hung up
%assign POLLNVAL    0x0020   ;Invalid request: fd not open

;
;sys/resource.h
;

%assign PRIO_PROCESS	0
%assign PRIO_PGRP	1
%assign	PRIO_USER	2

;
;socket.h
;

struc	sockaddr
.sa_family_t	USHORT	1		;address family, AF_xxx
.sa_data	CHAR	14		;14 bytes of protocol address
endstruc

;
;in.h
;

struc in_addr
.s_addr		U32	1
endstruc

;
;
;

struc winsize
.ws_row		USHORT	1
.ws_col		USHORT	1
.ws_xpixel	USHORT	1
.ws_ypixel	USHORT	1
endstruc

%endif	;__INCLUDES_INC
