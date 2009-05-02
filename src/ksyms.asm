;Copyright (C) 2003 Nick Kurshev <nickols_k@mail.ru>
;
;$Id: ksyms.asm,v 1.3 2003/05/26 15:25:21 nickols_k Exp $
;
;hackers' ksyms
;
;syntax: ksyms
;
; Usage: ksyms [-ahoV]
; -a  show all symbols (include kernel's)
; -h  supress column header
; -o  display symbols for given module only!!! [doesn't exist in modutils]
; -V  display version
;
;0.01: 25-May-2003	initial release (note: some code was borrowed from other sources of this project)
;
; TODO: auto update of symbol 'vers'
;	dynamic allocation of 'stmp' instead of reserving 130K in UDATASEG.
;

%include "system.inc"

STRUC module_symbol
.value:		resd	1
.name:		resd	1
ENDSTRUC

CODESEG


%assign	BUFSIZE	0x20000

START:
	push	ebp
	mov	ebp, esp

	cmp	[ebp+4], byte 2		;; args
	jl	.do
	mov	esi, [ebp+12]		;; argv[1]
	cmp	word [esi], '-V'	;; version info
	jne	.no_ver
	mov	esi, vers
	call	printS
	jmps	.success_exit
.no_ver:
	cmp	word [esi], '-h'	;; skip column header
	je	.no_header
	mov	esi, header
        call	printS
.no_header:
	mov	esi, [ebp+12]		;; argv[1]
	cmp	word [esi], '-o'	;; given module only
	jne	.do
	cmp	[ebp+4], byte 3
	jge	.get_mod_name		;; not enough arguments
	xor	esi, esi
	call	print_modsym
	jmps	.success_exit
.get_mod_name:
	mov	esi,	[ebp+16]	;; argv[3]
	call	print_modsym
	jmps	.success_exit
.do:
	sys_query_module NULL, QM_MODULES, buf, BUFSIZE, qret
	test	eax,eax
	js	.do_exit

	mov	ecx,[qret]
	mov	esi,edx
.show_info:
	call	print_modsym
.copy_names:
	lodsb
	test	al, al
	jnz	.copy_names
	loop	.show_info

	cmp	[ebp+4], byte 2		;; args
	jl	.do_exit
	mov	esi, [ebp+12]		;; argv[1]
	cmp	word [esi], '-a'	;; display kernel symbols too
	jne	.do_next
	xor	esi, esi
	call	print_modsym
.do_next:
.success_exit:
	xor	eax, eax
.do_exit:
	sys_exit eax
	
print_modsym:
; ARGS:
; esi - module name
	push	ebp
	mov	ebp, esp
	sub	esp, 12
	mov	[ebp-4], esi
	pusha
.next:
	sys_query_module [ebp-4], QM_SYMBOLS, stmp, BUFSIZE, sqret
	test	eax, eax
	jns	.do_module
	mov	edi, tmp
	mov	ecx, 16
	call	itoa
	sys_write STDOUT, tmp, 8
	mov	esi, errmsg
	call	printS
	mov	esi, space2
	call	printS
	mov	esi, [ebp-4]
	call	printS
	mov	esi, eol
	call	printS
	jmp	.loc_exit
.do_module:
	mov	ecx, [sqret]
	mov	edx, stmp
	mov	[ebp-8], edx
	mov	[ebp-12], edx
.module_loop:
	push	ecx
	mov	eax, [ebp-8]
	mov	eax, [eax+module_symbol.value]
	mov	edi, tmp
	mov	ecx, 16
	call	itoa
	sys_write STDOUT,tmp,8
	mov	esi, space2
	call	printS
	mov	esi, [ebp-8]
	mov	esi, [esi+module_symbol.name]
	add	esi, [ebp-12] ;; convert offset into string pointer
	call	printS
	mov	esi, [ebp-4]
	test	esi, esi
	jz	.noname
	mov	ecx, dword 32
	sub	ecx, eax
	jbe	.notabs
.tabs:
	mov	esi, space
	call	printS
	loop	.tabs
.notabs:
	mov	esi, space2
	call	printS
	mov	esi, obr
	call	printS
	mov	esi, [ebp-4]
	call	printS
	mov	esi, cbr
	call	printS
.noname:
	mov	esi, eol
	call	printS
	mov	edx, [ebp-8]
	add	edx, module_symbol_size
	mov	[ebp-8], edx
	pop	ecx
	loop	.mloop
	jmps	.loc_exit
.mloop:
	jmp	.module_loop
.loc_exit:
	popa
	leave
	ret

;itoa (unsigned long value, char *string, int radix)
;
;print 32 bit number as binary,octal,decimal,or hexadecimal value
;
;<EAX	unsigned long value
;<EDI	char *string
;<ECX	base    (2, 8, 10, 16, or another one)

itoa:
	push	edi
	call	.printB
	pop	edx

	mov	al,__t
	stosb

	cmp	cl,0x10
	jnz	.done

	sub	edx,edi
	cmp	dl,-7
	jbe	.done

	stosb

.done:
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

printS:
; ARGS: esi - source
; returns eax - strlen
	test	esi, esi
	jz	.exit
	push	ecx
	push	esi
	xor	ecx, ecx
.loop:
	lodsb
	test	al, al
	jz	.done
	inc	ecx
	jmps	.loop
.done:
	pop	esi
	push	ecx
	sys_write STDOUT,esi,ecx
	pop	eax	; return value
	pop	ecx
.exit:
	ret

DATASEG
vers	db	"hackers' ksyms v 0.1",__n,0
header	db	'Address   Symbol                            Defined by',__n,0
errmsg		db	"error",0
eol		db	__n,0
space		db	' ',0
space2		db	'  ',0
obr		db	'[',0
cbr		db	']',0

UDATASEG
buf	resb	BUFSIZE
tmp	resb	BUFSIZE
stmp	resb	BUFSIZE
sqret	resd	1
qret	resd	1


END
