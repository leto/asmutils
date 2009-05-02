;Copyright (C) 2001 by Joshua Hudson
;
;$Id: which.asm,v 1.5 2002/02/02 08:49:25 konst Exp $
;
;hacker's which
;
;usage: which command [command ...]
;
;fails when uid != euid

%include "system.inc"

CODESEG

START:

;*** Find PATH= in environment (most code from env.asm)
	pop	ebp
	mov	edx, ebp
	xor	eax, eax		; [found] = 1, error
	inc	eax
	mov	[found], eax
.env:
	inc	ebp
	mov	esi, [esp + ebp * 4]
	or	esi, esi
	jz	.lastpath		; If no PATH, everything must have /
	cmp	[esi], dword 'PATH'	; Is this the PATH= environ
	jne	.env
	cmp	[esi+4], byte '='
	jne	.env

;**** Found PATH=, now parse
	mov	ebp, edx
	add	esi, 5
	mov	ebx, pathptr
	mov	cl, 64
.nextpath:
	mov	al, [esi]
	or	al, al
	jz	.lastpath
	cmp	al, ':'			; Skip blank entries
	jne	.notempty
	inc	esi
	jmp	.nextpath
.notempty:
	mov	[ebx], esi		; Index entries
	add	ebx, byte 4
.nextposn:
	inc	esi			; Block off entries
	mov	al, [esi]
	or	al, al
	jz	.lastpath
	cmp	al, ':'
	jne	.nextposn
	mov	[esi], byte 0
	inc	esi
	dec	cl
	jnz	.nextpath
.lastpath:
	pop	eax			; Remove program name
					; from stack
;*** Get UID, GID
	sys_getuid
	mov	[uid], eax
	sys_getgid
	mov	[gid], eax

;*** Get GROUPS
	sys_getgroups	64, groups
	mov	[ngroups], eax

; For each command argument
.nextarg:
	dec	ebp
	jz	.done
	pop	edi			; edi = command to test
	mov	[current], edi
	push	ebp
	call	.which
	pop	ebp
	jmp	.nextarg

.done	mov	ebx, [found]
	sys_exit

;******* .which: determine if the argument in [current] can be run from PATH=
; May destroy all registers
.which:
	mov	ebp, pathptr
	mov	esi, [current]
.findslash:				; If contains any slashes,
	lodsb				; do not use PATH
	or	al, al
	jz	.chwhich
	cmp	al, '/'
	jne	.findslash
	mov	ebp, zero
	mov	edi, pathbuf
	jmps	.noneedslash
.chwhich:				; For each path,
	mov	esi, [ebp]
	or	esi, esi
	jz	near .whdone
	mov	al, [esi]
	or	al, al
	jz	near .whdone
	mov	edi, pathbuf
	call	.strccpy		; Copy into buffer
	dec	edi
	mov	al, '/'			; Append / if necessary
	cmp	[edi], al
	je	.noneedslash
	stosb
.noneedslash:
	mov	esi, [current]
	call	.strccpy

;*** NOW STAT the file
	sys_stat	pathbuf, sts	; This stat follows symlinks
	neg	eax
	jc	near .nextwhich		; If we can't stat it, we can't
					; execute it
	mov	ecx, [sts.st_mode - 2]
	shr	ecx, 28
	and	ecx, byte ~4
	jz	near .nextwhich		; Can't execute a directory
;*** Check permissions
	mov	eax, [sts.st_mode]
	and	eax, byte 73		; mode 0111
	jz	.notfound
	mov	ebx, [uid]		; If an execute bit is set,
	or	ebx, ebx
	jnz	.notroot		; root can execute it
.found:
	xor	eax, eax
	mov	[found], eax
	mov	al, __n
	stosb
	mov	edx, edi
	sub	edx, pathbuf
	sys_write	STDOUT, pathbuf
.whdone:
	ret
	
.notroot:
	cmp	bx, [sts.st_uid]	; Can it be executed
	jne	.group			; as the user?
	and	eax, byte 64		; mode 0100
	jnz	.found
	jmp	.notfound
.group:
	mov	cx, [sts.st_gid]	; As the group?
	cmp	ecx, [gid]
	je	.thegroup
	mov	edx, [ngroups]
	mov	ebx, groups
.nextgroup:
	cmp	cx, word [ebx]
	je	.thegroup
	inc	ebx
	inc	ebx
	dec	edx
	jnz	.nextgroup
	and	eax, byte 1		; as the world?
	jnz	.found
	jmp	.notfound
.thegroup:
	and	eax, byte 010
	jnz	.found
.notfound:
.nextwhich:
	add	ebp, 4
	jmp	.chwhich
	


.strccpy:	; *** copy string esi to edi
	lodsb	;esi
	stosb	;edi
	or	al, al
	jnz	.strccpy
	ret

;.DEBUG:		; Display a debugging message
;	pusha
;	mov	ecx, DEBUG_MESSAGE
;	mov	edx, [DEBUG_MESSAGE_LEN]
;	sys_write	STDERR
;	popa
;	ret
;
;DEBUG_MESSAGE	db	"DEBUG", __n
;DEBUG_MESSAGE_LEN	dd	6

UDATASEG

uid	resd 1		; The user's uid
gid	resd 1		; The user's gid
ngroups	resd 1		; The number of groups the user is in
groups	resd 64		; Those groups
pathptr	resd 64		; We process 64 paths from ENV
zero	resd 2		; Always zero
pathbuf	resb 1024	; 1k for the /path/to/filename buffer
found	resd 1		; Set to 0 when first entry is found
current	resd 1		; The current command pointer

sts:
%ifdef __BSD__
B_STRUC Stat,.st_ino,.st_mode,.st_nlink,.st_uid,.st_gid,.st_rdev,.st_mtime,.st_size,.st_blocks
%else
B_STRUC Stat,.st_ino,.st_mode,.st_nlink,.st_uid,.st_gid,.st_rdev,.st_size,.st_blocks,.st_mtime
%endif

END
