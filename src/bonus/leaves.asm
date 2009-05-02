;Copyright (C) 1996-2001 Konstantin Boldyshev <konst@linuxassembly.org>
;
;$Id: leaves.asm,v 1.10 2006/02/09 07:48:39 konst Exp $
;
;leaves		-	Linux fbcon intro in 394 bytes
;
;Once I've took one of my old DOS intros made in tasm, and rewrote it
;for nasm and Linux/fbcon.. Uhm.. I've got 394 bytes.
;(DOS 16-bit version was 381 bytes long)
;
;This intro is the smallest implementation
;of linear transformation with recursion (AFAIK).
;
;This intro was showed on few parties and produced an explosion of interest :)
;(however it wasn't nominated, because it doesn't fit into rules [yet])
;
;Intro MUST be run only in 640x480x256 mode (vga=0x301 in lilo.conf).
;You will see garbage or incorrect colors in other modes.
;(of course you must have framebuffer support enabled in your kernel)
;Warning! Intro assumes that everything is ok with the system (/dev/fb0 exists,
;can be opened and mmap()ed, correct video mode is set, and so on). So, if you
;ain't root, check permissions on /dev/fb0 first, or you will not see anything.
;
;If everything is ok you should see two branches of green leaves,
;and kinda wind blowing on them ;)
;
;Intro runs for about a minute and a half (depends on machine),
;and is interruptible at any time with ^C.
;
;Here is the source. It is quite short and self-explaining..
;Well, actually source is badly optimized for size, contains
;some Linux specific tricks, and can be hard to understand.
;
;Source is quite portable, your OS must support 32bit flat memory model,
;and you need to implement putpixel() and initialization part for your OS.
;
;Ah, /if haven't guessed yet/ license is GPL, so enjoy! :)

%include "system.inc"

%assign	SIZE_X	640
%assign	SIZE_Y	480
%assign	DEPTH	8

%assign	VMEM_SIZE	SIZE_X*SIZE_Y

;%define MaxX 640.0
;%define MaxY 480.0
;%define xc MaxX/2
;%define yc MaxY/2
;%define xmin0 100.0
;%define xmax0 -xmin0
;%define ymin0 xmin0
;%define ymax0 -ymin0

%define	OFFSET(x) byte ebp + ((x) - parameters)

CODESEG

;
;al	-	color
;

putpixel: 
	push	edx		
        lea	edx,[ebx+ebx*4]	;compute offset
        shl	edx,byte 7	;multiply by 640
	add	edx,[esp+8]
	mov	[edx+esi],al	;write to frame buffer
	pop	edx
_return:
        ret

;
; recursive function itself
;

leaves: 
        mov	ecx,[esp+12]
        test	cl,cl
	jz	_return

	fld	dword [OFFSET(f)]	;[f]
        mov	[esp-13],cl
        mov	eax,[edi]

	fld	st0
        push	ecx
        sub	esp,byte 8
	fld	st0
	mov	edx,esp
	fmul	dword [edx+16]
	fadd	dword [OFFSET(y1coef)]	;[y1coef]
	fistp	dword [edx]
        mov	ebx,[edx]

	fmul	dword [edx+20]
	fsubr	dword [OFFSET(x1coef)]	;[x1coef]
	fistp	dword [edx]

        call	putpixel

	fmul	dword [edx+20]
	fadd	dword [OFFSET(x2coef)]	;[x2coef]
	fistp	dword [edx]
        call	putpixel

	inc	edi
        cmp	edi,color_end
        jl	.rec
	sub	edi,byte color_end-color_begin
.rec:

	fld	dword [OFFSET(b)]	;[b]
	fld	dword [OFFSET(a)]	;[a]
	fld	st1
	fld	st1
	fxch
	fmul	dword [edx+16]
	fxch
	fmul	dword [edx+20]
	fsubp	st1
	fstp	dword [edx-8]

	fmul	dword [edx+16]
	fxch
	fmul	dword [edx+20]
	faddp	st1

	dec	ecx
        push	ecx

        sub	esp,byte 8
	fstp	dword [esp]

        call	leaves		;esp+12

	mov	edx,esp
	fld	dword [OFFSET(d)]	;[d]
	fld	dword [edx+28]
	fld	dword [OFFSET(c)]	;[c]
	fld	dword [OFFSET(x0)]	;[x0]
	fsub	to st2
	fld	st3
	fld	st2
	fxch
	fmul	st4
	fxch
	fmul	dword [edx+32]
	faddp	st1
	fstp	dword [edx-8]

	fxch
	fmulp	st2
	fxch	st2
	fmul	dword [edx+32]
	fsubp	st1
	faddp	st1

        push	ecx

        sub	esp,byte 8
	fstp	dword [esp]

        call	leaves

        add	esp,byte 12*2+8

        pop	ecx
.return:
        ret

;
; main()
;

START:
	_mov	ebp,parameters

	lea	ebx,[OFFSET(fb)]
	sys_open EMPTY, O_RDWR

;	test	eax,eax			;have we opened file?
;	js	do_exit

	_mov	ecx,VMEM_SIZE

%if	__SYSCALL__=__S_KERNEL__
;prepare structure for mmap on the stack
	_push	0			;.offset
	_push	eax			;.fd
	_push	MAP_SHARED		;.flags
	_push	PROT_READ|PROT_WRITE	;.prot
	_push	ecx			;.len
	_push	0			;.addr
	sys_oldmmap esp
%else
	push	ebp
	sys_mmap 0,EMPTY,PROT_READ|PROT_WRITE,MAP_SHARED,eax,0
	pop	ebp
%endif
;	test	eax,eax		;have we mmaped file?
;	js	do_exit

	mov	esi,eax

;clear screen
	mov	edi,esi
	xor	eax,eax
	rep	stosb

;leaves
	lea	edi,[OFFSET(color_begin)]
;	lea	edi,[ebp + 0x24]	;ColorBegin-Params
        _push	28			;recursion depth
	_push	eax
	_push	eax
        call	leaves

;close fb
;	sys_munmap esi,VMEM_SIZE
;	sys_close mm.fd

do_exit:
	sys_exit

;
;
;

parameters:

a	dd	0.7
b	dd	0.2
c	dd	0.5
d	dd	0.3

f	dd	0xc0400000	;MaxY/(ymax0-ymin0)*3/2	
x1coef	dd	0x433b0000	;MaxX-MaxY*4/9-yc
y1coef	dd	0x43dc0000	;MaxY/4+xc
x2coef	dd	0x43e28000	;MaxY*4/9+yc
x0	dd	112.0

color_begin:
	db	0,0,2,0,0,2,10,2
color_end:

fb	db	"/dev/fb0";,EOL

END

;/*
; leaves.c : C implementation using /dev/fb0
;
; takes ~2KB
;*/
;
;#include <unistd.h>
;#include <fcntl.h>
;#include <sys/mman.h>
;
;typedef unsigned char byte;
;
;#define MaxX 640
;#define MaxY 480
;#define VMEM_SIZE MaxX * MaxY
;
;#define xc	MaxX/2
;#define yc	MaxY/2
;#define xmin0	100
;#define xmax0	-xmin0
;#define ymin0	xmin0
;#define ymax0	-ymin0
;
;#define colornum 8
;
;int color = 0;
;
;byte *p, ColorTable[colornum] = { 0, 0, 2, 0, 0, 2, 10, 2 };
;
;float	f = MaxY / (ymax0 - ymin0) * 3 / 2, x0 = 112,
;	x1coef = MaxX - MaxY * 4 / 9 - yc, y1coef = MaxY / 4 + xc,
;	x2coef = MaxY * 4 / 9 + yc,
;	a = 0.7, b = 0.2, c = 0.5, d = 0.3;
;
;inline void putpixel(int x, int y, byte color)
;{
;    *(p + y * MaxX + x) = color;
;}
;
;void leaves(float x, float y, byte n)
;{
;    int y1;
;
;    if (n <= 0) return;
;
;    y1 = f * x + y1coef;
;
;    putpixel(x1coef - f * y, y1, ColorTable[color]);
;    putpixel(f * y + x2coef, y1, ColorTable[color]);
;
;    if (++color > colornum - 1) color = 0;
;
;    leaves(a * x + b * y, b * x - a * y, n - 1);
;    leaves(c * (x - x0) - d * y + x0, d * (x - x0) + c * y, n - 1);
;}
;
;int main(void)
;{
;    int i, h;
;
;    h = open("/dev/fb0", O_RDWR);
;    p = mmap(0, VMEM_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, h, 0);
;
;    for (i = 0; i < VMEM_SIZE; i++) *(p + i) = 0;
;
;    leaves(0, 0, 28);
;
;    munmap(p, VMEM_SIZE);
;    close(h);
;}
