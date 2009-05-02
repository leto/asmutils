;Copyright (C) 1999-2002 Konstantin Boldyshev <konst@linuxassembly.org>
;Copyright (C) 1999 Cecchinel Stephan <inter.zone@free.fr>
;
;$Id: libc.asm,v 1.16 2006/02/18 09:39:33 konst Exp $
;
;hackers' libc
;
;Yes, this is the most advanced libc ever seen.
;It uses advanced technologies which are possible only with assembly.
;Two main features that make this libc outstanding:
;1) calling convention can be configured AT RUNTIME (cdecl is default)
;2) THE smallest size
;
;It uses mixed code-data database approach for syscalls,
;resulting in extremely small size.
;
;Well, there's still a lot of work to be done.
;
;0.01: 10-Sep-1999	initial alpha pre beta 0 non-release
;0.02: 24-Dec-1999	first working version
;0.03: 21-Feb-2000	fastcall support
;0.04: 20-Jul-2000	fixed stupid bug/misprint, merged clib.asm & string.asm
;			printf()
;0.05: 16-Jan-2001	usual functions now work with both cdecl and fastcall,
;			added PIC support (and __GET_GOT macro),
;			added __ADJUST_CDECL3 macro,
;			syscall mechanism rewritten (size improved),
;			separated and optimized sprintf(),
;			printf() implemented via sprintf(),
;			lots of other various fixes (KB)
;			finally ready for additions and active development.
;0.06: 28-Jan-2001	added __start_main - it is called from stub in order
;			to prepare main() arguments (argc, argv, envp),
;			PIC fixes (KB)
;0.07: 25-Feb-2001	added __VERBOSE__, memcmp(), getenv() (KB)
;0.08: 20-Jan-2002	strlen() bugfix, various fixes (KB)
;0.09: 03-Mar-2002	__start_main fastcall fix (KB)
;0.10: 18-Feb-2006	static build fix (KB)

%undef __ELF_MACROS__

%include "system.inc"

%define __PIC__		;build PIC version
;%define	__VERBOSE__	;treat stack with care

;
; macro used for function declaration
;

%macro _DECLARE_FUNCTION 1-*
%rep %0
    global %1:function
%rotate 1
%endrep
%endmacro

;
; macro used for syscall declaration
;
;%1	syscall name
;%2	number of parameters
;
;Ok, what is written below?
;Yes - a really dirty trick, but it really saves size.
;This is the thing I like assembly for,
;and this why this libc is the most advanced :)
;
;This macro generates the following code:
;six bytes	-	call instruction
;one byte	-	number of syscall parameters (<0 means always cdecl)
;one byte	-	syscall number (two bytes on BSD systems)
;
;So, each syscall will take only 8 bytes (9 bytes on BSD systems)
;in executable image. We use call instruction to push return address,
;and then find out syscall number and number of parameters using
;this address in __system_call function. ret instructions is also
;missing, because we will handle correct return in __system_call too.

%macro _DECLARE_SYSCALL 2
    global %1:function
%1: call	__system_call
    db	%2	;number of parameters
%ifndef	__BSD__
    db	SYS_%{1};syscall number
%else
    dw	SYS_%{1}
%endif
%endmacro

;
;PIC handling
;

%define	__EXT_VAR(x) [ebx + (x) wrt ..got]
%define	__INT_VAR(x) ebx + (x) wrt ..gotoff

%macro __GET_GOT 0
	call	__get_GOT
%%get_GOT:
%define gotpc %%get_GOT wrt ..gotpc
	add	ebx,_GLOBAL_OFFSET_TABLE_ + $$ - gotpc
%undef gotpc
%endmacro

;adjust cdecl call (1 - 3 parameters)
;
;%1		stack frame to add
;%2 - %4	registers

%macro	__ADJUST_CDECL3	2-4

;	_mov	%2,eax
;%if %0>2
;	_mov	%3,edx
;%if %0>3
;	_mov	%4,ecx
;%endif
;%endif

%ifdef __PIC__
	push	ebx
	__GET_GOT
	mov	ebx,__EXT_VAR(__cc)
	cmp	byte [ebx],0
	pop	ebx
%else
	cmp	byte [__cc],0
%endif
	jnz	%%fc

	mov	%2,[esp + %1 + 4 ]
%if %0>2
	mov	%3,[esp + %1 + 8 ]
%if %0>3
	mov	%4,[esp + %1 + 12]
%endif
%endif
%%fc:

%endmacro

;
;for accessing registers after pusha
;
%define	__ret	esp+4*8
%define	__eax	esp+4*7
%define	__ecx	esp+4*6
%define	__edx	esp+4*5
%define	__ebx	esp+4*4
%define	__esp	esp+4*3
%define	__ebp	esp+4*2
%define	__esi	esp+4*1
%define	__edi	esp+4*0

CODESEG

%ifdef __PIC__
	__GET_GOT
	lea	ecx,[__INT_VAR(__libc_banner)]
%else
	mov	ecx,__libc_banner
%endif
	sys_write STDOUT,EMPTY,__LIBC_BANNER_LEN
	sys_exit 0

__libc_banner		db	"a r e   y o u   s i c k ?", __n
__LIBC_BANNER_LEN	equ	$ - __libc_banner

%ifdef __PIC__
__get_GOT:
	mov	ebx,[esp]
	ret
%endif


extern _GLOBAL_OFFSET_TABLE_

;**************************************************
;*             INTERNAL FUNCTIONS                 *
;**************************************************

;
;perform a system call (up to 6 arguments)
;

__system_call:
	pusha

	mov	eax,[__esp]		;load number of syscall args into eax
	mov	eax,[eax]
	movzx	eax,byte [eax]
	test	al,al
	jz	.ssn			;no args
%ifdef	__VERBOSE__
	jns	.sk1			;usual call
	neg	al			;always cdecl call
	jmps	.cdecl
%else
	js	.cdecl
%endif
.sk1:
%ifdef __PIC__
	__GET_GOT
	mov	ebx,__EXT_VAR(__cc)
	cmp	byte [ebx],0
%else
	cmp	byte [__cc],0
%endif
	jnz	.fc

%define _STACK_ADD 8 + 4*8
%macro _JZ_SSN_ 0
%ifdef	__VERBOSE__
	dec	eax
	jz	.ssn
%endif
%endmacro

.cdecl:
	mov	ebx,[esp + _STACK_ADD]		;1st arg
	_JZ_SSN_
	mov	ecx,[esp + _STACK_ADD + 4]	;2nd arg
	_JZ_SSN_
	mov	edx,[esp + _STACK_ADD + 8]	;3rd arg
	_JZ_SSN_
	mov	esi,[esp + _STACK_ADD + 12]	;4th arg
	_JZ_SSN_
	mov	edi,[esp + _STACK_ADD + 16]	;5th arg
	_JZ_SSN_
	mov	ebp,[esp + _STACK_ADD + 20]	;6th arg
	jmps	.ssn

.fc:
	mov	ebx,[__eax]			;1st arg
	_JZ_SSN_
	xchg	ecx,edx				;2nd & 3rd arg
	_JZ_SSN_
	_JZ_SSN_
	mov	esi,[esp + _STACK_ADD]		;4th arg
	_JZ_SSN_
	mov	edi,[esp + _STACK_ADD + 4]	;5th arg
	_JZ_SSN_
	mov	ebp,[esp + _STACK_ADD + 8]	;6th arg

%undef _STACK_ADD

.ssn:
	mov	eax,[__esp]		;set syscall number
	mov	eax,[eax]
%ifndef	__BSD__
	movzx	eax,byte [eax + 1]	;return address + 1
%else
	movzx	eax,word [eax + 1]	;return address + 1
%endif
	sys_generic

	cmp	eax,-4095
	jb	.leave

;	test	eax,eax
;	jns	.leave

	neg	eax

%ifdef __PIC__
	__GET_GOT
	mov	ebx,__EXT_VAR(errno)
	mov	[ebx],eax
%else
	mov	[errno],eax
%endif
	or	eax,byte -1
.leave:
	mov	[__eax + 4],eax		;replace return address with eax
	popa
	pop	eax			;now get it back
	ret				;and return to previous caller

;
;
;

_DECLARE_SYSCALL	open,	-3	;<0 means always cdecl
_DECLARE_SYSCALL	close,	1
_DECLARE_SYSCALL	read,	3
_DECLARE_SYSCALL	write,	3
_DECLARE_SYSCALL	lseek,	3
_DECLARE_SYSCALL	chmod,	2
_DECLARE_SYSCALL	chown,	2
_DECLARE_SYSCALL	pipe,	1
_DECLARE_SYSCALL	link,	2
_DECLARE_SYSCALL	symlink,2
_DECLARE_SYSCALL	unlink,	1
_DECLARE_SYSCALL	mkdir,	1
_DECLARE_SYSCALL	rmdir,	1

_DECLARE_SYSCALL	exit,	1
_DECLARE_SYSCALL	fork,	0
_DECLARE_SYSCALL	execve,	3
_DECLARE_SYSCALL	uname,	1
_DECLARE_SYSCALL	ioctl,	3
_DECLARE_SYSCALL	alarm,	1
_DECLARE_SYSCALL	nanosleep,	2
_DECLARE_SYSCALL	kill,	2
_DECLARE_SYSCALL	signal,	2
_DECLARE_SYSCALL	wait4,	4

;_DECLARE_SYSCALL	stat,	2
_DECLARE_SYSCALL	fstat,	2
_DECLARE_SYSCALL	lstat,	2

_DECLARE_SYSCALL	getuid,	0
_DECLARE_SYSCALL	getgid,	0


_DECLARE_FUNCTION	_fastcall

_DECLARE_FUNCTION	memcpy, memset, memcmp
_DECLARE_FUNCTION	strlen
_DECLARE_FUNCTION	strtol
_DECLARE_FUNCTION	itoa
_DECLARE_FUNCTION	printf, sprintf
_DECLARE_FUNCTION	getenv

_DECLARE_FUNCTION	__start_main

;
;
;ebp	-	main() address

__start_main:
	pop	ebp			;main() address
	pop	eax			;argc
	lea	ecx,[esp + eax * 4 + 4]	;**envp
%ifdef	__PIC__
	__GET_GOT
	mov	ebx,__EXT_VAR(__envp)
	mov	[ebx],ecx
%else
	mov	[__envp],ecx
%endif
	mov	edx,esp			;**argv
	push	ecx
	push	edx
	push	eax
	call	ebp
	push	eax
	call	exit

;**************************************************
;*          GLOBAL LIBRARY FUNCTIONS              *
;**************************************************

;void fastcall(int regnum)
;
;set fastcall/cdecl calling convention
;note: always uses fasctall convention
;
;<EAX	regnum

_fastcall:
%ifdef	__PIC__
	push	ebx
	__GET_GOT
	mov	ebx,__EXT_VAR(__cc)
	mov	[ebx],eax
	pop	ebx
%else
	mov	[__cc],eax
%endif
	ret

;void memset(void *s, int c, size_t n)
;
;fill an array of memory
;
;<EDX	*s
;<AL	c
;<ECX	n

memset:
	push	edx
	push	ecx
	push	eax

	xchg	eax,edx

	__ADJUST_CDECL3 4*3,edx,eax,ecx

.real:

%if __OPTIMIZE__=__O_SPEED__
	cmp	ecx,byte 20	;if length is below 20 , better use byte fill
	jl	.below20
	mov	ah,al		;expand al to eax like alalalal
	push	ax
	shl	eax,16
	pop	ax
.lalign:
	test	dl,3		;align edx on a 4 multiple
	jz	.align1
	mov	[edx],al
	inc	edx
	dec	ecx
	jnz	.lalign
	jmps	.memfin
.align1:
	push	ecx
        shr	ecx,3		;divide ecx by 8
	pushf
.boucle:
	mov	[edx],eax	;then fill by 2 dword each times
	mov	[edx+4],eax	;it is faster than stosd (on PII)
	add	edx,byte 8
	dec	ecx
	jnz	.boucle
	popf
	jnc	.boucle2
	mov	[edx],eax
	add	edx,byte 4
.boucle2:
	pop	ecx
        and	ecx,byte 3
        jz	.memfin
.below20:
	mov	[edx+ecx-1],al
	dec	ecx
	jnz	.below20
.memfin:

%else		;__O_SIZE__

	push	edi
	cld
	mov	edi,edx
	rep	stosb
	pop	edi

%endif		;__OPTIMIZE__

	pop	eax
	pop	ecx
	pop	edx
	ret

;void *memcpy(void *dest,const void *src, size_t n)
;
;<EDI	*dest
;<ESI	*src
;<ECX	n

memcpy:

%if __OPTIMIZE__=__O_SPEED__
%define	_STACK_ADD 4*3
	push	ecx
	push	edi
	push	esi
%else
%define	_STACK_ADD 4*8
	pusha
%endif

	mov	edi,eax
	mov	esi,edx
	__ADJUST_CDECL3 _STACK_ADD,edi,esi,ecx
.real:
	cld
	rep	movsb

%if __OPTIMIZE__=__O_SPEED__
	pop	esi
	pop	edi
	pop	ecx
%else
	popa
%endif
%undef	_STACK_ADD

	ret

;int memcmp(void *s1, void *s2, size_t n)
;
;compare memory areas
;
;<ESI	*s1
;<EDI	*s2
;<ECX	n

memcmp:
	push	esi
	push	edi
	push	ecx

	__ADJUST_CDECL3 4*3,esi,edi,ecx
.real:
	cld
	rep	cmpsb
	jz	.ret
	sbb	eax,eax
	or	eax,byte 1
.ret:
	pop	ecx
	pop	edi
	pop	esi
	ret

;char *getenv(char *)
;
;<ESI	*s

getenv:
	pusha

	mov	edi,eax
	__ADJUST_CDECL3 4*8,edi

%ifdef	__PIC__
	__GET_GOT
	mov	ebx,__EXT_VAR(__envp)
	mov	ebx,[ebx]
%else
	mov	ebx,[__envp]
%endif
	mov	edx,edi
	cld
	xor	eax,eax
        or	ecx,byte -1
	repne	scasb
	not	ecx
	dec	ecx
	mov	eax,ecx

.next_var:
	mov	ecx,eax
	mov	esi,edx
	mov	edi,[ebx]
	test	edi,edi
	jz	.ret
	rep	cmpsb
	jz	.found
	add	ebx,byte 4
	jmps	.next_var
.found:
	inc	edi		;assume = is next
.ret:
	mov	[__eax],edi
	popa
	ret

;size_t strlen(const char *s)
;
;<EDX	*s
;
;>EAX

strlen:
	push	edx
	__ADJUST_CDECL3 4*1,eax

	mov	edx,eax
.real:
%if __OPTIMIZE__=__O_SPEED__
	push	ecx
	test	dl,3
	jz	.boucle
	cmp	byte[eax],0
	jz	.strfi
	cmp	byte[eax+1],0
	jz	.ret1
	cmp	byte[eax+2],0
	jnz	.align
	add	eax,byte 2
	jmps	.strfi
.align:	add	eax,byte 3
	and	eax,byte -4
.boucle:		;normally the whole loop is 7 cycles (for 8 bytes)
	mov	ecx,dword[eax]
	test	cl,cl
	jz	.strfi
	test	ch,ch
	jz	.ret1
	test	ecx,0xFF0000
	jz	.ret2
	shr	ecx,24
	jz	.ret3
	mov	ecx,dword[eax+8]
	test	cl,cl
	jz	.ret4
	test	ch,ch
	jz	.ret5
	test	ecx,0xFF0000
	jz	.ret6
	add	eax,byte 8
	shr	ecx,4
	jnz	.boucle
	dec	eax
	jmps	.strfi
.ret1:	inc	eax
	jmps	.strfi
.ret2:	add	eax,byte 2
	jmps	.strfi
.ret3:	add	eax,byte 3
	jmps	.strfi
.ret4:	add	eax,byte 4
	jmps	.strfi
.ret5:	dec	eax
.ret6:	add	ecx,byte 6
.strfi:	sub	eax,edx
	pop	ecx

%else		;__O_SIZE__

	xor	eax,eax
.boucle:
	cmp	byte[edx+eax],1
	inc	eax
	jnc	.boucle
	dec	eax

%endif		;__OPTIMIZE__
	pop	edx
	ret

;itoa (unsigned long value, char *string, int radix)
;
;print 32 bit number as binary,octal,decimal,or hexadecimal value
;
;<EAX	unsigned long value
;<EDI	char *string
;<ECX	base    (2, 8, 10, 16, or another one)

itoa:
	pusha

	mov	edi,edx

	__ADJUST_CDECL3 4*8,eax,edi,ecx

.real:

.now:
	call	.printB
	mov	byte [edi],0	;zero terminate the string 
	popa
	ret

.printB:
	sub	edx,edx 
	div	ecx 
	test	eax,eax 
	jz	.print0
	push	edx
	call	.printB
	pop	edx
.print0:
	add	dl,'0'
	cmp	dl,'9'
	jle	.print1
	add	dl,0x27
.print1:
	mov	[edi],dl
 	inc	edi
 	ret

;int sprintf(char *str, const char *format, ...)
;
;

sprintf:
	pusha
	
	lea	edx,[esp + 4*8 + 12]	;preload argument (dangerous?)
	mov	esi,[esp + 4*8 + 8]	;*format
	mov	edi,[esp + 4*8 + 4]	;*str

	push	edi

	cld
.boucle:
	lodsb
	test	al,al
	jz	.out_pf
	cmp	al,'%'
	jz	.gest_spec
;	cmp	al,'\'		;is it really needed?
;	jz	.gest_spec2	;or compiler expands these characters?
.store:
	stosb
	jmps	.boucle
.gest_spec:
	mov	ebx,[edx]
	lodsb

	_mov	ecx,10
	cmp	al,'d'
	jz	.gestf
	_mov	ecx,16
	cmp	al,'x'
	jz	.gestf
	_mov	ecx,8
	cmp	al,'o'
	jz	.gestf
	_mov	ecx,2
	cmp	al,'b'
	jz	.gestf
	cmp	al,'c'
	jz	.store
	cmp	al,'s'
	jnz	.boucle
	test	ebx,ebx		;NULL check
	jz	.allok
.copyit:			;copy string in args to output buffer
	mov	al,[ebx]
	test	al,al		;string is null terminated
	jz	.allok
	stosb
	inc	ebx
	jmps	.copyit

.gestf:
	pusha
	mov	eax,ebx
	call	itoa.printB
	mov	byte [edi],0	;zero terminate the string 
	popa

.stl:	cmp	byte [edi],1
	inc	edi
	jnc	.stl
	dec	edi

.allok:	add	edx,byte 4
	jmps	.boucle

;.gest_spec2:
;	lodsb
;	mov	ah,__n
;	cmp	al,'n'
;	jz	.s2
;	mov	ah,__t
;	cmp	al,'t'
;	jnz	.boucle
;.s2:
;	mov	al,ah
;	stosb
;	jmps	.boucle

.out_pf:
	xor	al,al
	stosb
	pop	edx
	sub	edi,edx
	dec	edi		;do not write trailing 0
	mov	[__eax],edi
	popa
	ret

;int printf(const char *format, ...)
;
;uses rather dangerous approach

printf:
%define _sf	0x1000
	sub	esp,_sf			;create buffer (dangerous!!)
    	pusha
	mov	ebp,[esp + 4 * 8 + _sf]	;save return address
	lea	esi,[esp + 4 * 8]	;here will our buffer begin
	add	esp,4 * 8 + _sf		;rewind stack back
	mov	[esp],esi		;replace return address with buffer
	call	sprintf
	mov	[esp],ebp		;restore return address
	sub	esp,4 * 8 + _sf		;substitute stack

	sys_write STDOUT,esi,eax

	mov	[__eax + _sf],eax
	popa
	add	esp,_sf
	ret
%undef	_sf

;int inet_aton(const char *cp, struct in_addr *inp)
;
;convert IP address ascii string to 32 bit network oriented
;
;<ESI	*cp
;<EDI	*inp
;
;>EAX

inet_aton:
	push	esi
	push	edi
	push	edx

	mov	esi,eax
	mov	edi,edx

	__ADJUST_CDECL3	4*3,esi,edi

	cld
	_mov	ecx,4
; convert xx.xx.xx.xx  to  network notation
.conv:	xor	edx,edx
.next:	lodsb
	sub	al,'0'
	jb	.loop1
	add	edx,edx
	lea	edx,[edx+edx*4]
	add	dl,al
	jmps	.next
.loop1:	mov	al,dl
	stosb
	loop	.next

	xor	eax,eax		;assume address was valid

	pop	edx
	pop	edi
	pop	esi
	ret

;long strtol(const char *nptr, char **endptr, int base)
;
;convert string in npt to a long integer value
;according to given base (between 2 and 36)
;if enptr if not 0, it is the end of the string
;else the string is null-terminated
;
;<EDI	const char *nptr
;<ESI	char **endptr, or 0 if string is null-terminated
;<ECX	int base (2, 8, 10, 16, or another one max=36)
;
;>EAX

strtol:
	push	edi
        push	esi
        push	ebx
        push	ecx

	mov	edi,eax
	mov	esi,edx
	__ADJUST_CDECL3 4*4,edi,esi,ecx

	test	ecx,ecx
	jnz	.base_ok
	_mov	ecx,10		;default base to use
.base_ok:
        xor	eax,eax
	xor	ebx,ebx
.parse1:
	cmp	byte [edi],32
	jnz	.parse2
        inc	edi
        jmps	.parse1
.parse2:
	cmp	word[edi],'0x'
        jnz	.next
        _mov	ecx,16
	add	edi,byte 2
.next:	mov	bl,[edi]
	sub	bl,'0'
        jb	.done
        cmp	bl,9
        jbe	.ok
        sub	bl,7
        cmp	bl,35
        jbe	.ok
        sub	bl,32
.ok:	imul	ecx
	add	eax,ebx
        inc	edi
        cmp	edi,esi
	jnz	.next
.done:
	pop	ecx
        pop	ebx
        pop	esi
        pop	edi
	ret

;
;unused functions
;

%macro _UNUSED_ 0

;
;convert 32 bit number to hex string
;
;>EAX
;<EDI

LongToStr:
	pushad
	sub	esp,4
	mov	ebp,esp
	mov	[edi],word "0x"
	inc	edi
	inc	edi
	mov	esi,edi
	push	esi
	mov     [ebp],eax
	_mov ecx,16	;10 - decimal
	_mov esi,0
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
	popad
	ret

;
;convert string to 32 bit number
;
;<EDI
;>EAX

StrToLong:
	push	ebx
	push	ecx
	push	edi
	_mov	eax,0
	_mov	ebx,10
	_mov	ecx,0
.next:
	mov	cl,[edi]
	sub	cl,'0'
	jb	.done
	cmp	cl,9
	ja	.done
	mul	bx
	add	eax,ecx
;	adc	edx,0	;for 64 bit
	inc	edi
	jmp short .next

.done:
	pop	edi
	pop	ecx
	pop	ebx
	ret

strlen2:
%if  __OPTIMIZE__=__O_SIZE__
	push	edi
	mov	edi,[esp + 8]
	mov	eax,edi
	dec	edi
.l1:
	inc	edi
	cmp	[edi],byte 0
	jnz	.l1
	xchg	eax,edi
	sub	eax,edi
	pop	edi
%else
; (NK)
; note: below is classic variant of strlen
; if not needed to save ecx register then size of classic code
; will be same as above 
; remark: fastcall version of strlen will on 2 bytes less than cdecl
	push	esi
	push	ecx
	mov	esi,[esp + 12]
	xor	eax,eax
        or	ecx,-1
	repne	scasb
	not	ecx
	mov	eax,ecx
	dec	eax
	pop	ecx
	pop	esi
%endif
	_leave


%endmacro ;_UNUSED_

UDATASEG

;
;store them within caller's image
;

common	errno	4	;guess what

common	__cc	4	;calling convention (how many registers for fastcall)
			;0 = cdecl
common	__envp	4	;envp, for getenv()

END
