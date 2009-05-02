;Copyright (C) 2000 H-Peter Recktenwald <phpr@snafu.de>
;
;$Id: extname.asm,v 1.3 2000/12/10 08:20:36 konst Exp $
;
;hackers' extname (return extension or postfix of a given filename)
;
;syntax: extname { filename | - } [delimiter]
;	 "-" instead of filename for input from stdin
;	 delimiter is "." by default or,
;	 optionally any 1st (and 2nd) char of any length argument stg.
;
;if delimiter found:
;	ret. part of basename after and inclusive delimiter or,
;	ret extension not including dlm if arg is double dlm char.
;	for instance,
;		echo $(echo "yesterday was sunday"|extname - \ )
;	writes
;		sunday
;if delimiter not found:
;	empty string if no dlm found or only a leading single dlm.
;	for instance,
;		echo $(echo ".yesterday was sunday"|extname -)
;	writes the empty string
;
;exitcode:
;	1 if no argument given, 0 otherwise
;
; ------------------------------------------------------------------- ;
;
;0.01: 25-mar-2000	initial release
;0.02: 02-apr-2000	scan basename part only
;0.03: 14-apr-2000	modified to
;	accept filename from stdin/pipe and to complement `basename`:
;	default and arg single (1st) char as dlm returns the names
;		extension with leading delimiter inclusive,
;	if arg leading 2 chars are same, returnstring is extension
;		only, not including the delimiter char.
;	compile option WITH_DLM can be used to force default and
;		single delimiter chars mode, only.
;
; ------------------------------------------------------------------- ;

%include "system.inc"

;override compile options from Makefile:
;
;define to saving a few bytes if you'd know for certain that
; 	no pathnames will be passed to <extname>, e.g always 
;	used after "basename", or, if the expected delimiter 
;	will be at some position, unknown but always present.
;%define BASENAME
;%undef  BASENAME

;define for alternate behaviour,
;	to force returning xtn with leading delmiter, only.
;%define WITH_DLM
;%undef  WITH_DLM

ddir: equ '/'		; filename delimiter (directory marker)
dext: equ '.'		; default extension delimiter


    CODESEG

START:
    pop	ebx
    dec ebx
    dec ebx
    js .j
    pop	edi		; drop progname
; try filename from stdin
    mov eax,[esp]
    cmp byte[eax],'-'
    jnz .g		; name not from stdin
    mov ecx,fpath
    mov [esp],ecx	; overwrite option ptr
    push ebx
    mov edx,PATH_MAX
    sys_read STDIN
    test eax,eax
.j:
    js .r		;?; neither arg nor input
    pop ebx
.g:
    mov ah,dext		; default dlm
    pop edi		; 1st arg
    dec ebx
    js .a		; no.. 
    pop eax		;  ..delimiter
    mov eax,dword[eax]
    cmp ah,al
    jz .s		; doubly
    mov ah,al
    stc
.s:
    cmc			; C is flag for double dlm
.a:
    rcl eax,1		; preserve delimiter
    ror eax,1		; store flag to signbit
    cld			; scan forward
; find string
    xor ecx,ecx
    mov al,cl
    dec ecx
    repnz scasb
    std			; scan back
    not ecx
    mov edx,ecx
%ifndef BASENAME
; discriminate basename
    mov al,ddir		; dirname delimiter
    dec edi
    dec edx
    repnz scasb
    jz .b
    dec edi		; full length
.b:
    sub edx,ecx		; maxlen
    mov ecx,edx
    lea edi,[2+edx+edi]	; basename
%endif
    mov al,ah		; delimiter
    dec edi		; pts to before dlm, if found
    dec edx
    repnz scasb
    jz .f
.n:
    mov ecx,edx		; ret empty
    inc ecx
.f:
    test ecx,ecx
    jz .n		;?; ret empty if dlm is leading char of filename
%ifdef WITH_DLM		;compile option: extn with leading dlm mode, only
    dec ecx
    sub edx,ecx
    lea ecx,[edi+1]	; compensate for dlm & <nul>
%else
    sar eax,31		; -1 if extn w.o. dlm
    dec ecx
    sub ecx,eax
    sub edx,ecx
    lea ecx,[edi+1]	; compensate for dlm & <nul>
    sub ecx,eax
%endif
    mov [ecx+edx],byte __n
    inc edx
    sys_write STDOUT
    xor ebx,ebx
.r:
;    neg ebx		;(can be dispensed with -> exit 255 w.o. args, shorter code)
    sys_exit

    UDATASEG

fpath:	resd (PATH_MAX+7)/4
    
END
