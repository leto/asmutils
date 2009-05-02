;Copyright (C) 2000 Jonathan Leto <jonathan@leto.net>
;
;$Id: chown.asm,v 1.1 2001/01/21 15:18:46 konst Exp $
;
;hackers' chown
;
;syntax: chown uid[.gid] file [ file ] ....
;
;returns 0 on success, 1 on error
;ascii_to_num from strings.asm by Dmitry Bakhvalov <dl@gazeta.ru>
;strlen from rm.asm by Dmitry Bakhvalov <dl@gazeta.ru>
;
; No support for username/group yet
; No support for recursive or symlink(lchown) either
;
; used 255 for MAXPATH, couldn't find constant
;
; Version 0.1 - Tue Dec 19 19:30:30 EST 2000 
;
; All comments/feedback welcome.

%include "system.inc"

;ebp = return code

CODESEG

setnogroup:
	_mov	[gid],dword -1		; don't change group
	ret

START:   
	_mov	[uid],dword -1		; won't change

	_mov	ebp,0			; default file descriptor
	pop	ebx			; argc
	dec	ebx			 
	pop	ebx			; argv[0], program name
	jz 	near .exit		; flag set by dec

	pop	esi
	call	strlen
;--- make sure doesn't begin with letter
	lodsb	

	cmp	al,byte 0x2f
	jle	near .exit

	cmp	al,byte 0x3a
	jge	near .exit
	
	dec	esi
;-----------------------------------------	
;-- if last char in string is period, die
;-- without this, "chown uid. file" would be interpreted
;-- as  "chown uid.0 file", which is bad
.sane2:
	dec	edx
	inc	ebp
	cmp	[esi+edx],byte '.'
	je	near .exit
	inc	edx
	dec	ebp
;---------------------------------------
	xor	ecx,ecx			; offset in arg of .
	push	esi			; save orig argument

.findper:				; find period in string
	lodsb				; get byte
	inc	ecx			
	cmp	ecx,edx
	jg	.alldone		; no more string

	cmp	al,'.'
	jne	.findper
	_mov	[foundper],dword 1	; found it

.alldone:
	_mov	[gid],esi		; what's left is gid
	dec	ecx			; offset starts at 0
	pop	esi			; get orig argument
	_mov	[esi+ecx], byte 0x0	; put null where period was
	_mov	[uid],esi		; save uid

        _mov    esi,[gid]               ; change to number
        call    .ascii_to_num
        _mov    [gid],eax

	_mov	esi,[uid]		; change to number
	call	.ascii_to_num
	_mov	[uid],eax

        cmp    [foundper],dword 1
        je      .numbers
        call 	setnogroup

.numbers:	
	pop	esi			; get file
	or	esi,esi
	jz	.exit			; no file given

	_mov	[file],esi

	sys_chown [file],[uid],[gid]
	jmp .numbers			; get next file

.exit:
	sys_exit ebp			; exit with return value

;---------------------------------------
; esi = string
; eax = number 
.ascii_to_num:
        xor     eax,eax                 ; zero out regs
        xor     ebx,ebx
.next_digit:
        lodsb                           ; load byte from esi
        test    al,al
        jz      .done
        sub     al,'0'                  ; '0' is first number in ascii
        imul    ebx,10
        add     ebx,eax
        jmp     .next_digit
.done:
        xchg    ebx,eax                 ; ebx=eax,eax=ebx
        ret
;------------------
; esi = string
; edx = strlen
strlen:
                push    eax
                push    esi

                xor     eax,eax
                mov     edx,eax
                dec     edx
.do_strlen:
                inc     edx
                lodsb
                test    al,al
                jnz     .do_strlen

                pop     esi
                pop     eax
                ret

UDATASEG

uid:	resd	1
gid: 	resd	1
file:	resd	255
foundper:	resd 1

END
