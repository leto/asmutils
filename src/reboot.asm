;Copyright (C) 1999-2002 Konstantin Boldyshev <konst@linuxassembly.org>
;
;$Id: reboot.asm,v 1.5 2002/02/02 08:49:25 konst Exp $
;
;hackers' reboot/halt/poweroff
;
;syntax: reboot [-p] [-f]
;	 halt [-p]
;	 poweroff
;
;-p	try to do poweroff (as if called as 'poweroff')
;-f	do actual reboot (bypass shutdown sequence)
;
;0.01: 04-Jul-1999	initial release
;0.02: 23-Dec-2001	added "-p" option, try to talk to init, BSD port
;			
;WARNING:
;
;BSD is smart enough to care about things on sys_reboot, while Linux is not.
;Linux users -- this is actual reboot/halt/poweroff, it cares not
;about runlevels and "correct" shutdown. You have been warned.
;So that your day may not be ruined, Linux version of 'reboot' tries to tell
;init to invoke "correct" usual reboot sequence (*only* if called as 'reboot'), 
;waits 5 seconds (so that it can be terminated), and reboots system;
;so, if it was not terminated during these 5 seconds, you are unlucky.
;This "safety" step is bypassed by '-f' option.

%include "system.inc"

CODESEG

%ifdef	__LINUX__
%if	__SYSCALL__=__S_KERNEL__
%define	LINUX_REBOOT
%endif
%endif


START:
	xor	edi,edi
	pop	ebp		;argc

	pop	esi
.n1:
	lodsb
	or 	al,al
	jnz	.n1

;default action is reboot
%ifdef	LINUX_REBOOT
	_mov	ebx,LINUX_REBOOT_MAGIC1
	_mov	ecx,LINUX_REBOOT_MAGIC2
	_mov	edx,LINUX_REBOOT_CMD_RESTART
%else
	_mov	ebx,RB_AUTOBOOT
%else
%endif

.next:
	dec	ebp
	jz	.done

	pop	eax
	cmp	word [eax],"-p"
	jz	.poweroff
	cmp	word [eax],"-f"
	jnz	.done
	inc	edi
	jmps	.next

.done:

.n2:
	cmp	dword [esi-5],'halt'		;halt
	jnz	.n3

%ifdef	LINUX_REBOOT
	_mov	edx,LINUX_REBOOT_CMD_HALT
%else
	_mov	ebx,RB_HALT
%else
%endif
	jmps	.halt

.n3:
	cmp	word [esi-3],'ff'		;poweroff
	jnz	.n4

.poweroff:
%ifdef	LINUX_REBOOT
	_mov	edx,LINUX_REBOOT_CMD_POWER_OFF
%else
	_mov	ebx,RB_HALT|RB_POWEROFF
%else
%endif

.halt:

%ifdef	LINUX_REBOOT	;make sure that CTRL+ALT+DEL is enabled
	push	edx
	sys_reboot EMPTY,EMPTY,LINUX_REBOOT_CMD_CAD_ON
	pop	edx
%endif

.reboot:
	sys_reboot

.exit:
	sys_exit eax

.n4:
%ifdef	LINUX_REBOOT
	or	edi,edi		;check for -f
	jnz	.reboot		;let the show begin

	pusha
	sys_kill 1,SIGINT	;try to kill them all
	sys_nanosleep t		;and await our death
	popa
	sys_sync
	jmps	.reboot		;oops, init, you're late

t I_STRUC timespec
.tv_sec		_LONG	5
.tv_nsec	_LONG	0
I_END

%else

	jmps	.reboot

%endif

END
