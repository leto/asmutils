;Copyright (C) 1995-2001 Konstantin Boldyshev <konst@linuxassembly.org>
;
;$Id: window.asm,v 1.13 2006/02/09 07:50:07 konst Exp $
;
;text window example
;
;This is my another old program ported to Linux,
;demonstration of fancy text interface common for DOS programs.
;Actually this is a prototype of a screen/window library.
;
;The program does not use terminal escape sequense to control output.
;Instead, it uses DOS-like approach of working with text video memory -
;/dev/vcsa, so make sure you have rw permissions on this device.
;
;Functions and data structures are not documented, but I hope
;you can guess what is what by examining the source.

%include "system.inc"

;

%assign	cXY	0x02
%assign	cAttr	0x01
%assign	cEnd	0x00
%assign	cDefAttr 0x07

;

%assign cBack	0x1BB0

;

%assign	wX	2
%assign	wY	1        ; Window position
%assign	wXlen	64
%assign	wYlen	12       ; Window size


CODESEG

%define xy(x,y) ((x) << 8) | (y)

%macro s_xy 2
	db	cXY
	db	%2
	db	%1
%endmacro
%macro s_attr 1
	db	cAttr,%1
%endmacro
%macro s_end 0
	db	cEnd
%endmacro


sHeader:
	s_xy	wX+(wXlen-lHeader)/2,wY
	s_attr	0x1F
.text:
	db	'Shadowed window with header and status bar'
	s_end
lHeader	equ	$ - .text

sText:
	s_xy	wX+(wXlen-lText1-4)/2, (wYlen)/2 - 1
	s_attr	0x09
	db	'[ '
	s_attr	0x8E
.t1:
	db	'Assembler Inside'
lText1	equ	$ - .t1
	s_attr	0x09
	db	' ]'
sText2:
	s_xy	wX+(wXlen-lText2)/2, (wYlen)/2 + 1
	s_attr	0x0A
.t2:
	db	'kick '
	s_attr	0x70
	db	'Enter'
	s_attr	0x0A
	db	' to crash keyboard'
lText2	equ	$ - .t2 - 3
	s_end


sStatus:
	s_xy	wX+2,wY+wYlen-1 
	s_attr	0x1B
.text:
	db	'Designed for Linux/i386 '
;	s_attr	0x9F
;	db	':)'
	s_end
lStatus	equ	$ - .text

;
;
;

START:
	call	open_screen

;save old screen

	_mov	edx,[sLen]
	_mov	ecx,xy(0,0)
	_mov	ebx,vMemS
	call	vread

;clear screen

	mov	ax,cBack
	mov	ecx,edx
	mov	edi,vMem
	rep	stosw

;create window

	call	window

;update screen

	_mov	edx,[sLen]
	_mov	ecx,xy(0,0)
	_mov	ebx,vMem
	call	vwrite

.read_key:
	sys_read STDIN,tmp,1
	test	eax,eax
	js	.read_key

	mov	al,byte [tmp]
	cmp	al,0x1b	;Escape
	jz	.restore_screen
	cmp	al,0xd	;Enter
	jnz	.read_key

.restore_screen:

	_mov	edx,[sLen]
	_mov	ecx,xy(0,0)
	_mov	ebx,vMemS
	call	vwrite

	call	close_screen

do_exit:
	sys_exit eax

;
; Window function
;

%assign cWin	0x01DB
%assign cShadow	0x03      ; shadow attribute

window:
	_mov	ecx,xy(wX,wY)
	call	gotoXY
	
	_mov	ecx,wXlen
	mov	ax,cWin
	rep	stosw

	_mov	ecx,wYlen-2
.middle:
	push	ecx
	_add	ecx,(wY + (wX << 8))
	call	gotoXY
	mov	ax,(cWin & 0xf0) | 221
	stosw
	_mov	ecx,wXlen-2
	mov	al,' '
	rep	stosw

	mov	al,222
	stosw

	mov	al,cShadow
	inc	edi
	stosb
	inc	edi
	stosb
	pop	ecx
	loop	.middle

	_mov	ecx,xy(wX,wY+wYlen-1)
	call	gotoXY

	_mov	ecx,wXlen
	mov	ax,cWin
	rep	stosw

	mov	al,cShadow
	inc	edi
	stosb
	inc	edi
	stosb

	_mov	ecx,xy(wX+2,wY+wYlen)
	call	gotoXY
	_mov	ecx,wXlen
.bottom:
	inc	edi
	stosb
	loop	.bottom

	mov	esi,sHeader
	call	write
	mov	esi,sText
	call	write
	mov	esi,sStatus
	call	write
	ret

;
; Screen library itself
;

%assign	MAX_X	200
%assign	MAX_Y	100

;
;emulate pread/pwrite on earlier kernels
;

%macro	PREAD 0
%if __KERNEL__ >=22
	sys_pread
%else
	pusha
	sys_lseek EMPTY,esi,SEEK_SET
	popa
	sys_read
%endif
%endmacro

%macro	PWRITE 0
%if __KERNEL__ >=22
	sys_pwrite
%else
	pusha
	sys_lseek EMPTY,esi,SEEK_SET
	popa
	sys_write
%endif
%endmacro

;
;
;
cOpenError	db	"Can't open "
cScreenDevice	db	"/dev/vcsa",EOL
cNL		db	0xa
cOpenErrorLen	equ	$-cOpenError

open_screen:
	pusha

;
; open /dev/vcsa
;
	sys_open cScreenDevice, O_RDWR
	mov	[sHandle],eax
	test	eax,eax
	js	open_screen_error
	
;
; get console size and cursor position
;
	sys_read eax,sMaxY,4
	
	movzx	eax,word [ecx]
	mul	ah
	mov	[sLen],eax
	
;
;set non-blocking mode and one-char-at-a-time mode for STDIN
;
	sys_fcntl STDIN,F_SETFL,(O_RDONLY|O_NONBLOCK)
	sys_ioctl STDIN,TCGETS,sattr				;saved until restore
	sys_ioctl EMPTY,EMPTY,tattr				;will be modified
	and	dword [tattr+termios.c_lflag],~(ICANON|ECHO|ISIG)	;disable erase/fill processing, echo, signals
	or	dword [tattr+termios.c_oflag],OPOST|ONLCR		;enable output processg, NL<-CR/NL
	and	dword [tattr+termios.c_iflag],~(INPCK|ISTRIP|IXON|ICRNL);disable parity chk, 8th bit strip,start/stop prot.
	mov	byte [tattr+termios.c_cc+VTIME],0			;timo * 1/10 s (if ~ICANON)
	mov	byte [tattr+termios.c_cc+VMIN],1			;min no. of chars for a single read opr
	sys_ioctl STDIN,TCSETS,tattr

	popa
	ret

open_screen_error:
	sys_write STDIN,cOpenError,cOpenErrorLen
	jmp	do_exit

close_screen:
	pusha
	sys_ioctl STDIN,TCSETS,sattr
	sys_close [sHandle]
	popa
	ret

;
;write string to the screen
;
;<esi	string offset
;
write:
	pusha
	_mov	eax,0
	mov	ah,cDefAttr
.loop:
	lodsb
	or	al,al
	jz	.end
	cmp	al,cAttr
	jz	.attr
	cmp	al,cXY
	jnz	.put
	push	eax
	lodsw
	mov	ecx,eax
	call	gotoXY
	pop	eax
	jmp	short .loop
.attr:
	lodsb
	mov	ah,al
	jmp	short .loop
.put:
	stosw
	jmp	short .loop
.end:
	popa
	ret

;
;set cursor position
;
;<ch	X
;<cl	Y
;
;>EDI	offset

gotoXY:
	push	eax
	mov	eax,ecx
	mul	byte [sMaxX]
	mov	edi,eax
	movzx	eax,ch
	add	edi,eax
	shl	edi,1
	add	edi,vMem
	pop	eax
	ret

;
;get cursor position
;
;>ch	X
;>cl	Y
;
;getXY:
;	pusha
;	sys_pread [sHandle], sCurY, 2, 2
;	popa
;	movzx	ecx,word [sCurY]
;	ret

;<ch	X
;<cl	Y
;<edx	number of bytes
;<ebx	buffer

vread:
	pusha
	call	vprepare
	PREAD
	popa
	ret

vwrite:
	pusha
	call	vprepare
	PWRITE
	popa
	ret

vprepare:
	call	gotoXY
	lea	esi,[edi + 4]
	sub	esi,vMem
	mov	ecx,ebx
	shl	edx,1
	mov	ebx,[sHandle]
	ret



UDATASEG

sMaxY		resb	1
sMaxX		resb	1
sCurY		resb	1
sCurX		resb	1
sLen		resd	1
sHandle		resd	1

tmp		resd	1

vMem		resb	MAX_X * MAX_Y * 2
vMemS		resb	MAX_X * MAX_Y * 2

tattr B_STRUC termios,.c_iflag,.c_oflag,.c_lflag,.c_cc

sattr B_STRUC termios

END
