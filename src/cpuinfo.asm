;-====================================================================;
;- Copyright (C) 2000 H-Peter Recktenwald, Berlin <phpr@snafu.de>
;-
;- $Id: cpuinfo.asm,v 1.4 2006/02/09 08:04:32 konst Exp $
;-
;-  file  	: cpuinfo.asm
;-  created	: 18-jan-2000
;-  modified	: 12-mar-2000
;-  version	: 0.22 05-08-00
;-  assembler	: nasm 0.98
;-  description	: short form i486+ cpuid output, sedecimal register
;-		: values, and text output if invoked with (any)
;-		: argument. self adjusting to cpuid stepping, and
;-		: lines numbering scheme added for easier evaluation.
;-		: output:
;-		: leading "0x" for standard level queries,
;-		:	  "1x" intel cache description,
;-		:	  "8x" amd extended levels (eax=0x80000000+)
;-		:	where "x" is the corresponding level number,
;-		: followed by 8 digits sedecimal eax..edx values/line
;-		: with option -t or --time displays cpu timing in
;-		:	clocks/second (re below, 'e2sec' & 'ms').
;-		: with any other option displays cpuid data plus,
;-		:	additionally ascii equivalent of reg contents.
;-		: due to very simple options checking any strings
;-		: beginning "-t" or "--ti" will do for the timer
;-		: and, "-h" or "--he" for a short help message.
;-  author	: H-Peter Recktenwald, Berlin <phpr@snafu.de>
;-		: http://home.snafu.de/phpr/
;-  comment	: cpl: <Makefile> of asmutils 0.08 will work,
;-		: 'long' text output treated as ascii, no conversion
;-		: nor checks done, thus output might get corrupted
;-		: if any chars found which sys_write doesn't catch.
;-		; conditional compiling:
;-		: -h & -v options not compiled if OPTIMIZEd for SIZE
;-		: which can be overridden by %define-d switch __LONG.
;-		: "-t" mode w. disabled int's if __lockint %define-d.
;-		: other modifiers re source text.
;-  source	: AMD no. 218928F/0 Aug 1999, pg 3 f.
;-  requires	: asmutils 0.09+, http://linuxassembly.org
;-		; i486-linux 2.2+
;-====================================================================;
;-

; version history
;	0.22 05-08-00 "cpuspeed" is "-t" mode, opt. iopl setting
;	0.21 15-06-00 .bss section dispensed with, shorter
;	0.20 20-04-00 -h|--help added; (timing - 10ns)
;	0.19 08-04-00 combined with <cpuspeed> query
;	0.18 06-04-00 minor changes, shorter
;	0.17 04-04-00 .bss-'trick' eliminated
;	0.16 31-03-00 <start>,<cpurg>,<p_num> shorter
;	0.14 25-03-00 text output, w.o. macros, shorter
;	0.13 16-03-00 text output level 1; 'long' only
;	0.12 15-03-00 again intel 2nd level correction
;	0.11 12-03-00 more intel 2nd level correction
;	0.10 10-03-00 arbitrary intel flag correction
;	0.09 08-03-00 1st release

;-
;- result can be processed,
;- for instance, to extracting the processor signature:
;-	signature=0x`cpuinfo|grep "^01 "|cut -d\  -f2`
;- further,
;-	vtype	=$(((${signature}&0x03000)>>12))
;-	family  =$(((${signature}&0x00f00)>>8))
;-	model   =$(((${signature}&0x000f0)>>4))
;-	stepping=$(((${signature}&0x0000f)))
;-

%include "system.inc"

CPU 586

;-
;- "__LONG"
;- uncomment to force compiling w. help & version
;- options regardless of __OPTIMIZE__ mode.
;%define __LONG

;-
;- "__lockint" to lock interrupts in "-t" mode,
;- uncomment for (probably) more precise timing
;%define __lockint
;-

%if __OPTIMIZE__=__O_SIZE__
%define __SHORT
%else
%define __LONG
%endif

%ifdef __LONG
%undef __SHORT
%endif

%ifdef A2MSHELL
%define	SYSDATE ADATE
%else
    %ifdef DATE
%define	SYSDATE DATE
    %else
%define SYSDATE 000411
    %endif
%endif

TAB equ __t
LF  equ __n

;====================================================================;

%ifndef jr		; lazy typing.. (z80)
%define jr jmp short
%endif

; --------------------

	CODESEG

;-
;- cpu timing measurement & display mode configuration
;-	default: 1 sec interval, display in units of 1/sec
%define ms 1000000	; clocks per micro second
%define ms    1000   	; clocks per ms
%define ms       0   	; clocks per s
%define e2sec    3	; timing interval (8 sec)
%define e2sec    1	; timing interval (exp 2)
;-
;- temp. storage
%define rbuf	ebp		;21;
%define rbuf.e	rbuf+11
%define lflg	rbuf+11
%define txref	byte esi-req+
;-

%ifdef __SHORT
%else
vd:
    db 'hp:',SYSDATE,", cputest "
.v:
    db '[ -t | . ]',LF
    db TAB,'-t | --time cpu clock rate',LF
    db TAB,'(none) cpuid eax..edx/line',LF
    db TAB,'(any)  cpuid + ascii',LF
.e:
    db 0
vl:
    db vd.v-vd
%endif

req:				; struc & dft for nanosleep
    dd (1<<e2sec)-1		; sec
    dd 1000000000-5000000	; ns, allow(?) for system overhead 10ms

no_cpuid:
    db "no 'cpuid'"
crlf:
    db LF,0

; --

; determine whether '-t' mode forced by program name	;22;
; in: eax argc, edi ptr to prg.name
; out: eax:=0 if name is 'cpuspeed'
tname:
    push eax
    xor eax,eax		; <eol>
    lea ecx,[eax-1]	; maxcount
    repnz scasb
    cmp dword[edi-5],'peed'; program name
    jnz .r
    cmp dword[edi-9],'cpus'
    jnz .r
    mov [esp],eax	; force args count to "just name"
.r:
    pop eax
    ret

%ifdef __SHORT
%else
vers:
    lea edx,[syx]
    push edx
    movzx edx,byte[txref vl]	;21;
    pushad
    jmp syswrite
%endif

START:
    mov esi,req			;21;
    pop eax
    lea ebp,[esp+4*eax+4];ref to temp storage space	;21;
    mov edi,[esp]	; ptr to prg.name		;22;
    call tname		; check
    dec eax
    mov [lflg],al	; short/long output flag	;16;
    jle .no	;jz .no
		;js .no						;22;
    pop eax
    pop eax
    mov eax,[eax]
    _cmp ax,'-t'
    jz .ti
%ifdef __SHORT
%else
    lea ecx,[txref vd]		;21;
    _cmp ax,'-h'
    jz cpuid_ni.s
    _cmp ax,'-v'
    jz vers
    _cmp eax,'--he'
    jz cpuid_ni.s
%endif
    _cmp eax,'--ti'
    jnz .no
.ti:
    neg byte[lflg]	; -ve for cpuspeed
.no:
    pushfd
    pop eax
    mov ebx,eax
    _xor eax,1<<21
    push eax
    popfd
    pushfd
    pop eax
    cmp eax,ebx
    jz cpuid_ni		; <cpuid> not present
; - standard levels -
    xor eax,eax
    cmp al,[lflg]
    jg time
    cpuid
    push eax		; save no. of standard levels
    call idpt		; standard features
; - AMD xt'd -
    _mov eax,0x80000000
    cpuid
    test eax,eax
    jns .i		; try intel 2nd level		;11;
    call idpt		; amd extended features
.i:
    pop eax
    cmp eax,byte 2
    jc syx		; no additional standard config data
; - intel level 2 cache cfg -
    mov al,2
    cpuid
    dec al
    jle syx		; none/1st level already done	;12; <- re AP-485, 3.4, pg 12
    movzx eax,al	; counter is just l.s.b		;11;
    _or eax,0x10000000	; 'intel' output flag
    call idpt		; cache description
syx:
    sys_exit 0

cpuid_ni:
    lea ecx,[txref no_cpuid]	;21;
.s:
    call p_string
    jr syx

time:				;19;
%ifdef __lockint
    sys_iopl 3	;\ ;22;
    cli		;/ (re below)
%endif
    rdtsc
    push eax
    lea ecx,[rbuf]	; syscall (dummy) answer space
    sys_nanosleep req	; sleep ({e2sec}^2)
    rdtsc
%ifdef __lockint
    push eax	;\ ;22;
    sti		; \more precise timing
    sys_iopl 0	; /with locked int's.
    pop eax	;/
%endif
    pop edx
    sub eax,edx
%if e2sec>0
    shr eax,e2sec	; take 1s average of ({e2sec}^2)s
%endif
%ifdef ms
%if ms > 0
    _mov ebx,ms		; scale to factor {ms}
    _mov edx,0
    div ebx
;shr edx,((1+2*(ln(ms)/ln(2)))/2) ;"nasm"...
%endif
%endif
; ----------------------.
; <p_dec>
;	print significant digits (or "0")
;	of decimal number {eax} to stdout
; i:	eax
; o:	ecx,edx
; c:	eax,ebx,ecx,edx
;p_dec:
    xor ebx,ebx
    push ebx		; length counter
    mov bl,10		; radix
    lea ecx,[rbuf.e-2]
    mov word[ecx],bx	; trailing <nl>,<nul>
.l:
    dec ecx		; numbuf-
    inc dword[esp]
    xor edx,edx		; hi dword for div
    div ebx
    or dl,'0'
    mov [ecx],dl
    test eax,eax
    jnz .l
; ----------------------'
    call p_string
    jr syx

; - display all of one level mode -
idpt:
    push eax
    xor ax,ax			;18;
    mov edi,eax
.l:
    mov eax,edi
    call cpurg		; output a line of register values
    inc edi			;18;
    dec byte[esp]		;18;
    jns .l		; loop through all levels
    pop eax
    ret

; - display one line of regs -
cpurg:
    mov ebx,eax			;16;14;
    rol eax,8		; merge top nib. into lo byte
    or al,ah
    call p_b		; print packed levelflag & number
    mov eax,ebx
    _and eax,0xefffffff	; mask intel-2nd-level flag	;10;
    cpuid
    call p_num
    xchg eax,ebx	; a:=b b:=a	;16;
    call p_num
    xchg eax,ecx	; a:=c b:=a c:=b
    call p_num
    xchg eax,edx	; a:=d b:=a c:=b d:=c
    call p_num
    test byte[lflg],-1
    jng p_nl		; no text
; - regs text representation -
    test di,di		; count
    jnz .o
    xchg eax,edx	; #1: xg for name stg.
.o:
    push ecx
    lea ecx,[rbuf+1]
    mov dword[ecx]," '"
    call p_string
    dec ecx		; leave terminating <nul>
    mov [ecx],ebx	; a
    call p_string
    pop dword[ecx]	; b
    call p_string
    mov [ecx],edx	; c
    call p_string
    mov [ecx],eax	; d
    call p_string
    mov word[ecx],"'"
    call p_string
p_nl:
    lea ecx,[txref crlf]	;21;14;17;
; <p_string>
; print asciz string {ecx} to stdout
; all regs preserved
p_string:
    pushad
    mov edx,ecx
    dec edx
.l:
    inc edx
    cmp byte[edx],TAB
    jnl .l
    sub edx,ecx		; stg length
syswrite:
    push byte STDOUT
    pop ebx
    sys_write
    popad
    ret

; print sedecimal number {edx} to stdout
; <p_b> l.s.byte
; <p_num> dword
; all regs preserved
p_num:			; 8 digits
    pushad
    push byte 8			;16;
.n:
    mov edx,eax			;16;
    pop ebx
    xor eax,eax
    lea ecx,[rbuf+8]		;21;
    mov byte[ecx],' '
    push ebx
.p:
    mov al,15
    and al,dl
    shr edx,4
    dec ecx

    cmp	al,10
    sbb	al,0x69
    das

    mov [ecx],al
    dec ebx			;18;
    jg .p
    pop edx
    inc edx		; trailing blank
    jr syswrite

p_b:			; 2 digits
    pushad
    push byte 2			;16;
    jr p_num.n

    END
;-								
;-====================================================================
;- cpuinfo.asm <eof>
