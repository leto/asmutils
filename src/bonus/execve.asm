;Copyright (C) 1999-2001 Konstantin Boldyshev <konst@linuxassembly.org>
;
;$Id: execve.asm,v 1.5 2006/02/09 07:43:45 konst Exp $
;
;execve/regs
;
;execute a given program / show startup registers info
;
;example: regs
;	  execve regs

%include "system.inc"

struc regs
.eax	resd	1
.ebx	resd	1
.ecx	resd	1
.edx	resd	1
.esi	resd	1
.edi	resd	1
.ebp	resd	1
.esp	resd	1
.eflags	resd	1
.cs	resd	1
.ds	resd	1
.es	resd	1
.fs	resd	1
.gs	resd	1
.ss	resd	1
.argc	resd	1
.argv0	resd	1
.argv1	resd	1
.envp0	resd	1
endstruc

CODESEG

;>EDI
;<EDX
StrLen:
	push	edi
	mov	edx,edi
	dec	edi
.l1:
	inc	edi
	cmp	[edi],byte 0
	jnz	.l1
	xchg	edx,edi
	sub	edx,edi
	pop	edi
	ret

;>EAX
;<EDI
LongToStr:
	pusha
	sub	esp,4
	mov	ebp,esp
	mov	[edi],word "0x"
	inc	edi
	inc	edi
	mov	esi,edi
	push	esi
	mov     [ebp],eax
	_mov	ecx,16	;10 - decimal
	_mov	esi,0
.l1:
        inc     esi
	xor	edx,edx
	mov	eax,[ebp]
	div	ecx
	mov	[ebp],eax
        mov     al,dl

;dec convertion
;	add	al,'0'
;	add	al,0x90
;	daa
;	adc	al,0x40
;	daa

;hex convertion
	cmp	al,10
	sbb	al,0x69
	das

        stosb
	xor	eax,eax
	cmp	eax,[ebp]
	jnz	.l1
        stosb
	pop	ecx
	xchg	ecx,esi
        shr	ecx,1
	jz	.l3
	xchg	edi,esi
	dec	esi
	dec	esi
.l2:
        mov	al,[edi]
	xchg	al,[esi]
	stosb
	dec     esi
	loop    .l2
.l3:
	add	esp,4
	popa
	ret


PrintRegs:

	mov	esi,r
	mov	ebp,rstring

.mainloop:
	push	ecx
	mov	ecx,ebp
.l1:
	inc	ebp
	cmp	[ebp],byte 0
	jnz	.l1
	mov	edx,ebp
	sub	edx,ecx
	sys_write STDOUT
	inc	ebp
	lodsd
	mov	edi,tmpstr
	call	LongToStr
	call	StrLen
	sys_write STDOUT,edi
	sys_write EMPTY,lf,1
	pop	ecx
	loop	.mainloop
	ret

rstring:

db	"EAX	:	",EOL
db	"EBX	:	",EOL
db	"ECX	:	",EOL
db	"EDX	:	",EOL
db	"ESI	:	",EOL
db	"EDI	:	",EOL
db	"EBP	:	",EOL
db	"ESP	:	",EOL
db	"EFLAGS	:	",EOL
db	"CS	:	",EOL
db	"DS	:	",EOL
db	"ES	:	",EOL
db	"FS	:	",EOL
db	"GS	:	",EOL
db	"SS	:	",EOL
db	"argc	:	",EOL
db	"&argv[0]	:	",EOL
db	"&argv[1]	:	",EOL
db	"&envp[0]	:	",EOL

lf:
line	db	__n,"--------------------------",__n
s_line		equ	$-line

before	db	"Before sys_execve:"
s_before	equ	$-before

inside	db	__n,"Inside called program:"
s_inside	equ	$-inside


START:
	mov	[r.eax],eax
	mov	eax,r
	pushfd
	pop	dword [eax+regs.eflags]
	mov	[eax+regs.ebx],ebx
	mov	[eax+regs.ecx],ecx
	mov	[eax+regs.edx],edx
	mov	[eax+regs.esi],esi
	mov	[eax+regs.edi],edi
	mov	[eax+regs.ebp],ebp
	mov	[eax+regs.esp],esp
	mov	[eax+regs.cs],cs
	mov	[eax+regs.ds],ds
	mov	[eax+regs.es],es
	mov	[eax+regs.fs],fs
	mov	[eax+regs.gs],gs
	mov	[eax+regs.ss],ss

	pop	ebp
	mov	[eax+regs.argc],ebp
	pop	esi
	mov	[eax+regs.argv0],esi
	pop	edi
	mov	[eax+regs.argv1],edi
	mov	edx,[esp+ebp*4]
	mov	[eax+regs.envp0],edx
	
	push	edi			;restore argv/argc back
	push	esi
	push	ebp

;
;how we are called?
;

.a1:	lodsb
	or	al,al
	jnz	.a1
	cmp	dword [esi-5],"regs"
	jnz	do_execve

	_mov	ecx,19
	call	PrintRegs
quit:
	sys_exit_true

do_execve:
	pop	ebp			;get argc
	dec	ebp			;exit if no args
	jz	quit
.go:
	pop	esi			;get our name
	mov	ebx,[esp]		;ebx -- program name (*)
	mov	ecx,esp			;ecx -- arguments (**)
	lea	edx,[esp+(ebp+1)*4]	;edx -- environment (**)

;now we will try to pass some magic values to launched program
;on Linux 2.0 program will get them!

	mov	esi,0x11223344
	mov	edi,0x55667788
	mov	ebp,0x9900AABB

	mov	eax,r
	mov	[eax+regs.ebx],ebx
	mov	[eax+regs.ecx],ecx
	mov	[eax+regs.edx],edx

	mov	[eax+regs.esi],esi
	mov	[eax+regs.edi],edi
	mov	[eax+regs.ebp],ebp

	pusha
	sys_write STDOUT,before,s_before
	sys_write EMPTY,line,s_line
	_mov	ecx,15
	call	PrintRegs
	sys_write STDOUT,inside,s_inside
	sys_write EMPTY,line,s_line
	popa

	sys_execve

UDATASEG

r I_STRUC regs
.eax	resd	1
.ebx	resd	1
.ecx	resd	1
.edx	resd	1
.esi	resd	1
.edi	resd	1
.ebp	resd	1
.esp	resd	1
.eflags	resd	1
.cs	resd	1
.ds	resd	1
.es	resd	1
.fs	resd	1
.gs	resd	1
.ss	resd	1
.argc	resd	1
.argv0	resd	1
.argv1	resd	1
.envp0	resd	1
I_END

tmpstr	resd	10

END
