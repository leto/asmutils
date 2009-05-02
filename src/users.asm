; Copyright (C) 2003 Jorge Contreras A. <aioros2000@hotmail.com>
;
; $Id: users.asm,v 1.1 2006/02/09 07:56:56 konst Exp $
;
; hackers` users v0.1 26/02/2003 21:00
;
; Programmer :   Jorge Contreras A. (X3r0r)
; License    :   GNU General Public License.
; syntax     :   users [utmp file]
;                Arguments are not obligatories.
; Description:   Output who is currently logged in according utmp file.
; Note       :   Sorry for my poor english. 
; Country    :   Chile
; Bugs       :   Maybe a lot.. :(

%include "system.inc"

%define	ENDL       0x0a
%define EOL        0x0

CODESEG
START:
	pop		ebx
	dec		bl
	dec		bl
	jz		use_args
	_mov		edx, utmp_path
	jmp		near ok
use_args:
	pop 		edx
	pop		edx
ok:
	sys_open	edx, O_RDONLY
	push 		eax     	;; The Descriptor into the Stack.
	inc 		eax
	inc 		eax
	jz 		end
read_entries:
	sys_read 	[esp], utmpbuf, utmp_size ;; We won some bytes. :)
	test 		eax, eax
	jz 		entries_done
	xor 		byte [utmpbuf.ut_type], USER_PROCESS
	jnz 		read_entries
	sys_write 	STDOUT, utmpbuf.ut_user, UT_NAMESIZE
	sys_write	STDOUT, space, 1
	jmp 		near read_entries
entries_done:
	sys_write 	STDOUT, newline, 1 
end:
	sys_close 	[esp]
	sys_exit  	0

; Strings are here...

utmp_path 	db 	_PATH_UTMP, EOL
space     	db 	" "
newline   	db 	ENDL

UDATASEG
utmpbuf B_STRUC utmp,.ut_type,.ut_user
END
