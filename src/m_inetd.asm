;Copyright (C) 2001 by Joshua Hudson
;
;$Id: m_inetd.asm,v 1.3 2002/02/02 08:49:25 konst Exp $
;
;m_inetd by Joshua Hudson 08/09/2001
;
; Runs as inetd for a single service.
; Usage: m_inetd uid port /path/to/in.server [i] > /var/run/server.pid
;		2>/var/log/server
;
; Sends PID to standerd out, server errors to standard error (if any)
; NONSTANDARD: passes ip of connecting machine to in.server if i is passed

%include "system.inc"

CODESEG

START:
	pop	eax		; Argc
	cmp	eax, byte 4	; Receives 3 or 4 arguments
	jl	fail
	cmp	eax, byte 5
	jg	fail
	jl	nopassip
	mov	[passip], al	; Client will receive ip-addr as first arg
				; Not testing contents as this is the
				; only meaning of this field
	mov	[execptrs+4], dword address	; Pass the ip-address
nopassip:
	pop	ebp		; Program name
;*** Process uid
	pop	ebp
	call	atoi
	mov	[uid], eax

;*** Socket code from httpd.asm
;*** Process port
	pop	ebp		; Port
	call	atoi
	push	eax		; Will need this later
; socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)
	sys_socket	PF_INET, SOCK_STREAM, IPPROTO_TCP
	xchg	eax, ebp	; Socket
	test	ebp, ebp
	js	fail
; socketopt(socket, SOL_SOCKET, SO_REUSEADDER, &setsockoptvals, 4)
	sys_setsockopt	ebp, SOL_SOCKET, SO_REUSEADDR, sockoptvals, 4
	or	eax, eax
	jz	do_bind

fail:	mov	bl, 1
do_exit:
	sys_exit

do_bind:
	pop	eax
	mov	[bindsockstruct], dword AF_INET
	mov	byte [bindsockstruct + 2], ah		; htons port
	mov	byte [bindsockstruct + 3], al
; bind (socket, &bindsocketstruct, 16)
	sys_bind	ebp, bindsockstruct, 16
	or	eax, eax
	jnz	fail

; listen (s, 0xFF)
	sys_listen	ebp, 0xFF
	or	eax, eax
	jnz	fail

;*** Load info onto heap
	pop	esi
	mov	edi, application
	mov	[execptrs], esi			; Install the self-name here
	call	strccpy
nopathreq:
	sys_setuid	[uid]			; Run as this user
	sys_fork				; Start the program
	or	eax, eax
	jz	acceptloop
	js	near fail

; Display child pid to SDTOUT
	mov	edi, address
	push	edi
	call	itoa
	pop	ecx
	mov	[edi], byte __n
	mov	edx, edi
	sub	edx, ecx
	inc	edx
	sys_write	STDOUT
	xor	bl, bl
	jmp	do_exit

;*** Listen for connections
acceptanother:
	sys_close	[consock]
	sys_wait4	0xffffffff, NULL, WNOHANG, NULL
	sys_wait4
acceptloop:
;accept(socket, struct sockaddr *sockaddress, int *consock)
	_mov	eax, 16
	mov	[consock], eax
	sys_accept	ebp, sockaddress, consock
	test	eax, eax
	js	acceptloop
	mov	[consock], eax

;Got a connection: fork process
	sys_fork
	or	eax, eax
	jnz	acceptanother	; Parent goes back to waiting

;**** Child: determine from where and exec
	sys_close	ebp	; Close the listening socket
	xor	eax, eax
	cmp	[passip], byte 0
	je	activate
	mov	edi, address
	_mov	ebp, 4
	mov	ebx, sockaddress+4
transip:
	mov	al, [ebx]
	inc	ebx
	push	ebx
	call	itoa
	pop	ebx
	mov	[edi], byte "."
	inc	edi
	dec	ebp
	jnz	transip
	dec	edi
	mov	[edi], byte 0
; Connect stdin & stdout	
activate:
	sys_dup2	[consock], STDIN	; Connect stdin and stdout
	sys_dup2	eax, STDOUT		; to socket
	sys_execve	application, execptrs, emptyenviron
	sys_write	STDERR, ExecFailed, 12
	jmp	do_exit	; Failed to exec!

ExecFailed	db	"exec failed", __n

itoa:		; From id.asm
	xor     ecx,ecx
	mov     ebx,ecx
	mov     bl,10
div_again:
	xor     edx,edx
	div     ebx
	add     dl,'0'
	push    edx
	inc     ecx
	test    eax,eax
	jnz     div_again
keep_popping:
	pop     eax
	stosb
	loop    keep_popping
	ret


atoi:	xor	eax, eax
	xor	ebx, ebx
	_mov	ecx, 10
atoi_again:
	mov	bl, [ebp]
	inc	ebp
	sub	bl, '0'
	jc	atoi_done
	cmp	bl, 9
	jg	atoi_done
	mul	ecx
	add	eax, ebx
	jmps	atoi_again
atoi_done:
	ret
	
strccpy_next:			; I am sure this is the smallest
	stosb			; strccpy I have ever seen
strccpy:			; (8 bytes)
	lodsb
	or	al, al
	jnz	strccpy_next
	ret

; These two items are here to facilitate compression (I believe tar padds)!
sockoptvals	dd	1	; What does this mean?
emptyenviron	dd	0	; Command gets no environ!

UDATASEG

application	resd	1024	; The program to execute
bindsockstruct	resd	4	; Bind the socket here!
address		resb	16	; Target address
sockaddress	resb	16	; Source address in compact form
uid		resd	0	; Run as this uid, union with consock
consock		resd	1	; The connected socket
execptrs	resd	3	; for sys_exec
passip		resb	1	; Set if the ip-addr is to be passed

END
