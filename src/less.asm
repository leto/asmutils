;Copyright (C) 2001 Tiago Gasiba <ee97034@fe.up.pt>
;
;$Id: less.asm,v 1.8 2003/02/10 16:22:36 konst Exp $
;
;hackers' less/more
;
;syntax: less [filename]
;
;example: less /etc/passwd
;	  ls -l | more
;
;TODO:
;	- add "/" (search)
;	- view multiply files
;
;0.01:	24-Aug-2001	initial release
;0.02:	08-Sep-2001	some bug fixes
;0.03:	14-Mar-2002	dynamic window size, redirection check, 
;			enter & space keys, optimization (KB)

%include "system.inc"

%assign	LineWidth	80	;default values
%assign	NumLines	24	;

%assign	BUFF_IN_LEN	8192
%assign	MEM_RESERV	1024

KEY_DOWN		equ	0x00425b1b
KEY_UP			equ	0x00415b1b
KEY_PGDOWN		equ	0x7e365b1b
KEY_PGUP		equ	0x7e355b1b
KEY_HOME		equ	0x7e315b1b
KEY_END			equ	0x7e345b1b

KEY_ENTER		equ	0xa
KEY_SPACE		equ	" "
KEY_b			equ	"b"
KEY_q			equ	"q"
KEY_Q			equ	"Q"

CODESEG

key_table:
	dd	KEY_q,		terminate
	dd	KEY_Q,		terminate
	dd	KEY_UP,		event_key_up
	dd	KEY_DOWN,	event_key_down
	dd	KEY_ENTER,	event_key_down
	dd	KEY_SPACE,	event_key_pgdown
	dd	KEY_PGDOWN,	event_key_pgdown
	dd	KEY_PGUP,	event_key_pgup
	dd	KEY_b,		event_key_pgup
	dd	KEY_END,	event_key_end
	dd	KEY_HOME,	event_key_home
key_table_end:

write_nl:
		sys_write STDOUT,nl,1
		ret

terminate:
		sys_ioctl STDERR,TCSETS,oldtermios
		call	write_nl
do_exit:
		sys_exit 0

START:

begin:
;		_mov	eax,STDIN
;		mov	[fd],eax

		pop	ebx
		dec	ebx
		pop	ebx
		jz	.entrada
		pop	ebx
		sys_open EMPTY,O_RDONLY
		mov	[fd],eax
		test eax, eax
		jns .entrada
		sys_exit 1
.entrada:
		sys_ioctl [fd],TCGETS,oldtermios	;redirection check
		test	eax,eax
		jns	do_exit

		sys_ioctl STDOUT,TIOCGWINSZ,window	;get window size
		dec	word [edx]			;exclude one row
		or	eax,eax
		jz	.set_stderr

		mov	dword [edx], LineWidth << 16 | NumLines	;defaults
		
.set_stderr:
		sys_ioctl STDERR,TCGETS,oldtermios
		sys_ioctl STDERR,EMPTY,newtermios
		and	dword [newtermios+termios.c_lflag],~(ICANON|ECHO|ISIG)
		sys_ioctl STDERR,TCSETS,newtermios

		call	ler_ficheiro
		call	init_lines

;		xor	eax,eax
;		mov	[pos],eax		; set position = 0 (TOP)

.reescreve:
		sys_write STDOUT,clear,clear_len
		call	write_lines
		sys_write STDOUT,rev_on,rev_on_len
		mov	eax,[pos]
		mov	edi,msg
		call	itoa
		inc	edx
		push	edx
		mov	byte [edi],'/'
		inc	edi
		mov	eax,[nlines]
		call	itoa
		pop	eax
		add	edx,eax
		sys_write STDOUT,msg
		sys_write STDOUT,rev_off,rev_off_len
.outra_vez:
		mov	ecx,key_pressed
		xor	eax,eax
		mov	[ecx],eax

		sys_read STDERR,EMPTY,4

		mov	eax,[ecx]
		mov	ebx,key_table
.check:
		cmp	eax,[ebx]
		jz	.call
		add	ebx,byte 8
		cmp	ebx,key_table_end
		jz	.outra_vez
		jmps	.check
.call:

%define	POS	ecx
%define	NLINES	edx
%define	HEIGHT	ebp

		mov	POS,[pos]
		mov	NLINES,[nlines]
		movzx	HEIGHT,word [window.ws_row]
		call	[ebx + 4]
		mov	[pos],POS
		mov	[nlines],NLINES
		jmp	begin.reescreve


;=====================================================
;                  event_key_up
;=====================================================

event_key_up:
	test	POS,POS
	je	bell
	cmp	NLINES,HEIGHT
	jl	bell
	dec	POS
	ret

;=====================================================
;                  event_key_down
;=====================================================
event_key_down:
	cmp	NLINES,HEIGHT
	jl	bell
	mov	eax,NLINES
	sub	eax,HEIGHT
	cmp	POS,eax
	je	bell
	inc	POS
	ret

;=====================================================
;                  event_key_pgdown
;=====================================================
event_key_pgdown:
	cmp	NLINES,HEIGHT
	jl	bell
	mov	eax,NLINES
	sub	eax,HEIGHT
	mov	ebx,POS
	add	ebx,HEIGHT
	cmp	eax,ebx
	jg	bell.lbl1
	mov	POS,eax
bell:
	pusha
	sys_write STDOUT,bell_str,1	;bell_str_len
	popa
	ret

.lbl1:
	mov	POS,ebx
	ret

;=====================================================
;                  event_key_pgup
;=====================================================
event_key_pgup:
	cmp	NLINES,HEIGHT
	jl	bell
	mov	eax,POS
	sub	eax,HEIGHT
	jns	.lbl1
	xor	POS,POS
	jmps	bell
.lbl1:
	mov	POS,eax
	ret

;=====================================================
;                  event_key_end
;=====================================================
event_key_end:
	mov	eax,NLINES
	cmp	eax,HEIGHT
	jl	bell
	sub	eax,HEIGHT
	mov	POS,eax
	jmps	bell

;=====================================================
;                  event_key_home
;=====================================================
event_key_home:
	xor	POS,POS
	jmps	bell

%undef	POS
%undef	NLINES
%undef	HEIGHT

;-----------------------------------------------------
; function    : ler_ficheiro
; description : initializes the buffer
; needs       : [fd]
; returns     : [lines]
; destroys    : -
;-----------------------------------------------------
ler_ficheiro:
	pusha
	mov	ebp,filebuffer
	push	ebp
.lbl1:
	sys_read [fd],buffin,BUFF_IN_LEN

	test	eax,eax
	jz	.fim

	push	eax
	push	eax

	mov	ebx,eax
	add	ebx,ebp
	sys_brk

	mov	esi,buffin
	mov	edi,ebp
	pop	ecx
	cld
	rep	movsb
	mov	ebp,edi
	pop	eax
	cmp	edx,eax		;end of file?
	jz	.lbl1
.fim:	
	mov	[lines],ebp
	pop	dword [ebp]	;mov	dword [ebp],filebuffer
	popa
	ret

;-----------------------------------------------------
; function    : init_lines
; description : initializes lines structure
; needs       : -
; returns     : -
; destroys    : -
;-----------------------------------------------------
init_lines:
	pusha
	cld
	mov	esi,filebuffer
	mov	ebp,[lines]
	mov	ecx,ebp
	sub	ecx,esi
	_mov	edx,0
	mov	edi,ebp
.lbl1:
	lodsb
	cmp	al,__n
	je	.lbl3
	cmp	al,__t
	jne	.lbl2
	or	edx,byte 7
.lbl2:
	inc	edx
	cmp	dx,[window.ws_col]
	jl	.lbl5
.lbl3:
	add	ebp,byte 4
	cmp	edi,ebp
	jg	.lbl4
	_add	edi,MEM_RESERV
	sys_brk	edi
.lbl4:
	mov	[ebp],esi
	inc	dword [nlines]
	_mov	edx,0
.lbl5:
	loop	.lbl1
.fim:
	popa
	ret

;-----------------------------------------------------
; function    : write_lines
; description : writes a max. of NumLines to STDOUT
; needs       : -
; returns     : -
; destroys    : -
;-----------------------------------------------------
write_lines:
	mov	ebp,[lines]
	mov	edx,[pos]
	mov	eax,[nlines]
	sub	eax,edx
	mov	ecx,eax

	shl	edx,2
	add	ebp,edx
	movzx	ebx,word [window.ws_row]
	cmp	eax,ebx
	jle	.lbl1
	mov	ecx,ebx
.lbl1:
	push	ecx
	push	edx
	mov	ecx,[ebp]
	mov	edx,[ebp+4]
	push	edx
	sub	edx,ecx
	sys_write STDOUT
	pop	edx
	dec	edx
	cmp	byte [edx],__n
	je	.lbl2
	call	write_nl
.lbl2:
	add	ebp,byte 4
	pop	edx
	pop	ecx
	loop	.lbl1
	ret

;-----------------------------------------------------
; function  : itoa (modified version)
; objective : convert from int to string
; needs     : eax - unsigned integer
;           : edi - destination buffer
; returns   : edx - string length
; destroys  : edx
;           : edi
;           : eax
;-----------------------------------------------------
itoa:
	_mov	ebx,10
	_mov	ecx,0
	test	eax,eax
	jne	.lbl1
	push	byte 0x30
	inc	ecx
	jmps	.lbl2
.lbl1:
	test	eax,eax
	jz	.lbl2
	_mov	edx,0
	idiv	ebx
	or	dl,0x30
	push	edx
	inc	ecx
	jmps	.lbl1
.lbl2:
	mov	edx,ecx
.fim:	
	pop	eax
	stosb
	loop	.fim
	mov	[esp+20],edx
	ret

nl		db	__n

clear		db	0x1b,"[2J",0x1b,"[1H"
clear_len	equ	$-clear
bell_str	db	7
bell_str_len	equ	$-bell_str
rev_on		db	0x1b,"[7m["
rev_on_len	equ	$-rev_on
rev_off		db	"]",0x1b,"[27m"
rev_off_len	equ	$-rev_off

UDATASEG

fd			resd	1
msg			resb	LineWidth

window		B_STRUC winsize, .ws_row, .ws_col

oldtermios	B_STRUC termios,.c_iflag,.c_oflag
newtermios	B_STRUC termios,.c_iflag,.c_oflag

key_pressed		resd	1
lines			resd	1			; pnt to lines struct
nlines			resd	1			; nr. of lines
pos			resd	1			; current position
buffin			resb	BUFF_IN_LEN

filebuffer:		;resb	1			; file buffer

END
