;-====================================================================;
;- Copyright (C) 2000 H-Peter Recktenwald, Berlin <phpr@snafu.de>
;-
;- $Id: report.asm,v 1.2 2006/02/09 07:49:11 konst Exp $
;-
;-  file  	: report.asm
;-  created	: 06-jun-2000
;-  modified	:
;-  version	: 0.01		initial, 6.6.00,
;-		: current	re "version.inc"
;-  assembler	: nasm 0.98
;-  description	: display signals and error message strings or names
;-  author	: H-Peter Recktenwald, Berlin <phpr@snafu.de>
;-  comment	: cpl: <Makefile> of asmutils 0.09 will work,
;-  source	: 
;-  requires	: asmutils 0.09+, http://linuxassembly.org
;-		; i386-linux 2.2+, i586(+) processor
;-====================================================================;
;-
;-
;- report [ -s -n ] [-]number
;-	takes abs(number) and options by arguments
;-	and sends requested data to stdout:
;-
;-	no option	error message
;-	-s, --signal	modifier, result wrt the respective signals
;-	-h, --help	the above useage hints
;-
;- example:
;-		brumpf;n=${?};report ${n}
;-	reports
;-		ernum not in message table
;-

;-
;- %include "system.inc"	..always required
%include "system.inc"

%define VER 00
%define EXT 02

;====================================================================;

;- %include "errno.inc"		errors and signals names
%ifndef DATE
%ifdef  STAMP_DATE
%define DATE STAMP_DATE
%else
%define DATE '08-jun-00'
%endif
%endif
%define __PROG 'report'
%include "errno.inc"

%ifndef jr
%define jr jmp short
%endif

buf_size:	equ 4096
numbufl:	equ 16


;-
		CODESEG
Z:
; strings & displacemt tables
;rt:		error messages
    ertstg
;rn:
    ertdsp
;st:		signal messages
    sigstg
;sn:
    sigdsp

opts:;		flagbit val
    db "-n--nu";  3	8
    db "-s--si";  2	4
    dw "-h--he";  1	2
    dw "-v--ve";  0	1
    dw 0,0,0
vert:
    db 'report (asmutils 0.10) hp01',__n,0	; sub(?)version
hlpt:
    db 'report [option(s)] number',__n
;n.i.;    db __t,'--name (-n)'
    db __t,'--signal (-s)'
    db __t,'no option (errors)',__n
    db __t,'--version, -v'
    db __t,'--help, -h'
cr:
    db __n,0
    
START:
    call .b
.b:
    pop ebp
    add ebp,Z-.b		; base reference, requires no linker program
    pop ebx			; get argc
    dec ebx
    jz help			; no arg, print helptext
    lea esi,[esp+4]		; ptr to args past name
    push byte 0			; options flags
.l:
    lodsd			; pass ptr to arg in eax
    test eax,eax
    jz ready			;?;
    call qarg
    or [esp],dh			; save option flags
    dec ebx
    jns .l			;?; no more args
help:				; if no number print help
    xor eax,eax			; messagetext version
    call rmsg
    lea ecx,[ebp+hlpt-Z]	; helptext
    jr pver.p
pver:
    lea ecx,[ebp+vert-Z]	; version
.p:
    call print
do_exit:
    xor ebx,ebx
xxit:
    sys_exit		
;-
ready:
    mov esi,[esi-8]		; last argument
    push esi			; save for ovf case
    call sgnum			; fetch signal/error number to ecx
    pop esi
    mov eax,ecx
    lea ebx,[ebp+do_exit-Z]
    xchg ebx,[esp]		; options flags, push exit return
    shr ebx,1
    jc pver			;?; version
    shr ebx,1
    jc help			;?; helptext
    shr ebx,1
    jnc rmsg			;?; errors
;-
;- {r,s}msg
;-	display signal message if -ve x in range
;- i:	eax	message code
;-	ebx	output flags
;- 	ebp	code base reference
;- c:	eax,ecx
smsg:
    lea ecx,[ebp+sr-Z]	; disp to base of disp table
    mov edx,[ebp+sm-Z]	; top signals index
    inc edx		;<=; watch it! this is due to some nasm oddity and may change!
    jr rmsg.n
rmsg:
    lea ecx,[ebp+rn-Z]	; disp to base of disp table
    mov edx,[ebp+rm-Z]	; top index of messages table
.n:
;n.i.:    shr ebx,1		; test whether name requested
    test eax,eax
    jns .m
    neg eax
.m:
    cmp eax,edx		; upper bound of errno-s
    jnae .a 		; within range
    push ecx
    mov ecx,esi		; else
    call print		;  repeat the argument
    pop ecx
    mov eax,edx
.a:
    movsx eax,word[byte ecx+eax*2-2]
    add ecx,eax
    movsx edx,word[ecx]
    add ecx,byte 3	; advance past count.w & leading <nl>
    dec edx		; adjust & check length, leave trailing <nl>
    pushad
    jr print.w		; send text
;-
;- newline
;- i:	ebp	code base reference
;- c:	ecx
newline:
    lea ecx,[ebp+cr-Z]	; append line feed
;-
;- print
;- i:	ecx	ptr to asciz string to print
;- c:	-/-
print:
    pushad
    lea edx,[ecx-1]
.l:
    inc edx
    test byte[edx],-1
    jnz .l
    sub edx,ecx
.w:
    jng .r		;?; zero or -ve length (which shouldn't happen)
    sys_write STDOUT
.r:
    popad		
    ret
;-
;- qarg
;-	fetch options flags
;- i:	eax	ptr to argument
;- 	ebp	code base reference
;- o:	edx	bitflags from options
;-	eflags	Z:no more options or args
;- c:	eax,ebx,ecx,edx
qarg:
    push esi
    push ebx
    mov ebx,[eax]		; fetch leading chars
    _mov edx,01000b		; bitflags for..
    lea esi,[ebp+opts-Z]	;  ..options
.l:
    lodsw			; short option text
    mov ecx,eax
    lodsd			; long
    test eax,eax
    jz .r			;?; no more options
    cmp bx,cx			; short option
    jz .f			;?; found
    cmp ebx,eax			; long option
    jnz	.t			;?; more
.f:
    or dh,dl			; set bitflag
.t:
    shr dl,1			; top bitflag is loop counter
    jnz .l			;?; more flags to scan
.r:
    pop ebx
    pop esi
    ret
;-
;- signum
;-	get message index by dec, sedec or oct number
;-	exit into <help> if no number present
;- i:	eax	@arg, 1st dword
;-	esi	<[ea]> ptr to arg. text
;-	ebp	code base reference
;- o:	ecx	index := abs(num)
;- c:	eax, ebx, ecx, edx, esi, eflags
sgnum:
    mov eax,[esi]
    xor ecx,ecx			; clr accu for numeric result
    cmp al,'-'
    jnz .q
    inc esi			; advance to number chars
    shr eax,8			; abs(num), discard sign
.q:
    cmp al,'0'
    jz st2h			; octal/sedecimal
    js .h			; else exit with helptext
    cmp al,'9'
    ja .h			; not decimal
    mov eax,ecx
;decimal number
.l:
    lodsb
    sub al,'0'
    jc .n
    cmp al,10
    jc .d
.n:
    ret
.h:
    jmp help
.d:
    lea ecx,[ecx+ecx*4]		; ecx := ecx 5 *
    lea ecx,[eax+ecx*2]		; ecx := ecx 2 * al + := accu 10 * digit +
    jr .l			; more
;sedec '0x'number, or '0'octal (or any 2^x radix)
st2h:
    mov ebx,ecx
    mov cx,8<<8|3		; conversion radix and bitmask
    cmp ah,'x'
    jnz .l			;?; octal
    add esi,byte 2		; drop '0x'
    mov cx,16<<8|4		; sedecimal
.l:
    lodsb			; arg
    sub al,'0'
    jnc .c
.n:
    mov ecx,ebx
    ret
.c:
    cmp al,10
    jc .h
    sub al,7
    jc .n
    cmp al,ch
    jc .a
    sub al,('a'-'0'-17)
.h:
    cmp al,ch
    jnc .n
.a:
    shl ebx,cl
    or bl,al
    jr .l			; more

		END
;  -----------------------------------  ;
