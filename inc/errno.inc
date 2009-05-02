;-================================================================;
;- Copyright (C) 2000 H-Peter Recktenwald, Berlin <phpr@snafu.de>
;-
;- $Id: errno.inc,v 1.1 2000/09/03 16:13:53 konst Exp $
;-
;-  file  	: errno.inc
;-  switch	; __I386_ERRNO
;-  created	: 15-jan-2000
;-  modified	: 25-mai-2000
;-  version	: 0.03
;-  assembler	: nasm 0.98-3e
;-  description	: <ertstg> error messages strings assembly
;-		: <ertdsp> associated disp-s table
;-		: <sigstg> signal messages strings assembly
;-		: <sigdsp> associated disp-s table
;-		: <ermstg> error and signal strings addressing
;-		: strings macros further %define ernum/signum
;-		: related messages strings and named numbers.
;-  author	: H-Peter Recktenwald, Berlin <phpr@snafu.de>
;-  comment	: macros, inclusion doesn't compile any data.
;-		: re "errno_h.inc" for error names defn-s
;-  		: re "signal_h.inc" for signal names defn-s
;-		:
;-		: __N98E compile variable, if not defined, 
;-		: outcomments %xdefine statements to compiling
;-		: with nasm original (buggy!) program...
;-		:
;-  source	: linux 2.2.14, arch/i386/
;-  requires	: nasm-0.98, or patched/debugged version if
;-		: %defined variables' _values_ should be assigned
;-		: to newly defined differently named variables:
;-		: either one of nasm 0.98e
;-		:	ftp://ftp.linuxgames.com/crystal/nasm/
;-		: or, nasm 0.98-3e patches for nasm 0.98(3)
;-		:	http://home.snafu.de/phpr/lhputils.html
;-================================================================;
;-
%ifndef __I386_ERRNO
%define __I386_ERRNO

%ifndef __PROG
%define __PROG 'report'
%endif

; additional numbers, not in kernel
%define __I386_ERRNO_X
%undef  __I386_ERRNO_X

;-
;- errors
;-

;-
;- nr
;-	assigned, msg.no. labels counter
%assign nr 0

;-
;- num,macro 2
;-	label string generating
%macro num 2.nolist
%{2}%{1}:
%endmacro

;-
;- eno, macro 1
;-	label writing
%macro eno 1.nolist
    num nr,%{1}
%endmacro

;-
;- dbs, macro 1-3
;-	label & msg string assembly, errnum defn
;-	compiles list of word counted message strings,
;-	%define-s S(errorname) message strings as "S"-prepended standard error names,
;-	%assign-s (errorname)  -ve(!) error numbers as standard error names.
;-	<mn> %define-d to top msg.no. (used in "debug.inc")
;-	<nr> incremented by one, after label/stg defn.
%macro dbs 1-3.nolist
    eno e
        dw %%l2-%%l1+1
%%l1:   db 10,%{1}
%%l2:	db 10
    align 2
%if %{0} = 3
%ifnum %{3}
%define S%{2} %{1}
%assign %{2} -%{3}	; -ve ernum, as will be received...
%endif
%endif
%define mn nr
%assign nr nr+1
%endmacro

;-
;- error messages strings
;- two macros to be used in conjunction:
;-
;- ertstg, macro 0
;-	compiles labels & errormessages, defines -ve error codes
;-	and names, for instance:
;-		%define SEPERM 'Operation not permitted'
;-		%assign EPERM -1
;- 	<rt> label, base of msg strings
;-	<m.ro>,<a.ro>,<e.ro> internal labels, and
;-	<e1>..<e124> refer to message texts, rsp., and will be
;-	stet up by <ertdsp> for access by -ve number with <ermstg>.
%macro ertstg 0.nolist
	align 4
%assign nr 0
%ifndef EXT
%undef VER
%endif
%ifndef VER
%error "VERsion not defined"
%define VER 00
%define EXT 00
%endif
%ifndef DATE
%error "DATE not defined"
%define DATE 991231
%endif
	dbs {__PROG,'-',(VER/10)|48,(VER-VER/10*10)|48,'.',(EXT/10)|48,(EXT-EXT/10*10)|48,'-',DATE,' (C) 2000 hp Berlin, GNU GPL'}
rt:
        dbs 'Operation not permitted'				,EPERM		,1
	dbs 'No such file or directory'				,ENOENT		,2
        dbs 'No such process'					,ESRCH		,3
        dbs 'Interrupted system call'				,EINTR		,4
        dbs 'I/O error'						,EIO		,5
        dbs 'No such device or address'				,ENXIO		,6
        dbs 'Arg list too long'					,E2BIG		,7
        dbs 'Exec format error'					,ENOEXEC	,8
        dbs 'Bad file number'					,EBADF		,9
        dbs 'No child processes'				,ECHILD		,10
        dbs 'Try again'						,EAGAIN		,11
        dbs 'Out of memory'					,ENOMEM		,12
	dbs 'Permission denied'					,EACCES		,13
        dbs 'Bad address'					,EFAULT		,14
        dbs 'Block device required'				,ENOTBLK	,15
        dbs 'Device or resource busy'				,EBUSY		,16
        dbs 'File exists'					,EEXIST		,17
        dbs 'Cross-device link'					,EXDEV		,18
        dbs 'No such device'					,ENODEV		,19
        dbs 'Not a directory'					,ENOTDIR	,20
        dbs 'Is a directory'					,EISDIR		,21
        dbs 'Invalid argument'					,EINVAL		,22
        dbs 'File table overflow'				,ENFILE		,23
        dbs 'Too many open files'				,EMFILE		,24
        dbs 'Not a typewriter'					,ENOTTY		,25
        dbs 'Text file busy'					,ETXTBSY	,26
        dbs 'File too large'					,EFBIG		,27
        dbs 'No space left on device'				,ENOSPC		,28
        dbs 'Illegal seek'					,ESPIPE		,29
        dbs 'Read-only file system'				,EROFS		,30
        dbs 'Too many links'					,EMLINK		,31
        dbs 'Broken pipe'					,EPIPE		,32
        dbs 'Math argument out of domain of func'		,EDOM		,33
        dbs 'Math result not representable'			,ERANGE		,34
        dbs 'Resource deadlock would occur'			,EDEADLK	,35
        dbs 'File name too long'				,ENAMETOOLONG	,36
        dbs 'No record locks available'				,ENOLCK		,37
        dbs 'Function not implemented'				,ENOSYS		,38
        dbs 'Directory not empty'				,ENOTEMPTY	,39
        dbs 'Too many symbolic links encountered'		,ELOOP		,40
	dbs 'Operation would block'				,EWOULDBLOCK	,EAGAIN ;11
        dbs 'No message of desired type'			,ENOMSG		,42
        dbs 'Identifier removed'				,EIDRM		,43
        dbs 'Channel number out of range'			,ECHRNG		,44
        dbs 'Level 2 not synchronized'				,EL2NSYNC	,45
        dbs 'Level 3 halted'					,EL3HLT		,46
        dbs 'Level 3 reset'					,EL3RST		,47
        dbs 'Link number out of range'				,ELNRNG		,48
        dbs 'Protocol driver not attached'			,EUNATCH	,49
        dbs 'No CSI structure available'			,ENOCSI		,50
        dbs 'Level 2 halted'					,EL2HLT		,51
        dbs 'Invalid exchange'					,EBADE		,52
        dbs 'Invalid request descriptor'			,EBADR		,53
        dbs 'Exchange full'					,EXFULL		,54
        dbs 'No anode'						,ENOANO		,55
        dbs 'Invalid request code'				,EBADRQC	,56
        dbs 'Invalid slot'					,EBADSLT	,57
	dbs 'Resource deadlock would occur'			,EDEADLOCK	,EDEADLK;35
        dbs 'Bad font file format'				,EBFONT		,59
        dbs 'Device not a stream'				,ENOSTR		,60
        dbs 'No data available'					,ENODATA	,61
        dbs 'Timer expired'					,ETIME		,62
        dbs 'Out of streams resources'				,ENOSR		,63
        dbs 'Machine is not on the network'			,ENONET		,64
        dbs 'Package not installed'				,ENOPKG		,65
        dbs 'Object is remote'					,EREMOTE	,66
        dbs 'Link has been severed'				,ENOLINK	,67
        dbs 'Advertise error'					,EADV		,68
        dbs 'Srmount error'					,ESRMNT		,69
        dbs 'Communication error on send'			,ECOMM		,70
        dbs 'Protocol error'					,EPROTO		,71
        dbs 'Multihop attempted'				,EMULTIHOP	,72
        dbs 'RFS specific error'				,EDOTDOT	,73
        dbs 'Not a data message'				,EBADMSG	,74
        dbs 'Value too large for defined data type'		,EOVERFLOW	,75
        dbs 'Name not unique on network'			,ENOTUNIQ	,76
        dbs 'File descriptor in bad state'			,EBADFD		,77
        dbs 'Remote address changed'				,EREMCHG	,78
        dbs 'Can not access a needed shared library'		,ELIBACC	,79
        dbs 'Accessing a corrupted shared library'		,ELIBBAD	,80
        dbs 'lib section in a.out corrupted'			,ELIBSCN	,81
        dbs 'Attempting to link in too many shared libraries'	,ELIBMAX	,82
        dbs 'Cannot exec a shared library directly'		,ELIBEXEC	,83
        dbs 'Illegal byte sequence'				,EILSEQ		,84
        dbs 'Interrupted system call should be restarted'	,ERESTART	,85
        dbs 'Streams pipe error'				,ESTRPIPE	,86
        dbs 'Too many users'					,EUSERS		,87
        dbs 'Socket operation on non-socket'			,ENOTSOCK	,88
        dbs 'Destination address required'			,EDESTADDRREQ	,89
        dbs 'Message too long'					,EMSGSIZE	,90
        dbs 'Protocol wrong type for socket'			,EPROTOTYPE	,91
        dbs 'Protocol not available'				,ENOPROTOOPT	,92
        dbs 'Protocol not supported'				,EPROTONOSUPPORT,93
        dbs 'Socket type not supported'				,ESOCKTNOSUPPORT,94
        dbs 'Operation not supported on transport endpoint'	,EOPNOTSUPP	,95
        dbs 'Protocol family not supported'			,EPFNOSUPPORT	,96
        dbs 'Address family not supported by protocol'		,EAFNOSUPPORT	,97
        dbs 'Address already in use'				,EADDRINUSE	,98
        dbs 'Cannot assign requested address'			,EADDRNOTAVAIL	,99
        dbs 'Network is down'					,ENETDOWN	,100
        dbs 'Network is unreachable'				,ENETUNREACH	,101
        dbs 'Network dropped connection because of reset'	,ENETRESET	,102
        dbs 'Software caused connection abort'			,ECONNABORTED	,103
        dbs 'Connection reset by peer'				,ECONNRESET	,104
        dbs 'No buffer space available'				,ENOBUFS	,105
        dbs 'Transport endpoint is already connected'		,EISCONN	,106
        dbs 'Transport endpoint is not connected'		,ENOTCONN	,107
        dbs 'Cannot send after transport endpoint shutdown'	,ESHUTDOWN	,108
        dbs 'Too many references: cannot splice'		,ETOOMANYREFS	,109
        dbs 'Connection timed out'				,ETIMEDOUT	,110
        dbs 'Connection refused'				,ECONNREFUSED	,111
        dbs 'Host is down'					,EHOSTDOWN	,112
        dbs 'No route to host'					,EHOSTUNREACH	,113
        dbs 'Operation already in progress'			,EALREADY	,114
        dbs 'Operation now in progress'				,EINPROGRESS	,115
        dbs 'Stale NFS file handle'				,ESTALE		,116
        dbs 'Structure needs cleaning'				,EUCLEAN	,117
        dbs 'Not a XENIX named type file'			,ENOTNAM	,118
        dbs 'No XENIX semaphores available'			,ENAVAIL	,119
        dbs 'Is a named type file'				,EISNAM		,120
        dbs 'Remote I/O error'					,EREMOTEIO	,121
        dbs 'Quota exceeded'					,EDQUOT		,122
        dbs 'No medium found'					,ENOMEDIUM	,123
        dbs 'Wrong medium type'					,EMEDIUMTYPE	,124
%ifdef __I386_ERRNO_X
	dbs 'Errnum 125'					,E125		,125;?; not def`d by kernel source
	dbs 'Errnum 126'					,E126		,126;?; not def`d by kernel source
	dbs 'Command unknown'					,ENOTKNOWN	,127;empiric, not def`d by kernel source
%endif
m.ro:	dw e.ro-a.ro+1
a.ro:	db 10,': Unknown Error'
e.ro:	db 10
                align 4
%endmacro

;- ertdsp, macro 0
;-	compiles reference table of disps re <rn> to errormessages
;- 	<rn> label, base of disp's to msg(no.*2) strings
;-	<rm> double, top message no.
%macro ertdsp 0.nolist
	align 4
	dw e0-rn
rn:
        dw e1-rn,e2-rn,e3-rn,e4-rn
        dw e5-rn,e6-rn,e7-rn,e8-rn
        dw e9-rn,e10-rn,e11-rn,e12-rn
        dw e13-rn,e14-rn,e15-rn,e16-rn
        dw e17-rn,e18-rn,e19-rn,e20-rn
        dw e21-rn,e22-rn,e23-rn,e24-rn
        dw e25-rn,e26-rn,e27-rn,e28-rn
        dw e29-rn,e30-rn,e31-rn,e32-rn
        dw e33-rn,e34-rn,e35-rn,e36-rn
        dw e37-rn,e38-rn,e39-rn,e40-rn
        dw e41-rn,e42-rn,e43-rn,e44-rn
        dw e45-rn,e46-rn,e47-rn,e48-rn
        dw e49-rn,e50-rn,e51-rn,e52-rn
        dw e53-rn,e54-rn,e55-rn,e56-rn
        dw e57-rn,e58-rn,e59-rn,e60-rn
        dw e61-rn,e62-rn,e63-rn,e64-rn
        dw e65-rn,e66-rn,e67-rn,e68-rn
        dw e69-rn,e70-rn,e71-rn,e72-rn
        dw e73-rn,e74-rn,e75-rn,e76-rn
        dw e77-rn,e78-rn,e79-rn,e80-rn
        dw e81-rn,e82-rn,e83-rn,e84-rn
        dw e85-rn,e86-rn,e87-rn,e88-rn
        dw e89-rn,e90-rn,e91-rn,e92-rn
        dw e93-rn,e94-rn,e95-rn,e96-rn
        dw e97-rn,e98-rn,e99-rn,e100-rn
        dw e101-rn,e102-rn,e103-rn,e104-rn
        dw e105-rn,e106-rn,e107-rn,e108-rn
        dw e109-rn,e110-rn,e111-rn,e112-rn
        dw e113-rn,e114-rn,e115-rn,e116-rn
        dw e117-rn,e118-rn,e119-rn,e120-rn
        dw e121-rn,e122-rn,e123-rn,e124-rn
%ifdef __I386_ERRNO_X
	dw e125-rn,e126-rn,e127-rn
%endif
	dw m.ro-rn	; ernum range overflow msg

	align 4

;%error "mn last ERRnum"
rm:	dd mn		; last valid ernum - false: in fact, this is last+1 - re <sigdsp>, below!
%endmacro

;-
;- label: ermstg 0
;-	subroutine, pic, find error message
;-	no regs changed if not applicable
;- i:	eax	(assumed) ernum
;- o:	eax	eax
;-	ecx	ecx or message text after leading <nl>
;-	edx	edx or text count, trailing <nl> inclusive
%macro ermstg 0.nolist
%00:
%ifdef __PUSHPOP_M
    push eax,ecx,edx	; with multi-pop macro from "pushpop.mac"
%else
    push eax
    push ecx
    push edx
%endif
    neg eax
    cmp eax,4095
    ja .r		;?;not an error
    call .b
.b:
    pop edx
    cmp eax,0x80000000
    jz .n		;?;special
    mov ecx,dword[edx+rm-.b]
    cmp eax,ecx		; upper bound of errno-s
    jc .a 		; within range
    mov eax,ecx		; msg ovf message
.n:
    shl eax,1
    sar eax,1
.a:
    lea ecx,[edx+rn-.b]	; base of disp table
    movsx eax,word[byte ecx+eax*2-2]; msg-<rn>
    add ecx,eax
    movsx edx,word[ecx]
    add ecx,byte 3	; advance past leading <nl>
    dec edx		; adjust & check length
    jng .r		;?; ptr/len not valid
    mov [esp],edx	; length
    mov [esp+4],ecx	; address
.r:
%ifdef __PUSHPOP_M
    pop regl
%else
    pop edx
    pop ecx
    pop eax		; zero or -ve length (which shouldn't happen)
%endif
    ret
%endm
;-
;-================================================================;
;- signals
;- 

;-
;- sbs, macro 1-3
;-	label & msg string assembly, errnum defn
;-	compiles list of word counted message strings,
;-	%define-s S(signal names) as message strings,
;-	%assign-s M(signal names) as -ve error numbers,
;-	%assign-s B(signal names) as bit-values.
;-	<mn> %define-d to top msg.no. (used in "debug.inc")
;-	<nr> incremented by one, after label/stg defn.
%macro sbs 1-3;.nolist
    eno s
        dw %%l2-%%l1+1
%%l1:   db 10,%{3}
%%l2:	db 10
    align 2
%if %{0} = 3
%ifnum %{2}
%define SSIG%{1} %{3}
%assign MSIG%{1} -%{2}
%assign BSIG%{1} 1<<%{2}
%endif
%endif
%assign sn nr
%assign nr nr+1
%endmacro

;-
;- signal messages strings
;- two macros to be used in conjunction:
;-
;- sigstg, macro 0
;-	compiles labels & signalmessages, re macro <sbs>.
;- 	<rs> label, base of msg strings
;-	<m.rs>,<a.rs>,<e.rs> internal labels, and
;-	<s1>..<s31> refer to message texts, rsp.
%macro sigstg 0.nolist
	align 4
%assign nr 0
%ifndef EXT
%undef VER
%endif
%ifndef VER
%error "default VERsion"
%define VER 00
%define EXT 00
%endif
%ifndef DATE
%error "default DATE"
%define DATE 991231
%endif
    sbs OK, 0, {'sm',(VER/10)|48,(VER-VER/10*10)|48,'.',(EXT/10)|48,(EXT-EXT/10*10)|48,'-',DATE,' (C) 2000 hp Berlin, GNU GPL'}
st:
;- linux signal number defn's
    sbs HUP	, 1,"Hangup"			;:1:(cannot be caught nor ignored)
    sbs INT	, 2,"Terminal Interrupt"	;:1: ctr/"c"
    sbs QUIT	, 3,"Quit"			;:2: alt-r/ctr/"\"
    sbs ILL	, 4,"Illegal Instruction"	;:2:
    sbs TRAP	, 5,"Trace/Breakpoint Trap"	;:2:
    sbs ABRT	, 6,"Aborted"			;:2:
    sbs BUS	, 7,"Bus Error"			;:2: Access to an undefined portion of a memory object.
    sbs FPE	, 8,"Arithmetic Fault"		;:2: div-0
    sbs KILL	, 9,"Killed"			;:1:(cannot be caught nor ignored)
    sbs USR1	,10,"User Signal 1"		;:1:
    sbs SEGV	,11,"Invalid Memory Reference"	;:2:
    sbs USR2	,12,"User Signal 2"		;:1:
    sbs PIPE	,13,"Broken Pipe"		;:1: Write on a pipe with no one to read it.
    sbs ALRM	,14,"Alarm Clock"		;:1:
    sbs TERM	,15,"Terminated"		;:1:
    sbs STKFLT	,16,"Stack Fault"
    sbs CHLD	,17,"Child exited"		;:3:
    sbs CONT	,18,"Continued"			;:5: restarts, but console chan. lost
    sbs STOP	,19,"Halted"			;:4: ctr/"z", inactivate job (cannot be caught or ignored)
    sbs TSTP	,20,"Halt by Terminal Stop Signal"	 ;:4:
    sbs TTIN	,21,"Background Process attempting Read" ;:4:
    sbs TTOU	,22,"Background Process attempting Write";:4:
    sbs URG	,23,"Urgent I/O at a Socket"	;:3:
    sbs XCPU	,24,"CPU Time Limit exceeded"	;:2:
    sbs XFSZ	,25,"File Size Limit exceeded"	;:2:
    sbs VTALRM	,26,"Virtual Timer expired"	;:1:
    sbs PROF	,27,"Profiling Timer expired"	;:1:
    sbs WINCH	,28,"Window changed"		;	- doesn't appear to be sent - how to obtain? -
    sbs IO	,29,"I/O possible"
    sbs PWR	,30,"Power Failure"
    sbs	UNUSED	,31,"signal unused"

; multiply defined messages:
%define  SIGPOLL 	SIGIO
%define  SIGIOT		SIGABRT
%define  SIGLOST	SIGIO			;29,"Resource lost"
%ifdef __N98E; bugs-fixed nasm version:
; nasm..e required, to assigning variables by _values_
%xdefine SSIGPOLL 	SSIGIO
%xdefine BSIGPOLL 	BSIGIO
%xdefine MSIGPOLL 	MSIGIO
%xdefine SSIGIOT	SSIGABRT
%xdefine BSIGIOT 	BSIGABRT
%xdefine MSIGIOT 	MSIGABRT
%xdefine SSIGLOST 	SSIGIO
%xdefine BSIGLOST 	BSIGIO
%xdefine MSIGLOST 	MSIGIO
%else ;..else might not always be error free:
%define SSIGPOLL 	SSIGIO
%assign BSIGPOLL 	BSIGIO
%assign MSIGPOLL 	MSIGIO
%define SSIGIOT		SSIGABRT
%define BSIGIOT 	BSIGABRT
%define MSIGIOT 	MSIGABRT
%define SSIGLOST 	SSIGIO
%assign BSIGLOST 	BSIGIO
%assign MSIGLOST 	MSIGIO
%endif
m.rs:	dw e.rs-a.rs+1
a.rs:	db 10,': rt-signal or unknown'
e.rs:	db 10
                align 4
%endm
;- signals
;-	default actions are as follows:
;-	:1:
;-		Abnormal termination of the process. The process is terminated
;-		with all the consequences of _exit() except that the status
;-		made available to wait() and waitpid() indicates abnormal
;-		termination by the specified signal.
;-	:2:
;-		Abnormal termination of the process. Additionally,
;-		implementation-dependent abnormal termination actions, such as
;-		creation of a core file, may occur.
;-	:3:
;-		Ignore the signal.
;-	:4:
;-		Stop the process.
;-	:5:
;-		Continue the process, if it is stopped; otherwise ignore the
;-		signal.
;-

;-
;- sigdsp, macro 0
;-	compiles reference table of disps re <sr> to signal messages
;-	macro <ermstg> can be used to reference signal names strings
;- 	<sr> label, base of disp's to msg(no.*2) strings
;-	<sm> double, top message no.
%macro sigdsp 0.nolist
	align 4
	dw s0-sr
sr:
        dw s1-sr,s2-sr,s3-sr,s4-sr
        dw s5-sr,s6-sr,s7-sr,s8-sr
        dw s9-sr,s10-sr,s11-sr,s12-sr
        dw s13-sr,s14-sr,s15-sr,s16-sr
        dw s17-sr,s18-sr,s19-sr,s20-sr
        dw s21-sr,s22-sr,s23-sr,s24-sr
        dw s25-sr,s26-sr,s27-sr,s28-sr
        dw s29-sr,s30-sr,s31-sr
	dw m.rs-sr	; range overflow msg

	align 4
;same macro, but differently compiling:
;%error "sn last SIGnal";which for ernum assembles to last+1 number - why ???
sm:	dd sn		; last valid num
%endmacro
;-
%endif ;__I386_ERRNO
;-
;-================================================================;
;- errno.inc <eof>
