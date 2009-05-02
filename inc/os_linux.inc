; Copyright (C) 1999-2006 Konstantin Boldyshev <konst@linuxassembly.org>
;
; $Id: os_linux.inc,v 1.27 2006/02/18 10:09:17 konst Exp $
;
; file          : os_linux.inc
; created       : 08-Feb-2000
; modified      : 09-Feb-2006
; version       : 0.18
; assembler     : nasm 0.98
; description   : Linux kernel (2.0+) constants and structures
; author        : Konstantin Boldyshev <konst@linuxassembly.org>
; comment       : included from system.inc

%ifndef __SYSTEM_INC
%error "this file must be included from system.inc !"
%endif

%ifndef __LINUX_INC
%define __LINUX_INC

%macro	DO_SYSCALL 0
	int	0x80
%endmacro

%macro	SYSCALL_GATE 0
%endmacro

;
;linux/posix_types.h
;

%assign	FD_SETSIZE	1024

struc fd_set
	U32	FD_SETSIZE / 32
endstruc

;
;
;

%assign MAP_GROWSDOWN	0x0100
%assign MAP_DENYWRITE	0x0800
%assign MAP_EXECUTABLE	0x1000
%assign MAP_LOCKED	0x2000
%assign MAP_NORESERVE	0x4000

;
;linux/reboot.h
;

%assign	LINUX_REBOOT_MAGIC1	0xfee1dead
%assign	LINUX_REBOOT_MAGIC2	0x28121969
%assign	LINUX_REBOOT_MAGIC2A	85072278
%assign	LINUX_REBOOT_MAGIC2B	369367448

%assign	LINUX_REBOOT_CMD_RESTART	0x01234567	;Restart system using default command and mode.
%assign	LINUX_REBOOT_CMD_HALT		0xCDEF0123	;Stop OS and give system control to ROM monitor, if any.
%assign	LINUX_REBOOT_CMD_CAD_ON		0x89ABCDEF	;Ctrl-Alt-Del sequence causes RESTART command.
%assign	LINUX_REBOOT_CMD_CAD_OFF	0x00000000	;Ctrl-Alt-Del sequence sends SIGINT to init task.
%assign	LINUX_REBOOT_CMD_POWER_OFF	0x4321FEDC	;Stop OS and remove all power from system, if possible.
%assign	LINUX_REBOOT_CMD_RESTART2	0xA1B2C3D4	;Restart system using given command string.

%assign RB_AUTOBOOT	LINUX_REBOOT_CMD_RESTART
%assign RB_HALT		LINUX_REBOOT_CMD_HALT
%assign RB_ENABLE_CAD	LINUX_REBOOT_CMD_CAD_ON
%assign RB_DISABLE_CAD	LINUX_REBOOT_CMD_CAD_OFF
%assign RB_POWEROFF	LINUX_REBOOT_CMD_POWER_OFF

;
;linux/kd.h
;

%assign KDGKBTYPE	0x4B33	;get keyboard type
%assign KB_84		0x01
%assign KB_101		0x02	;this is what we always answer
%assign KB_OTHER	0x03

%assign	KIOCSOUND	0x4B2F	;start sound generation (0 for off)
%assign	KDMKTONE	0x4B30	;generate tone
%assign KDFONTOP	0x4B72	;font operations ioctl 

%assign KD_FONT_OP_SET		0	;Set font 
%assign KD_FONT_OP_GET		1	;Get font 
%assign KD_FONT_OP_SET_DEFAULT	2	;Set font to default, data points to name 
%assign KD_FONT_OP_COPY		3	;Copy from another console 

struc console_font_op
.op		UINT	1
.flags		UINT	1	;should always be 0?
.width		UINT	1
.height		UINT	1
.charcount	UINT	1
.data		DWORD	1	;pointer to unsigned char
endstruc

struc	raw_font_type
.fontdata	UCHAR	16384
endstruc

;
;linux/cdrom.h
;

%assign CDROMPAUSE		0x5301	;Pause Audio Operation
%assign CDROMRESUME		0x5302	;Resume paused Audio Operation
%assign CDROMPLAYMSF		0x5303	;Play Audio MSF (struct cdrom_msf)
%assign CDROMPLAYTRKIND		0x5304	;Play Audio Track/index (struct cdrom_ti)
%assign CDROMREADTOCHDR		0x5305	;Read TOC header (struct cdrom_tochdr)
%assign CDROMREADTOCENTRY	0x5306	;Read TOC entry (struct cdrom_tocentry)
%assign CDROMSTOP		0x5307	;Stop the cdrom drive
%assign CDROMSTART		0x5308	;Start the cdrom drive
%assign CDROMEJECT		0x5309	;Ejects the cdrom media
%assign CDROMVOLCTRL		0x530a	;Control output volume (struct cdrom_volctrl)
%assign CDROMSUBCHNL		0x530b	;Read subchannel data (struct cdrom_subchnl)
%assign CDROMREADMODE2		0x530c	;Read CDROM mode 2 data (2336 Bytes) (struct cdrom_read)
%assign CDROMREADMODE1		0x530d	;Read CDROM mode 1 data (2048 Bytes) (struct cdrom_read)
%assign CDROMREADAUDIO		0x530e	;(struct cdrom_read_audio)
%assign CDROMEJECT_SW		0x530f	;enable(1)/disable(0) auto-ejecting
%assign CDROMMULTISESSION	0x5310	;Obtain the start-of-last-session address of multi session disks (struct cdrom_multisession)
%assign CDROM_GET_MCN		0x5311	;Obtain the "Universal Product Code" if available (struct cdrom_mcn)
%assign CDROM_GET_UPC		CDROM_GET_MCN	;This one is depricated, but here anyway for compatability
%assign CDROMRESET		0x5312	;hard-reset the drive
%assign CDROMVOLREAD		0x5313	;Get the drive's volume setting (struct cdrom_volctrl)
%assign CDROMREADRAW		0x5314	;read data in raw mode (2352 Bytes)
%assign CDROMCLOSETRAY	0x5319

;
;linux/vt.h
;

%assign VT_ACTIVATE	0x5606	;make vt active
%assign VT_WAITACTIVE	0x5607	;wait for vt active
%assign VT_DISALLOCATE	0x5608	;free memory associated to vt

%define VT_GETMODE	0x5601	;get mode of active vt
%define VT_SETMODE	0x5602	;set mode of active vt

struc vt_mode
.mode		CHAR	1	;vt mode
.waitv		SHORT	1	;if set, hang on writes if not active
.relsig		SHORT	1	;signal to raise on release req
.acqsig		SHORT	1	;signal to raise on acquisition
.frsig		SHORT	1	;unused (set to 0)
endstruc

;
;asm/termbits.h
;

; c_cc characters
%assign VINTR	0
%assign VQUIT	1
%assign VERASE	2
%assign VKILL	3
%assign VEOF	4
%assign VTIME	5
%assign VMIN	6
%assign VSWTC	7
%assign VSTART	8
%assign VSTOP	9
%assign VSUSP	10
%assign VEOL	11
%assign VREPRINT 12
%assign VDISCARD 13
%assign VWERASE	14
%assign VLNEXT	15
%assign VEOL2	16

; c_iflag bits
%assign IGNBRK	0000001q
%assign BRKINT	0000002q
%assign IGNPAR	0000004q
%assign PARMRK	0000010q
%assign INPCK	0000020q
%assign ISTRIP	0000040q
%assign INLCR	0000100q
%assign IGNCR	0000200q
%assign ICRNL	0000400q
%assign IUCLC	0001000q
%assign IXON	0002000q
%assign IXANY	0004000q
%assign IXOFF	0010000q
%assign IMAXBEL	0020000q

; c_oflag bits
%assign OPOST	0000001q
%assign OLCUC	0000002q
%assign ONLCR	0000004q
%assign OCRNL	0000010q
%assign ONOCR	0000020q
%assign ONLRET	0000040q
%assign OFILL	0000100q
%assign OFDEL	0000200q
%assign NLDLY	0000400q
%assign   NL0	0000000q
%assign   NL1	0000400q
%assign CRDLY	0003000q
%assign   CR0	0000000q
%assign   CR1	0001000q
%assign   CR2	0002000q
%assign   CR3	0003000q
%assign TABDLY	0014000q
%assign   TAB0	0000000q
%assign   TAB1	0004000q
%assign   TAB2	0010000q
%assign   TAB3	0014000q
%assign   XTABS	0014000q
%assign BSDLY	0020000q
%assign   BS0	0000000q
%assign   BS1	0020000q
%assign VTDLY	0040000q
%assign   VT0	0000000q
%assign   VT1	0040000q
%assign FFDLY	0100000q
%assign   FF0	0000000q
%assign   FF1	0100000q

; c_cflag bit meaning
%assign CBAUD	0010017q
%assign  B0	0000000q	;hang up
%assign  B50	0000001q
%assign  B75	0000002q
%assign  B110	0000003q
%assign  B134	0000004q
%assign  B150	0000005q
%assign  B200	0000006q
%assign  B300	0000007q
%assign  B600	0000010q
%assign  B1200	0000011q
%assign  B1800	0000012q
%assign  B2400	0000013q
%assign  B4800	0000014q
%assign  B9600	0000015q
%assign  B19200	0000016q
%assign  B38400	0000017q
%assign EXTA	B19200
%assign EXTB	B38400
%assign CSIZE	0000060q
%assign   CS5	0000000q
%assign   CS6	0000020q
%assign   CS7	0000040q
%assign   CS8	0000060q
%assign CSTOPB	0000100q
%assign CREAD	0000200q
%assign PARENB	0000400q
%assign PARODD	0001000q
%assign HUPCL	0002000q
%assign CLOCAL	0004000q
%assign CBAUDEX 0010000q
%assign    B57600 0010001q
%assign   B115200 0010002q
%assign   B230400 0010003q
%assign   B460800 0010004q
%assign   B500000 0010005q
%assign   B576000 0010006q
%assign   B921600 0010007q
%assign  B1000000 0010010q
%assign  B1152000 0010011q
%assign  B1500000 0010012q
%assign  B2000000 0010013q
%assign  B2500000 0010014q
%assign  B3000000 0010015q
%assign  B3500000 0010016q
%assign  B4000000 0010017q
%assign CIBAUD	  002003600000q	;input baud rate (not used)
%assign CMSPAR	  010000000000q	;mark or space (stick) parity
%assign CRTSCTS	  020000000000q	;flow control

; c_lflag bits
%assign ISIG	0000001q
%assign ICANON	0000002q
%assign XCASE	0000004q
%assign ECHO	0000010q
%assign ECHOE	0000020q
%assign ECHOK	0000040q
%assign ECHONL	0000100q
%assign NOFLSH	0000200q
%assign TOSTOP	0000400q
%assign ECHOCTL	0001000q
%assign ECHOPRT	0002000q
%assign ECHOKE	0004000q
%assign FLUSHO	0010000q
%assign PENDIN	0040000q
%assign IEXTEN	0100000q

; tcflow() and TCXONC use these
%assign	TCOOFF		0
%assign	TCOON		1
%assign	TCIOFF		2
%assign	TCION		3

; tcflush() and TCFLSH use these
%assign	TCIFLUSH	0
%assign	TCOFLUSH	1
%assign	TCIOFLUSH	2

; tcsetattr uses these
%assign	TCSANOW		0
%assign	TCSADRAIN	1
%assign	TCSAFLUSH	2

%assign NCCS 19
struc termios
.c_iflag	UINT	1	;input mode flags
.c_oflag	UINT	1	;output mode flags
.c_cflag	UINT	1	;control mode flags
.c_lflag	UINT	1	;local mode flags
.c_line		UCHAR	1	;line discipline
.c_cc		UCHAR	NCCS	;control characters
endstruc

;
;asm/ioctls.h
;

;0x54 is just a magic number to make these relatively unique ('T')

%assign TCGETS		0x5401
%assign TCSETS		0x5402
%assign TCSETSW		0x5403
%assign TCSETSF		0x5404
%assign TCGETA		0x5405
%assign TCSETA		0x5406
%assign TCSETAW		0x5407
%assign TCSETAF		0x5408
%assign TCSBRK		0x5409
%assign TCXONC		0x540A
%assign TCFLSH		0x540B
%assign TIOCEXCL	0x540C
%assign TIOCNXCL	0x540D
%assign TIOCSCTTY	0x540E
%assign TIOCGPGRP	0x540F
%assign TIOCSPGRP	0x5410
%assign TIOCOUTQ	0x5411
%assign TIOCSTI		0x5412
%assign TIOCGWINSZ	0x5413
%assign TIOCSWINSZ	0x5414
%assign TIOCMGET	0x5415
%assign TIOCMBIS	0x5416
%assign TIOCMBIC	0x5417
%assign TIOCMSET	0x5418
%assign TIOCGSOFTCAR	0x5419
%assign TIOCSSOFTCAR	0x541A
%assign FIONREAD	0x541B
%assign TIOCINQ		FIONREAD
%assign TIOCLINUX	0x541C
%assign TIOCCONS	0x541D
%assign TIOCGSERIAL	0x541E
%assign TIOCSSERIAL	0x541F
%assign TIOCPKT		0x5420
%assign FIONBIO		0x5421
%assign TIOCNOTTY	0x5422
%assign TIOCSETD	0x5423
%assign TIOCGETD	0x5424
%assign TCSBRKP		0x5425	;Needed for POSIX tcsendbreak()
%assign TIOCTTYGSTRUCT	0x5426  ;For debugging only
%assign TIOCSBRK	0x5427  ;BSD compatibility
%assign TIOCCBRK	0x5428  ;BSD compatibility
%assign TIOCGSID	0x5429  ;Return the session ID of FD

;
;asm/stat.h
;

struc Stat			;guess why uppercase S?
%if __SYSCALL__=__S_KERNEL__
.st_dev		USHORT	1
.__pad1		USHORT	1
.st_ino		ULONG	1
.st_mode	USHORT	1
.st_nlink	USHORT	1
.st_uid		USHORT	1
.st_gid		USHORT	1
.st_rdev	USHORT	1
.__pad2		USHORT	1
.st_size	ULONG	1
.st_blksize	ULONG	1
.st_blocks	ULONG	1
.st_atime	ULONG	1
.__unused1	ULONG	1
.st_mtime	ULONG	1
.__unused2	ULONG	1
.st_ctime	ULONG	1
.__unused3	ULONG	1
.__unused4	ULONG	1
.__unused5	ULONG	1
%elif __SYSCALL__=__S_LIBC__
.st_dev		ULONG	2
.__pad1		USHORT	1
.st_ino		ULONG	1
.st_mode	UINT	1
.st_nlink	UINT	1
.st_uid		UINT	1
.st_gid		UINT	1
.st_rdev	ULONG	2
.__pad2		USHORT	1
.st_size	ULONG	1
.st_blksize	ULONG	1
.st_blocks	ULONG	1
.st_atime	ULONG	1
.__unused1	ULONG	1
.st_mtime	ULONG	1
.__unused2	ULONG	1
.st_ctime	ULONG	1
.__unused3	ULONG	1
%endif
endstruc

struc __old_kernel_stat
.st_dev		USHORT	1
.st_ino		USHORT	1
.st_mode	USHORT	1
.st_nlink	USHORT	1
.st_uid		USHORT	1
.st_gid		USHORT	1
.st_rdev	USHORT	1
.st_size	ULONG	1
.st_atime	ULONG	1
.st_mtime	ULONG	1
.st_ctime	ULONG	1
endstruc

;
;asm/signal.h
;

%assign SA_NOCLDSTOP	0x00000001
%assign SA_NOCLDWAIT	0x00000002
%assign SA_SIGINFO	0x00000004
%assign SA_ONSTACK	0x08000000
%assign SA_RESTART	0x10000000
%assign SA_NODEFER	0x40000000
%assign SA_RESETHAND	0x80000000
%assign SA_RESTORER	0x04000000

%assign SA_NOMASK	SA_NODEFER
%assign SA_ONESHOT	SA_RESETHAND

struc sigset_t
		U32	_NSIG / 32
endstruc

struc Sigaction
.sa_handler	ULONG	1
%if __SYSCALL__=__S_KERNEL__
.sa_flags	ULONG	1
.sa_restorer	ULONG	1
.sa_mask	resb	sigset_t_size
%elif __SYSCALL__=__S_LIBC__
.sa_sigaction	ULONG	1
.sa_mask	resb	sigset_t_size
.sa_flags	ULONG	1
.sa_restorer	ULONG	1
%endif
endstruc

;
;sys/dirent.h
;

struc dirent
%if __SYSCALL__=__S_KERNEL__
.d_ino		ULONG	1
.d_off		ULONG	1
.d_reclen	USHORT	1
.d_name		CHAR	256
%elif __SYSCALL__=__S_LIBC__
.d_ino		ULONG	2
.d_off		ULONG	2
.d_reclen	USHORT	1
.d_type		UCHAR	1
.d_name		CHAR	256
%endif
endstruc


;
;linux/fb.h
;

; ioctl defs for fb

%assign FBIOGET_VSCREENINFO	0x4600	
%assign FBIOPUT_VSCREENINFO	0x4601	
%assign	FBIOGET_FSCREENINFO	0x4602
%assign	FBIOGETCMAP		0x4604
%assign	FBIOPUTCMAP		0x4605
%assign FBIOPAN_DISPLAY		0X4606

; activate flags for ioctl on var->activate

%assign	FB_ACTIVATE_NOW		0
%assign	FB_ACTIVATE_NXTOPEN	1
%assign	FB_ACTIVATE_TEST	2
%assign	FB_ACTIVATE_MASK	15
%assign	FB_ACTIVATE_VBL		16	;activate changes on next VBL - coool
%assign	FB_CHANGE_CMAP_VBL	32
%assign	FB_ACTIVATE_ALL		64

struc fb_fix
.id		CHAR	16
.smem_start	ULONG	1
.smem_len	U32	1
.type		U32	1
.type_aux	U32	1
.visual		U32	1
.xpanstep	U16	1
.ypanstep	U16	1
.ywrapstep	U16	1
.line_length	U32	1
.mmio_start	ULONG	1
.mmio_len	U32	1
.accel		U32	1
.reserved	U16	3
endstruc

struc fb_bitfield
.offset		U32	1
.length		U32	1
.msb_right	U32	1
endstruc
	
struc fb_cmap
.start		U32	1
.len		U32	1
.r_ptr		U32	1
.g_ptr		U32	1
.b_ptr		U32	1
.t_ptr		U32	1
endstruc

struc fb_var
.xres		U32	1
.yres		U32	1
.xres_virtual	U32	1
.yres_virtual	U32	1
.xoffset	U32	1
.yoffset	U32	1
		
.bits_per_pixel	U32	1
.grayscale	U32	1

;; fixme! this is a hack
;; dunno how to nest structure defs in NASM
.red_offset	U32	1
.red_length	U32	1
.red_msb_right	U32	1
.green_offset	U32	1
.green_length	U32	1
.green_msb_right	U32	1
.blue_offset	U32	1
.blue_length	U32	1
.blue_msb_right	U32	1
.transp_offset	U32	1
.transp_length	U32	1
.transp_msb_right	U32	1
	
.nonstd		U32	1
.activate	U32	1
.height		U32	1
.width		U32	1

.accel_flags	U32	1

.pixclock	U32	1
.left_margin	U32	1
.right_margin	U32	1
.upper_margin	U32	1
.lower_margin	U32	1
.hsync_len	U32	1
.vsync_len	U32	1
.sync		U32	1
.vmode		U32	1
.reserved	U32	6																							
	
endstruc

; struct fb_vblank
struc fb_vblank
  .flags           resd 1    ; FB_VBLANK flags
  .count           resd 1    ; counter of retraces since boot
  .vcount          resd 1    ; current scanline position
  .hcount          resd 1    ; current scandot position
  .reserved        resd 4    ; reserved for future compatibility
endstruc    ; 32 bytes

%assign FB_VBLANK_VBLANKING 0x001   ; currently in a vertical blank
%assign FB_VBLANK_HBLANKING 0x002   ; currently in a horizontal blank
%assign FB_VBLANK_HAVE_VBLANK 0x004 ; vertical blanks can be detected
%assign FB_VBLANK_HAVE_HBLANK 0x008 ; horizontal blanks can be detected
%assign FB_VBLANK_HAVE_COUNT 0x010  ; global retrace counter is available
%assign FB_VBLANK_HAVE_VCOUNT 0x020 ; the vcount field is valid
%assign FB_VBLANK_HAVE_HCOUNT 0x040 ; the hcount field is valid
%assign FB_VBLANK_VSYNCING 0x080    ; currently in a vsync
%assign FB_VBLANK_HAVE_VSYNC 0x100  ; vertical syncs can be detected


;
;linux/time.h
;

%assign	ITIMER_REAL	0
%assign	ITIMER_VIRTUAL	1
%assign	ITIMER_PROF	2

struc itimerval
.it_interval_sec:	ULONG	1
.it_interval_usec:	ULONG	1
.it_value_sec:		ULONG	1
.it_value_usec:		ULONG	1
endstruc

struc itimerspec
.it_interval_sec:	ULONG	1
.it_interval_nsec:	ULONG	1
.it_value_sec:		ULONG	1
.it_value_nsec:		ULONG	1
endstruc

;
;sys/socket.h
;

%assign	SOL_SOCKET	1

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
%assign SO_REUSEPORT	15
%assign SO_PASSCRED	16
%assign SO_PEERCRED	17
%assign SO_RCVLOWAT	18
%assign SO_SNDLOWAT	19
%assign SO_RCVTIMEO	20
%assign SO_SNDTIMEO	21

;
;sys/vfs.h
;

struc Statfs
.f_type		LONG	1	;fs type
.f_bsize	LONG	1	;optimal transfer block size
.f_blocks	LONG	1	;total data blocks
.f_bfree	LONG	1	;free blocks
.f_bavail	LONG	1	;free blocks avail to non-superuser
.f_files	LONG	1	;total file nodes
.f_free		LONG	1	;free file nodes
.f_fsid		LONG	1	;fs id
.f_namelen	LONG	1	;maximum filename length
.f_reserv	LONG  	6	;reserved
endstruc

;
;asm/ptrace.h
;

struc pt_regs
.ebx	ULONG	1
.ecx	ULONG	1
.edx	ULONG	1
.esi	ULONG	1
.edi	ULONG	1
.ebp	ULONG	1
.eax	ULONG	1
%if __KERNEL__ = 20
.ds	USHORT	1
.__dsu	USHORT	1
.es	USHORT	1
.__esu	USHORT	1
.fs	USHORT	1
.__fsu	USHORT	1
.gs	USHORT	1
.__gsu	USHORT	1
%elif __KERNEL__ = 22
.xds	INT	1
.xes	INT	1
%endif
.orig_eax	ULONG	1
.eip		ULONG	1
%if __KERNEL__ = 20
.cs	USHORT	1
.__csu	USHORT	1
%elif __KERNEL__ = 22
.xcs	INT	1
%endif
.eflags	ULONG	1
.esp	ULONG	1
%if __KERNEL__ = 20
.ss	USHORT	1
.__ssu	USHORT	1
%elif __KERNEL__ = 22
.xss	INT	1
%endif
endstruc

;
;asm/unistd.h
;

%assign SYS_exit		1
%assign SYS_fork		2
%assign SYS_read		3
%assign SYS_write		4
%assign SYS_open		5
%assign SYS_close		6
%assign SYS_waitpid		7
%assign SYS_creat		8
%assign SYS_link		9
%assign SYS_unlink		10
%assign SYS_execve		11
%assign SYS_chdir		12
%assign SYS_time		13
%assign SYS_mknod		14
%assign SYS_chmod		15
%assign SYS_lchown		16
%assign SYS_break		17
%assign SYS_oldstat		18
%assign SYS_lseek		19
%assign SYS_getpid		20
%assign SYS_mount		21
%assign SYS_umount		22
%assign SYS_setuid		23
%assign SYS_getuid		24
%assign SYS_stime		25
%assign SYS_ptrace		26
%assign SYS_alarm		27
%assign SYS_oldfstat		28
%assign SYS_pause		29
%assign SYS_utime		30
%assign SYS_stty		31
%assign SYS_gtty		32
%assign SYS_access		33
%assign SYS_nice		34
%assign SYS_ftime		35
%assign SYS_sync		36
%assign SYS_kill		37
%assign SYS_rename		38
%assign SYS_mkdir		39
%assign SYS_rmdir		40
%assign SYS_dup			41
%assign SYS_pipe		42
%assign SYS_times		43
%assign SYS_prof		44
%assign SYS_brk			45
%assign SYS_setgid		46
%assign SYS_getgid		47
%assign SYS_signal		48
%assign SYS_geteuid		49
%assign SYS_getegid		50
%assign SYS_acct		51
%assign SYS_umount2		52
%assign SYS_lock		53
%assign SYS_ioctl		54
%assign SYS_fcntl		55
%assign SYS_mpx			56
%assign SYS_setpgid		57
%assign SYS_ulimit		58
%assign SYS_oldolduname		59
%assign SYS_umask		60
%assign SYS_chroot		61
%assign SYS_ustat		62
%assign SYS_dup2		63
%assign SYS_getppid		64
%assign SYS_getpgrp		65
%assign SYS_setsid		66
%assign SYS_sigaction		67
%assign SYS_sgetmask		68
%assign SYS_ssetmask		69
%assign SYS_setreuid		70
%assign SYS_setregid		71
%assign SYS_sigsuspend		72
%assign SYS_sigpending		73
%assign SYS_sethostname		74
%assign SYS_setrlimit		75
%assign SYS_getrlimit		76
%assign SYS_getrusage		77
%assign SYS_gettimeofday	78
%assign SYS_settimeofday	79
%assign SYS_getgroups		80
%assign SYS_setgroups		81
%assign SYS_oldselect		82
%assign SYS_symlink		83
%assign SYS_oldlstat		84
%assign SYS_readlink		85
%assign SYS_uselib		86
%assign SYS_swapon		87
%assign SYS_reboot		88
%assign SYS_readdir		89
%assign SYS_mmap		90
%assign SYS_munmap		91
%assign SYS_truncate		92
%assign SYS_ftruncate		93
%assign SYS_fchmod		94
%assign SYS_fchown		95
%assign SYS_getpriority		96
%assign SYS_setpriority		97
%assign SYS_profil		98
%assign SYS_statfs		99
%assign SYS_fstatfs		100
%assign SYS_ioperm		101
%assign SYS_socketcall		102
%assign SYS_syslog		103
%assign SYS_setitimer		104
%assign SYS_getitimer		105
%assign SYS_stat		106
%assign SYS_lstat		107
%assign SYS_fstat		108
%assign SYS_olduname		109
%assign SYS_iopl		110
%assign SYS_vhangup		111
%assign SYS_idle		112
%assign SYS_vm86old		113
%assign SYS_wait4		114
%assign SYS_swapoff		115
%assign SYS_sysinfo		116
%assign SYS_ipc			117
%assign SYS_fsync		118
%assign SYS_sigreturn		119
%assign SYS_clone		120
%assign SYS_setdomainname	121
%assign SYS_uname		122
%assign SYS_modify_ldt		123
%assign SYS_adjtimex		124
%assign SYS_mprotect		125
%assign SYS_sigprocmask		126
%assign SYS_create_module	127
%assign SYS_init_module		128
%assign SYS_delete_module	129
%assign SYS_get_kernel_syms	130
%assign SYS_quotactl		131
%assign SYS_getpgid		132
%assign SYS_fchdir		133
%assign SYS_bdflush		134
%assign SYS_sysfs		135
%assign SYS_personality		136
%assign SYS_afs_syscall		137
%assign SYS_setfsuid		138
%assign SYS_setfsgid		139
%assign SYS_llseek		140
%assign SYS_getdents		141
%assign SYS_select		142
%assign SYS_flock		143
%assign SYS_msync		144
%assign SYS_readv		145
%assign SYS_writev		146
%assign SYS_getsid		147
%assign SYS_fdatasync		148
%assign SYS_sysctl		149
%assign SYS_mlock		150
%assign SYS_munlock		151
%assign SYS_mlockall		152
%assign SYS_munlockall		153
%assign SYS_sched_setparam	154
%assign SYS_sched_getparam	155
%assign SYS_sched_setscheduler	156
%assign SYS_sched_getscheduler	157
%assign SYS_sched_yield		158
%assign SYS_sched_get_priority_max	159
%assign SYS_sched_get_priority_min	160
%assign SYS_sched_rr_get_interval	161
%assign SYS_nanosleep		162
%assign SYS_mremap		163
%if __KERNEL__ >= 22
%assign SYS_setresuid		164
%assign SYS_getresuid		165
%assign SYS_vm86		166
%assign SYS_query_module	167
%assign SYS_poll		168
%assign SYS_nfsservctl		169
%assign SYS_setresgid		170
%assign SYS_getresgid		171
%assign SYS_prctl		172
%assign SYS_rt_sigreturn	173
%assign SYS_rt_sigaction	174
%assign SYS_rt_sigprocmask	175
%assign SYS_rt_sigpending	176
%assign SYS_rt_sigtimedwait	177
%assign SYS_rt_sigqueueinfo	178
%assign SYS_rt_sigsuspend	179
%assign SYS_pread		180
%assign SYS_pwrite		181
%assign SYS_chown		182
%assign SYS_getcwd		183
%assign SYS_capget		184
%assign SYS_capset		185
%assign SYS_sigaltstack		186
%assign SYS_sendfile		187
%else
%assign SYS_chown		SYS_lchown
%endif	;__KERNEL__ >= 22
%assign SYS_getpmsg		188
%assign SYS_putpmsg		189
%if __KERNEL__ >= 22
%assign SYS_vfork		190
%endif	;__KERNEL__ >= 22
%if __KERNEL__ >= 24
%assign SYS_ugetrlimit		191
%assign SYS_mmap2		192
%assign SYS_truncate64		193
%assign SYS_ftruncate64		194
%assign SYS_stat64		195
%assign SYS_lstat64		196
%assign SYS_fstat64		197
%assign SYS_lchown32		198
%assign SYS_getuid32		199
%assign SYS_getgid32		200
%assign SYS_geteuid32		201
%assign SYS_getegid32		202
%assign SYS_setreuid32		203
%assign SYS_setregid32		204
%assign SYS_getgroups32		205
%assign SYS_setgroups32		206
%assign SYS_fchown32		207
%assign SYS_setresuid32		208
%assign SYS_getresuid32		209
%assign SYS_setresgid32		210
%assign SYS_getresgid32		211
%assign SYS_chown32		212
%assign SYS_setuid32		213
%assign SYS_setgid32		214
%assign SYS_setfsuid32		215
%assign SYS_setfsgid32		216
%assign SYS_pivot_root		217
%assign SYS_mincore		218
%assign SYS_madvise		219
%assign SYS_getdents64		220
%assign SYS_fcntl64		221
%endif	;__KERNEL__ >= 24

;
;linux/net.h (socket calls)
;

%assign SYS_SOCKET	1
%assign SYS_BIND	2
%assign SYS_CONNECT	3
%assign SYS_LISTEN	4
%assign SYS_ACCEPT	5
%assign SYS_GETSOCKNAME	6
%assign SYS_GETPEERNAME	7
%assign SYS_SOCKETPAIR	8
%assign SYS_SEND	9
%assign SYS_RECV	10
%assign SYS_SENDTO	11
%assign SYS_RECVFROM	12
%assign SYS_SHUTDOWN	13
%assign SYS_SETSOCKOPT	14
%assign SYS_GETSOCKOPT	15
%assign SYS_SENDMSG	16
%assign SYS_RECVMSG	17

;
;linux/sockios.h
;

%assign SIOCADDRT	0x890B		;add routing table entry	
%assign SIOCDELRT	0x890C		;delete routing table entry	
%assign SIOCRTMSG	0x890D		;call to routing system	

%assign SIOCGIFNAME	0x8910		;get iface name		
%assign SIOCSIFLINK	0x8911		;set iface channel		
%assign SIOCGIFCONF	0x8912		;get iface list		
%assign SIOCGIFFLAGS	0x8913		;get flags			
%assign SIOCSIFFLAGS	0x8914		;set flags			
%assign SIOCGIFADDR	0x8915		;get PA address		
%assign SIOCSIFADDR	0x8916		;set PA address		
%assign SIOCGIFDSTADDR	0x8917		;get remote PA address	
%assign SIOCSIFDSTADDR	0x8918		;set remote PA address	
%assign SIOCGIFBRDADDR	0x8919		;get broadcast PA address	
%assign SIOCSIFBRDADDR	0x891a		;set broadcast PA address	
%assign SIOCGIFNETMASK	0x891b		;get network PA mask		
%assign SIOCSIFNETMASK	0x891c		;set network PA mask		
%assign SIOCGIFMETRIC	0x891d		;get metric			
%assign SIOCSIFMETRIC	0x891e		;set metric			
%assign SIOCGIFMEM	0x891f		;get memory address (BSD)	
%assign SIOCSIFMEM	0x8920		;set memory address (BSD)	
%assign SIOCGIFMTU	0x8921		;get MTU size			
%assign SIOCSIFMTU	0x8922		;set MTU size			
%assign SIOCSIFNAME	0x8923		;set interface name 
%assign	SIOCSIFHWADDR	0x8924		;set hardware address 	
%assign SIOCGIFENCAP	0x8925		;get/set encapsulations       
%assign SIOCSIFENCAP	0x8926		
%assign SIOCGIFHWADDR	0x8927		;Get hardware address		
%assign SIOCGIFSLAVE	0x8929		;Driver slaving support	
%assign SIOCSIFSLAVE	0x8930
%assign SIOCADDMULTI	0x8931		;Multicast address lists	
%assign SIOCDELMULTI	0x8932
%assign SIOCGIFINDEX	0x8933		;name -> if_index mapping	
%assign SIOGIFINDEX	SIOCGIFINDEX	;misprint compatibility :-)	
%assign SIOCSIFPFLAGS	0x8934		;set/get extended flags set	
%assign SIOCGIFPFLAGS	0x8935
%assign SIOCDIFADDR	0x8936		;delete PA address		
%assign	SIOCSIFHWBROADCAST	0x8937	;set hardware broadcast addr	
%assign SIOCGIFCOUNT	0x8938		;get number of devices 

;
;linux/module.h
;

%assign MOD_UNINITIALIZED	0
%assign MOD_RUNNING		1
%assign MOD_DELETED		2
%assign MOD_AUTOCLEAN		4
%assign MOD_VISITED  		8
%assign MOD_USED_ONCE		16
%assign MOD_JUST_FREED		32
%assign MOD_INITIALIZING	64

%assign QM_MODULES	1
%assign QM_DEPS		2
%assign QM_REFS		3
%assign QM_SYMBOLS	4
%assign QM_INFO		5

;
;linux/sysctl.h
;

%assign	CTL_MAXNAME 10

%assign	CTL_KERN	1	;General kernel info and control
%assign	CTL_VM		2	;VM management
%assign	CTL_NET		3	;Networking
%assign	CTL_PROC	4	;Process info
%assign	CTL_FS		5	;Filesystems
%assign	CTL_DEBUG	6	;Debugging
%assign	CTL_DEV		7	;Devices
%assign	CTL_BUS		8	;Busses
%assign	CTL_ABI		9	;Binary emulation
%assign	CTL_CPU		10	;CPU stuff (speed scaling, etc)

%assign	KERN_OSTYPE	1	;string: system version
%assign	KERN_OSRELEASE	2	;string: system release
%assign	KERN_OSREV	3	;int: system revision
%assign	KERN_VERSION	4	;string: compile time info
%assign	KERN_SECUREMASK	5	;struct: maximum rights mask
%assign	KERN_PROF	6	;table: profiling information
%assign	KERN_NODENAME	7
%assign	KERN_HOSTNAME	KERN_NODENAME
%assign	KERN_DOMAINNAME	8

%assign	KERN_CAP_BSET	14	;int: capability bounding set
%assign	KERN_PANIC	15	;int: panic timeout
%assign	KERN_REALROOTDEV	16	;real root device to mount after initrd

%assign	KERN_SPARC_REBOOT	21	;reboot command on Sparc
%assign	KERN_CTLALTDEL	22	;int: allow ctl-alt-del to reboot
%assign	KERN_PRINTK	23	;struct: control printk logging parameters
%assign	KERN_NAMETRANS	24	;Name translation
%assign	KERN_PPC_HTABRECLAIM	25	;turn htab reclaimation on/off on PPC
%assign	KERN_PPC_ZEROPAGED	26	;turn idle page zeroing on/off on PPC
%assign	KERN_PPC_POWERSAVE_NAP	27	;use nap mode for power saving
%assign	KERN_MODPROBE	28
%assign	KERN_SG_BIG_BUFF	29
%assign	KERN_ACCT	30	;BSD process accounting parameters
%assign	KERN_PPC_L2CR	31	;l2cr register on PPC

%assign	KERN_RTSIGNR	32	;Number of rt sigs queued
%assign	KERN_RTSIGMAX	33	;Max queuable
	
%assign	KERN_SHMMAX	34	;long: Maximum shared memory segment
%assign	KERN_MSGMAX	35	;int: Maximum size of a messege
%assign	KERN_MSGMNB	36	;int: Maximum message queue size
%assign	KERN_MSGPOOL	37	;int: Maximum system message pool size
%assign	KERN_SYSRQ	38	;int: Sysreq enable 
%assign	KERN_MAX_THREADS	39	;int: Maximum nr of threads in the system
%assign	KERN_RANDOM	40	;Random driver
%assign	KERN_SHMALL	41	;int: Maximum size of shared memory
%assign	KERN_MSGMNI	42	;int: msg queue identifiers
%assign	KERN_SEM	43	;struct: sysv semaphore limits
%assign	KERN_SPARC_STOP_A	44	;int: Sparc Stop-A enable
%assign	KERN_SHMMNI	45	;int: shm array identifiers
%assign	KERN_OVERFLOWUID	46	;int: overflow UID
%assign	KERN_OVERFLOWGID	47	;int: overflow GID
%assign	KERN_SHMPATH	48	;string: path to shm fs
%assign	KERN_HOTPLUG	49	;string: path to hotplug policy agent
%assign	KERN_IEEE_EMULATION_WARNINGS	50	;int: unimplemented ieee instructions
%assign	KERN_S390_USER_DEBUG_LOGGING	51	;int: dumps of user faults
%assign	KERN_CORE_USES_PID	52	;int: use core or core.%pid
%assign	KERN_TAINTED	53	;int: various kernel tainted flags
%assign	KERN_CADPID	54	;int: PID of the process to notify on CAD

;
;linux/mount.h
;

%assign MS_RDONLY	 1	;Mount read-only
%assign MS_NOSUID	 2	;Ignore suid and sgid bits
%assign MS_NODEV	 4	;Disallow access to device special files
%assign MS_NOEXEC	 8	;Disallow program execution
%assign MS_SYNCHRONOUS	16	;Writes are synced at once
%assign MS_REMOUNT	32	;Alter flags of a mounted FS
%assign MS_MANDLOCK	64	;Allow mandatory locks on an FS
%assign MS_NOATIME	1024	;Do not update access times
%assign MS_NODIRATIME	2048	;Do not update directory access times
%assign MS_BIND		4096
%assign MS_REC		16384
%assign MS_VERBOSE	32768
%assign MS_ACTIVE	(1<<30)
%assign MS_NOUSER	(1<<31)

%assign	MS_MGC_VAL	0xc0ed0000

;
;linux/hdreg.h
;

%assign	HDIO_GETGEO	0x0301  ;get device geometry

;
;utmp.h
;

%define _PATH_UTMP	"/var/run/utmp"

%assign	UT_LINESIZE	32
%assign	UT_NAMESIZE	32
%assign	UT_HOSTSIZE	256

%assign RUN_LVL		1	;The system's runlevel
%assign BOOT_TIME	2	;Time of system boot
%assign NEW_TIME	3	;Time after system clock changed
%assign OLD_TIME	4	;Time when system clock changed
%assign INIT_PROCESS	5	;Process spawned by the init process
%assign LOGIN_PROCESS	6	;Session leader of a logged in user
%assign USER_PROCESS	7	;Normal process
%assign DEAD_PROCESS	8	;Terminated process
%assign ACCOUNTING	9

struc exit_status
.e_termination	SHORT	1	;Process termination status
.e_exit		SHORT	1	;Process exit status
endstruc

struc utmp
.ut_type	SHORT	1		;Type of login
.__pad1		SHORT	1		
.ut_pid		U32	1		;Process ID of login process
.ut_line  	CHAR	UT_LINESIZE	;Devicename
.ut_id		CHAR	4		;Inittab ID
.ut_user	CHAR	UT_NAMESIZE	;Username
.ut_host	CHAR	UT_HOSTSIZE	;Hostname for remote login
.ut_exit	SHORT	2		;Exit status of a process marked as DEAD_PROCESS
.ut_session	LONG	1		;Session ID, used for windowing
.ut_tv		ULONG	2 		;Time entry was made
.ut_addr_v6	U32	4		;Internet address of remote host
.__unused	CHAR	20		;Reserved for future use
endstruc

;
;sys/sysinfo.h
;

struc sysinfo
.uptime     LONG    1
.loads      ULONG   3
.totalram   ULONG   1
.freeram    ULONG   1
.sharedram  ULONG   1
.bufferram  ULONG   1
.totalswap  ULONG   1
.freeswap   ULONG   1
.procs      USHORT  1
%if __KERNEL__ <= 22
.pad        CHAR    22
%else
.totalhigh  ULONG   1
.freehigh   ULONG   1
.mem_unit   ULONG   1
.pad        CHAR    8
%endif
endstruc

;
;system calls
;

%macro	__pushargs 2-8
%if %1>0
 %if %1>1
  %if %1>2
   %if %1>3
    %if %1>4
     %if %1>5
	%if %2>5
	_push	%8,ebp
	%else
	push	ebp
	%endif
     %endif
	%if %2>4
	_push	%7,edi
	%else
        push	edi
	%endif
    %endif
	%if %2>3
	_push	%6,esi
	%else
        push	esi
	%endif
   %endif
	%if %2>2
	_push	%5,edx
	%else
        push	edx
	%endif
  %endif
	%if %2>1
	_push	%4,ecx
	%else
        push	ecx
	%endif
 %endif
	%if %2>0
	_push	%3,ebx
	%else
        push	ebx
	%endif
%endif
%endmacro

;
;net/socket.c
;

%if __SYSCALL__=__S_KERNEL__

%define	__OS_SYSCALL_NETWORK__

%macro sys_socketcall 0-3
        __syscall socketcall, 3, %0, %1, %2, %3
%endmacro

%macro	sys_socket 0-3
	__pushargs 3, %0, %1, %2, %3
	sys_socketcall SYS_SOCKET,esp
	_add	esp,(3 * 4)
%endmacro

%macro	sys_accept 0-3
	__pushargs 3, %0, %1, %2, %3
	sys_socketcall SYS_ACCEPT,esp
	_add	esp,(3 * 4)
%endmacro

%macro	sys_connect 0-3
	__pushargs 3, %0, %1, %2, %3
	sys_socketcall SYS_CONNECT,esp
	_add	esp,(3 * 4)
%endmacro

%macro	sys_bind 0-3
	__pushargs 3, %0, %1, %2, %3
	sys_socketcall SYS_BIND,esp
	_add	esp,(3 * 4)
%endmacro

%macro	sys_setsockopt 0-5
	__pushargs 5, %0, %1, %2, %3, %4, %5
	sys_socketcall SYS_SETSOCKOPT,esp
	_add	esp,(5 * 4)
%endmacro

%macro	sys_getsockname 0-3
	__pushargs 3, %0, %1, %2, %3
	sys_socketcall SYS_GETSOCKNAME,esp
	_add	esp,(3 * 4)
%endmacro

%macro	sys_shutdown 0-2
	__pushargs 2, %0, %1, %2
	sys_socketcall SYS_SHUTDOWN,esp
	_add	esp,(2 * 4)
%endmacro

%macro	sys_listen 0-2
	__pushargs 2, %0, %1, %2
	sys_socketcall SYS_LISTEN,esp
	_add	esp,(2 * 4)
%endmacro

%macro	sys_send 0-4
	__pushargs 4, %0, %1, %2, %3, %4
	sys_socketcall SYS_SEND,esp
	_add	esp,(4 * 4)
%endmacro

%macro	sys_recv 0-4
	__pushargs 4, %0, %1, %2, %3, %4
	sys_socketcall SYS_RECV,esp
	_add	esp,(4 * 4)
%endmacro

%macro	sys_sendto 0-6
	__pushargs 6, %0, %1, %2, %3, %4, %5, %6
	sys_socketcall SYS_SENDTO,esp
	_add	esp,(6 * 4)
%endmacro

%macro	sys_recvfrom 0-6
	__pushargs 6, %0, %1, %2, %3, %4, %5, %6
	sys_socketcall SYS_RECVFROM,esp
	_add	esp,(6 * 4)
%endmacro

%macro	sys_sendmsg 0-3
	__pushargs 3, %0, %1, %2, %3
	sys_socketcall SYS_SENDMSG,esp
	_add	esp,(3 * 4)
%endmacro

%macro	sys_recvmsg 0-3
	__pushargs 3, %0, %1, %2, %3
	sys_socketcall SYS_RECVMSG,esp
	_add	esp,(3 * 4)
%endmacro

%endif


;
;arch/i386/kernel/sys_i386.c
;

%if __SYSCALL__=__S_KERNEL__

%define	__OS_SYSCALL_MMAP__

struc	mmap_arg_struct
.addr	ULONG	1
.len	ULONG	1
.prot	ULONG	1
.flags	ULONG	1
.fd	ULONG	1
.offset	ULONG	1
endstruc

%macro sys_oldmmap 0-1
	__syscall mmap, 1, %0, %1
%endmacro

%macro sys_mmap 0-6
%if __KERNEL__ >= 24
	__syscall mmap2, 6, %0, %1, %2, %3, %4, %5, %6
%else
	__pushargs 6, %0, %1, %2, %3, %4, %5, %6
	sys_oldmmap esp
	_add	esp,(6 * 4)
%endif
%endmacro

%endif

%macro sys_vhangup 0
	__syscall vhangup, 0
%endmacro

;
;kernel/sys.c
;

%if __SYSCALL__=__S_KERNEL__
%define	__OS_SYSCALL_REBOOT__
%macro sys_reboot 0-4
	__syscall reboot, 4, %0, %1, %2, %3, %4
%endmacro
%endif

%if __SYSCALL__=__S_LIBC__
%define __OS_SYSCALL_GETDENTS__
%macro sys_getdents 0-3
	__syscall getdents64, 3, %0, %1, %2, %3
%endmacro
%endif

;
;Linux specific syscalls
;

%macro sys_llseek 0-5
	__syscall llseek, 5, %0, %1, %2, %3, %4, %5
%endmacro

;
;arch/i386/kernel/ioport.c
;

%macro sys_ioperm 0-3
	__syscall ioperm, 3, %0, %1, %2, %3
%endmacro

%macro sys_iopl 0-1
	__syscall iopl, 1, %0, %1
%endmacro

;
;arch/i386/kernel/process.c
;

%macro sys_idle 0
	__syscall idle, 0
%endmacro

%macro sys_clone 0-2
	__syscall clone, 2, %0, %1, %2
%endmacro

;
;arch/i386/kernel/ldt.c
;

%macro sys_modify_ldt 0-3
	__syscall modify_ldt, 3, %0, %1, %2, %3
%endmacro
;
;arch/i386/kernel/vm86.c
;

%macro sys_vm86old 0-1
	__syscall vm86old, 1, %0, %1
%endmacro

%macro sys_vm86 0-2
	__syscall vm86, 2, %0, %1, %2
%endmacro

;
;kernel/info.c
;

%macro sys_sysinfo 0-1
	__syscall sysinfo, 1, %0, %1
%endmacro

;
;kernel/printk.c
;

%macro sys_syslog 0-3
	__syscall syslog, 3, %0, %1, %2, %3
%endmacro

;
;fs/buffer.c
;

%macro sys_bdflush 0-2
	__syscall bdflush, 2, %0, %1, %2
%endmacro

;
;mm/swapfile.c
;

%macro sys_swapon 0-2
	__syscall swapon, 2, %0, %1, %2
%endmacro

%macro sys_swapoff 0-1
	__syscall swapoff, 1, %0, %1
%endmacro

;

%macro sys__sysctl 0-1
	__syscall sysctl, 1, %0, %1
%endmacro

%macro sys_sysctl 0-6
	__pushargs 6, %0, %1, %2, %3, %4, %5, %6
	sys__sysctl esp
	_add	esp,(6 * 4)
%endmacro

;

%macro sys_rt_sigreturn 0-1
	__syscall rt_sigreturn, 1, %0, %1
%endmacro

%macro sys_rt_sigsuspend 0-2
	__syscall rt_sigsuspend, 2, %0, %1, %2
%endmacro

;
;kernel/module.c
;

%macro sys_delete_module 0-1
	__syscall delete_module, 1, %0, %1
%endmacro

%macro sys_init_module 0-2
	__syscall init_module, 2, %0, %1, %2
%endmacro

%macro sys_create_module 0-2
	__syscall create_module, 2, %0, %1, %2
%endmacro

%macro sys_query_module 0-5
	__syscall query_module, 5, %0, %1, %2, %3, %4, %5
%endmacro

%macro sys_get_kernel_syms 0-1
	__syscall get_kernel_syms, 1, %0, %1
%endmacro

;

%macro sys_umount2 0-2
	__syscall umount2, 2, %0, %1, %2
%endmacro

%macro sys_sbrk 0-1
	__syscall brk, 1, %0, %1
%endmacro

%endif	;__LINUX_INC
