; Copyright (C) 2002 Thomas M. Ogrisegg
;
; nm(size) - list symbols (section sizes) from (of) ELF binary
;
; syntax:
;        nm [file-list]
;        size [file-list]
;
; If filename is omitted "a.out" will be listed
;
; License           :       GNU General Public License
; Author            :       Thomas Ogrisegg
; E-Mail            :       tom@rhadamanthys.org
; Version           :       0.7
; Release-Date      :       02/02/02
; Last updated      :       02/16/06
; SuSV2-Compliant   :       no
; GNU-compatible    :       no
;
; $Id: nm.asm,v 1.6 2002/08/16 15:07:08 konst Exp $

%include "system.inc"
%include "elfheader.inc"

CODESEG

aout	db	"a.out", EOL
errstr	db	"Error opening file "
errlen	equ	$ - errstr

header		db	"    text    data     bss     dec     hex filename", __n
headerlen	equ	$ - header

START:
	pop	ecx
	pop	esi

.n1:				; how we are called?
	lodsb
	or 	al,al
	jnz	.n1

	mov	dword [addr],do_nm
	cmp	word [esi-3],'nm'
	jz	.n2

	mov	dword [addr],do_size
	push	ecx
	sys_write STDOUT, header, headerlen
	pop	ecx

.n2:
	dec	ecx
	mov	[argc],ecx
	jnz	near argv_loop
	mov	ebx,aout

do_open:
	mov	[fname],ebx
	sys_open EMPTY, O_RDONLY
	or	eax,eax
	js	do_error
	mov	[fd],eax

	sys_lseek eax, 0, SEEK_END
	sys_mmap NULL, eax, PROT_READ, MAP_PRIVATE, [fd], 0
	mov	[ptr],eax

	call	[addr]
	sys_close [fd]
	jmp	argv_loop

do_error:
	sys_write STDOUT, errstr, errlen
	xor	edx,edx
	call	write_fname
	inc	dword [err]
argv_loop:
	pop	ebx
	or	ebx,ebx
	jnz	near do_open
do_exit:
	sys_exit [err]

;
;nm
;

do_nm:
	cmp	[argc],byte 2
	jb	.cont
	call	write_nl
	mov	dl,':'
	call	write_fname
.cont:
	mov	esi,eax
	movzx	ecx,word [eax+ELF32_Ehdr.e_shnum]
	add	eax,[eax+ELF32_Ehdr.e_shoff]
	sub	eax,byte 40
	;; search symtab entry ;;
.Lsrch_symtab:
	add	eax,byte 40
	dec	ecx
	jnz	.Lnext
	ret
.Lnext:
	cmp	byte [eax+ELF32_Shdr.sh_type],SHT_SYMTAB
	jnz	.Lsrch_symtab
	;; found symtab entry  ;;
.Lfound_symtab:
	push	eax
	push	ecx
	mov	[shdr],eax
	mov	ebx,[eax+ELF32_Shdr.sh_offset]
	mov	ecx,[eax+ELF32_Shdr.sh_size]
	shr	ecx,0x4		; sizeof(elf_sym)=16
	inc	ecx
	add	ebx,[ptr]
	sub	ebx,byte 0x10
.Lsrch_symbols:
	dec	ecx
	jz	near .Lback
	add	ebx,byte 0x10
	cmp	dword [ebx+ELF32_Sym.st_name],0
	jz	.Lsrch_symbols
.Lfound:
	pusha
	mov	edx,[eax+ELF32_Shdr.sh_link]
	imul	edx,40
	mov	eax,[ptr]
	add	eax,[eax+ELF32_Ehdr.e_shoff]
	add	eax,edx
	mov	edx,[eax+ELF32_Shdr.sh_offset]
	add	edx,[ptr]
	add	edx,[ebx+ELF32_Sym.st_name]
		
	mov	esi,edx
	mov	ecx,edx
	mov	ecx,[ebx+ELF32_Sym.st_value]
	mov	edi,buf
	call	.hextostr
	add	edx,byte 0x8
	add	edi,edx
	inc	edi
	mov	al,' '
.Lstrlen:
	stosb
	lodsb
	inc	edx
	or	al,al
	jnz	.Lstrlen

	mov	al, __n
	stosb
	mov	ecx,edi
	sub	ecx,edx
	sys_write STDOUT, ecx, edx
	popa
	jmp	.Lsrch_symbols
.Lback:
	pop	ecx
	pop	eax
.Lreturn:
	jmp	.Lsrch_symtab

;; %ecx <-
;; %edi ->
.hextostr:
	std
	add	edi,0x7
	mov	edx,0x8
.Lloop:
	mov	al,cl
	and	al,0xf
	add	al,'0'
	cmp	al,'9'
	jng	.Lstos
	;; 0x7 = Uppercase, 0x27 = Lowercase ;;
	add	al,0x27
.Lstos:
	stosb
	shr	ecx,0x4
	dec	edx
	jnz	.Lloop
	cld
	ret

write_fname:
	pusha
	mov	esi,[fname]
	mov	edi,esi
	xor	al,al
	xor	ecx,ecx
	dec	ecx
	repnz	scasb
	not	ecx
	or	dl,dl
	jz	.write
	dec	edi
	mov	al,dl
	stosb
.write:
	sys_write STDOUT, esi, ecx

	xor	al,al
	dec	edi
	stosb

	call	write_nl
	popa
	ret

write_nl:
	pusha
	sys_write STDOUT,.nl,1
	popa
	ret
.nl:	db	__n

;
;size
;

do_size:

	mov	dword [sizetext],0
	mov	dword [sizedata],0
	mov	dword [sizeheap],0

	mov	ebp,eax
	mov	eax,[ebp+ELF32_Ehdr.e_shoff]
	lea	edi,[eax+ebp]
	movzx	ecx,word [ebp+ELF32_Ehdr.e_shnum]
	sub	edi,byte 40
	call	.Lsection_loop
	mov	edi,buf
	mov	eax,[sizetext]
	call	ltostr
	add	edi,0x9
	mov	eax,[sizedata]
	call	ltostr
	add	edi,0x9
	mov	eax,[sizeheap]
	call	ltostr
	add	edi,0x9
	mov	eax,[sizetext]
	add	eax,[sizedata]
	add	eax,[sizeheap]
	push	eax
	call	ltostr
	add	edi,0x9
	pop	ecx
	call	.hextostr
	add	edi,0x9
	mov	esi,[fname]
	mov	al,' '
.Lstrcpy:
	stosb
	lodsb
	or	al,al
	jnz	.Lstrcpy
	mov	al,__n
	stosb
	sub	edi,buf
	sys_write STDOUT, buf, edi
	ret

.Lsection_loop:
	dec	ecx
	js	.Lret
	add	edi,byte 40
	mov	eax,[edi+ELF32_Shdr.sh_size]
	or	eax,eax
	jz	.Lsection_loop
	cmp	dword [edi+ELF32_Shdr.sh_type],SHT_NOBITS
	jz	.Ladd_bss
	mov	edx,[edi+ELF32_Shdr.sh_flags]
	cmp	dword [edi+ELF32_Shdr.sh_flags],(SHF_EXECINSTR | SHF_ALLOC)
	je	.Ladd_text
	cmp	dword [edi+ELF32_Shdr.sh_flags],(SHF_WRITE | SHF_ALLOC)
	je	.Ladd_data
	jmp	.Lsection_loop
.Ladd_bss:
	add	[sizeheap],eax
	jmp	.Lsection_loop
.Ladd_text:
	add	[sizetext],eax
	jmp	.Lsection_loop
.Ladd_data:
	add	[sizedata],eax
	jmp	.Lsection_loop
.Lret:
	ret

;

.hextostr:
	std
	add	edi,0x7
	mov	edx,0x7
.Lloop:
	mov	al,cl
	and	al,0xf
	add	al,'0'
	cmp	al,'9'
	jng	.Lstos
	;; 0x7 = Uppercase, 0x27 = Lowercase ;;
	add	al,0x27
.Lstos:
	stosb
	shr	ecx,0x4
	jecxz	.Lout
	dec	edx
	jnz	.Lloop
.Lout:
	mov	ecx,edx
	mov	al,' '
	repnz	stosb
	cld
	ret
;

ltostr:
	mov	ebx,0xa
	mov	ecx,0x7
	or	eax,eax
	jnz	.Ldiv
	mov	byte [edi+ecx],'0'
	dec	ecx
	jmp	.Lout
.Ldiv:
	or	eax,eax
	jz	.Lout
	xor	edx,edx
	idiv	ebx
	add	dl,'0'
	mov	byte [edi+ecx],dl
	dec	ecx
	jnz	.Ldiv
.Lout:
	add	edi,ecx
	inc	ecx
	std
	mov	al,' '
	repnz	stosb
	cld
	ret

UDATASEG

argc	DWORD	1
fname	DWORD	1
fd	INT	1
ptr	DWORD	1
addr	DWORD	1
err	INT	1

shdr	LONG	1
link	LONG	1

sizetext	LONG	1
sizedata	LONG	1
sizeheap	LONG	1

buf	UCHAR	100

END
