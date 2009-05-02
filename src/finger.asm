; Copyright (c) 2001 Thomas M. Ogrisegg
;
; finger - user information lookup program
;
; fingerd - remote user information server
;
; usage:
;      finger [username] / fingerd
;
; License          :     GNU General Public License
; Author           :     Thomas Ogrisegg
; E-Mail           :     tom@rhadamanthys.org
; Created          :     12/02/01
; Last Updated     :     03/25/02 03/17/02
; Version          :     0.6
; Processor        :     i386+
; SusV2-compliant  :     no
; GNU-compatible   :     no
; Feature-Complete :     no
;
; 03/17/02 - added individual user lookup (TO)
; 03/22/02 - added fingerd (TO)
;
; BUGS: 
;      probably many
;
; $Id: finger.asm,v 1.7 2006/02/09 08:02:57 konst Exp $

%include "system.inc"

%assign UTMP_RECSIZE utmp_size

%ifdef __LINUX__
%assign ERESTART 85
%endif

CODESEG

init_data:
	sys_open utmpfile, O_RDONLY
	mov [utmpfd], eax
	sys_chdir devdir
	sys_open passwd, O_RDONLY
	mov [pwdfd], eax
	sys_fstat eax, statbuf
	sys_mmap 0, [statbuf.st_size], PROT_READ, MAP_PRIVATE, [pwdfd], 0
	mov [pwptr], eax
	sys_time ctime
	ret

START:
	call init_data
	pop ecx
	dec ecx
	jnz near lookup_user
	;;; NEW ;;;
	pop edi
	xor eax, eax
	dec ecx
	repnz scasb
	cmp byte [edi-2], 'd'
	jz near start_fingerd
	sys_write STDOUT, banner, bannerlen
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
read_next_utmp:
	sys_read [utmpfd], utmpbuf, UTMP_RECSIZE
	or eax, eax
	jz near do_exit
	cmp long [utmpbuf.ut_type], USER_PROCESS
	jnz read_next_utmp
	mov edi, buf
	lea esi, [utmpbuf.ut_user]
	mov ecx, 11
	lodsb
.un_copy_loop:
	stosb
	dec ecx
	lodsb
	or al, al
	jnz .un_copy_loop

	mov al, ' '
	push ecx
	repnz stosb

	pop ecx
	neg ecx
	add ecx, 11
	call getusername
	sub ecx, 22
	neg ecx
	mov al, ' '
	repnz stosb

	mov esi, utmpbuf.ut_line
	mov ecx, 8

	lodsb
.tty_copy_loop:
	stosb
	dec ecx
	lodsb
	or al, al
	jnz .tty_copy_loop
	mov al, ' '
	repnz stosb

	sys_stat utmpbuf.ut_line, statbuf
	or eax, eax
	js near _write
	mov eax, [ctime]
	sub eax, [statbuf.st_atime]
	cmp eax, 60
	jng near nidle

	xor edx, edx
	mov ebx, 86400 ; 60*60*24
	idiv ebx
	or eax, eax
	jz _next1
	call lstr
	jmp _next2
_next1:
	xchg edx, eax
	mov long [edi], '    '
_next2:
	add edi, 3

	mov ebx, 3600
	idiv ebx
	or eax, eax
	jz _next3
	call lstr
	jmp _next4
_next3:
	xchg edx, eax
	mov long [edi], '    '
_next4:
	add edi, 3
	mov ebx, 60
	idiv ebx
	call lstr
	add edi, 2

end_idle:
	mov esi, utmpbuf.ut_host
	lodsb
	or al, al
	jz lnext
	mov long [edi],   '    '
	mov long [edi+4], '    '
	add edi, 4

uth_cp_loop:
	stosb
	lodsb
	or al, al
	jnz uth_cp_loop
lnext:
	mov byte [edi], __n
	mov byte [edi+1], 0
_write:
	mov edi, buf
	xor eax, eax
	mov ecx, 80
	repnz scasb
	sub ecx, 80
	not ecx
	sys_write STDOUT, buf, ecx
	jmp read_next_utmp
	jmp do_exit

nidle:
	mov long [edi],   '    '
	mov long [edi+4], '    '
	mov word [edi+6], '  '
	mov byte [edi+7], '-'
	add edi, 8
	jmp end_idle

sigchld:
	sys_signal SIGCHLD, sigchld
	sys_wait4	-1, 0, 0, 0
	ret

start_fingerd:
	sys_signal SIGCHLD, sigchld
	sys_socket AF_INET, SOCK_STREAM, IPPROTO_IP
	mov [sockfd], eax
	push byte 0x0
	push word 0x4f00
	push word AF_INET
	mov edi, esp
	sys_bind   [sockfd], edi, 0x10
	or eax, eax
	js near .Lno_bind
	sys_listen [sockfd], 5
	sys_close STDOUT
	push byte 0x0
.Laccept:
	pop eax
	sys_accept [sockfd], NULL, NULL
	push eax
	or eax, eax
	js .Laccept
	sys_fork
	or eax, eax
	jnz .Laccept
	pop eax
	sys_dup2 eax, STDOUT
	sub esp, 0x100
	sys_read STDOUT, esp, 0x100
	mov byte [esp+eax], 0x0
	lea esi, [esp+eax]
	std
.Lloop:
	lodsb
	cmp al, ' '
	jng .Lloop
	cld
	mov byte [esi+2], 0
	mov esi, esp
	add esp, 0x100
	push esi
	push long 0x0
	sys_lseek [utmpfd], 0, SEEK_SET ;FIXME;
	jmp lookup_user
.Lno_bind:
	sys_write STDOUT, nobind, nobindlen
	sys_exit 0x0

nobind	db	"Could not bind socket to port", __n
nobindlen	equ	$ - nobind

%macro strcpy 3
	mov ecx, %2
	mov esi, %1
	repnz movsb
	mov ecx, %3-%2
%endmacro

%macro strccpy 2
	mov esi, %1
	lodsb
.Llabel%2:
	dec ecx
	stosb
	lodsb
	or al, al
	jnz .Llabel%2
%endmacro

%macro skip1 2
.Llabel%1:
	lodsb
	cmp al, %2
	jnz .Llabel%1
%endmacro

strfcpy:
	lodsb
	cmp al, ':'
	jz .Lret
	cmp al, ','
	jz .Lret
	cmp al, __n
	jz .Lret
	or al, al
	jz .Lret
	dec ecx
	stosb
	jmp strfcpy
.Lret:
	ret

lookup_user:
	pop esi
	mov esi, [pwptr]
	pop edi
	push edi
	xor ecx, ecx
	xor eax, eax
	dec ecx
	repnz scasb
	not ecx
	dec ecx
	pop edi
	push edi
	call rn_search_loop
	mov ebp, esi
	or esi, esi ;ERROR!
	jz near .Lerror
	mov edi, buf
	strcpy login, loginlen, 40
	pop esi
	push esi
	strccpy esi, 33
	mov al, ' '
	repnz stosb
	strcpy name, namelen, 40
	mov ecx, 4
	mov esi, ebp
	skip1 1, ':'
	dec ecx
	jnz .Llabel1
	push esi
	call strfcpy
	mov byte [edi+1], __n
	sys_write STDOUT, buf, 80
	mov edi, buf
	strcpy hdir, hdirlen, 40
	pop esi
	skip1 2, ':'
	push esi
	call strfcpy
	mov al, ' '
	repnz stosb
	strcpy shell, shellen, 40
	pop esi
	skip1 3, ':'
	call strfcpy
	mov byte [edi], __n
;	lea ecx, [edi-buf+1]
	lea edx, [edi+1]
	sub edx, buf
	sys_write STDOUT, buf
.Lsrch_utmp:
	sys_read [utmpfd], utmpbuf, UTMP_RECSIZE
	or eax, eax
	jz near do_exit
	cmp long [utmpbuf.ut_type], USER_PROCESS
	jnz .Lsrch_utmp
	lea esi, [utmpbuf.ut_user]
	pop edi
	push edi
	repz cmpsb
	cmp byte [esi], 0
	jnz .Lsrch_utmp
	mov edi, buf
	strcpy loggedin, loglen, 80
	strccpy utmpbuf.ut_line, 23
	sub ecx, 81
	neg ecx
	mov byte [edi], __n
	sys_write STDOUT, buf, ecx
	jmp .Lsrch_utmp
.Lerror:
	sys_write STDOUT, nouser, nouserlen
	cmp long [sockfd], 0x0
	jz .Lreal_exit
	sys_shutdown STDOUT, 0x2
.Lreal_exit:
	sys_exit 0x1


;;;;;;;;;;;;;;;;;;;;;;;;;;;lstr;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Converts a long into a two-byte string
;; <- eax (long to convert)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
lstr:
	push edx
	xor edx, edx
	mov ebx, 10
	idiv ebx
	add dl, '0'
	add al, '0'
	mov byte [edi],   al
	mov byte [edi+1], dl
	mov byte [edi+2], ':'
	xor edx, edx
	pop eax
	ret

;;;;;;;;;;;;;;;;;;;;;;getusername;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Parses /etc/passwd and copys the realname to the outputbuffer
;; <- ecx (length of username)
;; -> ecx (length of Realname - 0 on error)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

getusername:
	push edi
	mov edi, utmpbuf.ut_user
	mov esi, [pwptr]
	xor eax, eax
	call rn_search_loop
	or esi, esi
	jz .Lret
	call rn_found_next
.Lret:
	pop eax
	ret

rn_search_loop:
	lodsb
	cmp al, [edi]
	jz rn_fc_match
rn_nextline:
	lodsb
	cmp al, __n
	jz rn_search_loop
	or al, al
	jnz rn_nextline
	xor esi, esi
	xor ecx, ecx
	ret

rn_fc_match:
	mov edx, ecx
	dec esi
	push edi
	repz cmpsb
	pop edi
	or ecx, ecx
	jnz rn_prep_sl
	cmp byte [esi], ':'
	jz rn_found

rn_prep_sl:
	mov ecx, edx
	jmp rn_nextline

rn_found:
	ret
rn_found_next:
	mov ecx, 4
rn_lloop:
	lodsb
	or al, al
	jz do_exit
	cmp al, ':'
	jnz rn_lloop
	dec ecx
	jnz rn_lloop
	dec ecx

	mov edi, [esp+4]
rn_laloop:
	inc ecx
	lodsb
	cmp al, ':'
	jz rn_ret
	cmp al, ','
	jz rn_ret
	stosb
	jmp rn_laloop

rn_ret:
	ret

do_exit:
	cmp long [sockfd], 0x0
	jz .Lreal_exit
	sys_shutdown STDOUT, 0x2
.Lreal_exit:
	sys_exit 0x0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

utmpfile db _PATH_UTMP, EOL
passwd db "/etc/passwd", EOL
banner db "Login      Name                  Tty         Idle    Where",__n
bannerlen equ $ - banner
devdir db "/dev",EOL

login	db	"Login: "
loginlen	equ	$ - login
name	db	"Name: "
namelen	equ	$ - name
hdir	db	"Directory: "
hdirlen	equ	$ - hdir
shell	db	"Shell: "
shellen	equ $ - shell
office	db	"Office: "
offlen	equ	$ - office
phone	db	"Home Phone: "
loggedin	db	"Logged in at "
loglen	equ	$ - loggedin
nouser	db	"This user doesnt exist", __n
nouserlen	equ	$ - nouser

UDATASEG

sockfd	LONG	1
ctime	LONG	1
utmpfd  LONG    1
pwdfd   LONG    1
pwptr   LONG    1

statbuf B_STRUC Stat,.st_size,.st_atime
utmpbuf B_STRUC utmp,.ut_type,.ut_line,.ut_user,.ut_host,.ut_tv

buf		UCHAR	80

END
