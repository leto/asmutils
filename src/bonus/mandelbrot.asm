; MANDELBROT GENERATOR 
;
; $Id: mandelbrot.asm,v 1.1 2006/02/09 07:36:07 konst Exp $
;
; Original code by Tenie Remmel & John Eckerdal
; ported to Linux/framebuffer by Stephan Walter <stephan.walter@gmx.ch>
;
; (c) 2002 by Stephan Walter - licensed under the GNU GPL
;
; v1.0 2002-06-02 --- First release (175 bytes)
;
;
; Well, it's nothing new, just another Mandelbrot proggie. It uses
; 640x480x8 fb mode (like all the other asmutils gfx programs).
; Use Ctrl-C to exit.
;
; Color palette is not set. If you run fire256 or X11 before running
; this program, you'll get different colors.
;
; The size of the DOS/INT10h program was 61 bytes, my version has 175 :-(
;
;
; Original file comment:
;==========================================================================
;This is a small implementation of a mandelbrot generator. I've found this
;gem a some time ago in a swedish fido-net meeting as a UUencoded file. All
;comments have been inserted by me (John Eckerdal). I have tried to give
;some information about what the program acutally calculates. This
;information might however be incorrect.
;The source and a compiled version is available for download (1092 bytes).
;
; mandelbrot plotter, 61 bytes - Tenie Remmel
;==========================================================================

%include "system.inc"

%assign SIZE_X	640
%assign	SIZE_Y	480
%assign VMEM_SIZE	SIZE_X*SIZE_Y

CODESEG

START:
	sys_open fb, O_RDWR
	sys_mmap EMPTY, VMEM_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, eax
	mov edi, eax		; we'll use stosb

	_mov ecx, SIZE_Y	; "xor ecx, ecx", "inc ch" is one byte smaller
outer_loop:
	_mov esi, SIZE_X
inner_loop:
	_mov ebp, 127 		; number of iterations. Can be >127 but then
				; it uses 2 more bytes. >255 makes no sense
				; because this is used for the pixel color.

	xor ebx, ebx		;  re := 0
	xor edx, edx		;  im := 0

complex_loop:
	push edx
	mov eax, ebx
	sub eax, edx		;  eax := re - im
	add edx, ebx		;  edx := re + im
	imul edx		;  u := (re-im) * (im+re) = re^2 - im^2
	sar eax, 8		;  u := u / 2^8
	pop edx

	xchg ebx, eax

	sub ebx, esi		;  new_re := u - width
        
	imul edx
	shld edx, eax, 25	;  edx := 2(re * im) / 2^8

	sub edx, ecx		;  new_im := 2(rm * im) / 2^8 - height

	test dh,dh		; if j>=256 plot pixel
	jg short plot_color

	dec ebp			; next iteration
	jnz short complex_loop

plot_color:
	xchg ebp,eax
	stosb			; plot pixel

	dec esi
	jnz short inner_loop

	loop outer_loop

schluss:			; of course we should use sys_exit,
	jmps schluss		; but this loop is smaller and the
				; picture won't get overridden by the
				; shell prompt. Use Ctrl-C to exit.

fb	db	"/dev/fb0"

END
