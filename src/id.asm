;Copyright (C) 1999 Dmitry Bakhvalov <dl@gazeta.ru>
;
;$Id: id.asm,v 1.6 2001/08/14 18:55:38 konst Exp $
;
;hackers' id
;
;0.01: 25-Oct-1999	initial release
;0.02: 07-Apr-2000	squeezed few bytes (KB)
;0.03: 11-Aug-2001	added groups=list  (JH)
;
;syntax: id
;        No options so far.
;	 
;	 Always returns 0
;
		%include "system.inc"
		
		CODESEG
		
START:
		sys_getuid
		mov	ebx,"uid="
		call	print_stuff
		
		sys_getgid
		mov	bl,'g'			; ebx="gid="
		call	print_stuff
		
		call	.groups
	
		mov	cl,10			; print "\n"
		push	ecx
		sys_write STDOUT,esp,1
		
		sys_exit_true

.groups:	;*** Get GROUPS
		sys_getgroups   64, groups
		mov	ebp, eax
		mov	dl, 7		; Looks like a bug, but it works.
		mov	ecx, gstuff
		sys_write	STDOUT

		mov	esi, groups
		or	ebp, ebp
		jz	.nogroups
.forallgroups:
		mov	edi, num_buf
		push	edi
		mov	ax, [esi]
		inc	esi
		inc	esi
		call	bin_to_dec
		dec	ebp
		or	ebp, ebp
		jz	.nocomma
		mov	al, ','
		stosb
.nocomma:
		mov	edx, edi
		pop	ecx
		sub	edx, ecx
		sys_write	STDOUT
		or	ebp, ebp
		jnz	.forallgroups
.nogroups:
		ret

print_stuff:
		pushad
		
		test	eax,eax
		js	.error

		mov	edi,num_buf
		push	edi			; save num_buf
		push	ebx			; save "uid="
		call	bin_to_dec
		mov	al,9
		stosb		
		
		pop	ebx			; restore "uid="
		
		push	ebx			; put "uid=" on the stack
		mov	ecx,esp			; point ecx to it
		mov	dl,4			; len=4
		sys_write STDOUT		; write
		pop	ebx			; restore stack

		pop	esi			; restore num_buf
		
		mov	ecx,esi			; save it in ecx
		mov	edx,edi
		sub	edx,ecx
		
		; ecx already holds string, edx holds strlen
		sys_write STDOUT

.error:	
		popad
		ret

bin_to_dec:	; Pointer to num_buf in edi, number in eax
		xor	ecx,ecx		
		mov	ebx,ecx
		mov	bl,10
.div_again:		
		xor	edx,edx
		div	ebx
		add	dl,'0'
		push	edx
		inc	ecx
		test	eax,eax
		jnz	.div_again
.keep_popping:		
		pop	eax
		stosb
		loop	.keep_popping
		ret

gstuff		db	'groups='

		UDATASEG
groups:		resw	64
num_buf:	resb	16
		
		END
