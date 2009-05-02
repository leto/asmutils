; Copyright (C) 1999 Brian Raiter <breadbox@muppetlabs.com>
;
; $Id: elf.inc,v 1.3 2002/02/02 12:33:38 konst Exp $
;
; file		: elf.inc
; created	: 20-Aug-1999
; modified	: 27-Jan-2002
; version	: 0.16
; assembler	: nasm 0.98
; description	: macro definitions for defining a simple ELF executable
;		  file image. These macros must be used with files
;		  assembled with the "bin" output format.
; author	: Brian Raiter <breadbox@muppetlabs.com>
; comment	: can be used separately or included from system.inc


%ifndef __ELF_INC
%define __ELF_INC


; BEGIN_ELF marks the beginning of an ELF image. It includes an ELF
; header and program header table. This must appear prior to any
; instructions or pseudo-instructions. All other macros in this file
; require the presence of BEGIN_ELF.
;
; The label _text will be defined to mark the contents following the
; program header table.

%macro BEGIN_ELF 0
%push elf
BITS 32

;
;e_ident[EI_OSABI] values
;

%assign ELFOSABI_SYSV		0	;UNIX System V ABI
%assign ELFOSABI_NONE		ELFOSABI_SYSV	;symbol used in old spec
%assign ELFOSABI_HPUX		1	;HP-UX operating system
%assign ELFOSABI_NETBSD		2	;NetBSD
%assign ELFOSABI_LINUX		3	;GNU/Linux
%assign ELFOSABI_HURD		4	;GNU/Hurd
%assign ELFOSABI_86OPEN		5	;86Open common IA32 ABI
%assign ELFOSABI_SOLARIS	6	;Solaris
%assign ELFOSABI_MONTEREY	7	;Monterey
%assign ELFOSABI_IRIX		8	;IRIX
%assign ELFOSABI_FREEBSD	9	;FreeBSD
%assign ELFOSABI_TRU64		10	;TRU64 UNIX
%assign ELFOSABI_MODESTO	11	;Novell Modesto
%assign ELFOSABI_OPENBSD	12	;OpenBSD

%ifdef		__LINUX__
%assign %$osabi	ELFOSABI_LINUX
%elifdef	__FREEBSD__
%assign %$osabi	ELFOSABI_FREEBSD
%elifdef	__OPENBSD__
%assign %$osabi	ELFOSABI_OPENBSD
%elifdef	__NETBSD__
%assign %$osabi	ELFOSABI_NETBSD
%else
%assign %$osabi	ELFOSABI_SYSV
%endif

%assign	%$origin	0x08048000

		org	%$origin
		db	0x7F, 'ELF'		; e_ident
		db	1, 1, 1
		db	%$osabi			; e_ident[EI_OSABI]
	times 8	db	0
		dw	2			; e_type
		dw	3			; e_machine
		dd	1			; e_version
		dd	START			; e_entry
		dd	%%phdr - $$		; e_phoff
		dd	0			; e_shoff
		dd	0			; e_flags
		dw	0x34			; e_ehsize
		dw	0x20			; e_phentsize
%%phdr:		dw	1			; e_phnum	; p_type
		dw	0			; e_shentsize
		dw	0			; e_shnum	; p_offset
		dw	0			; e_shstrndx
		dd	$$					; p_vaddr
		dd	$$					; p_paddr
		dd	_elf_filesz				; p_filesz
		dd	_elf_memsz				; p_memsz
		dd	_elf_phdr_flags
		dd	0x1000					; p_align
_text:
%endmacro


; ELF_DATA marks the end of the ELF file image proper, and the
; beginning of the "BSS section". Between ELF_DATA and END_ELF, the
; programmer may declare "uninitialized" data (actually, the data will
; always be initialized to zero) using the RESB family of
; pseudo-instructions. These data will not take up space in the
; executable file, but will be allocated when the executable is loaded
; into memory.
;
; Note that if the ELF_DATA macro is not used, the program will be run
; in non-writeable memory. If the program needs to be able to modify
; itself, it should therefore include an empty ELF_DATA section.
;
; The label _data will be defined to mark the beginning of the
; ELF_DATA section.

%macro ELF_DATA 0
%repl elfdata
_elf_filesz	equ	$ - $$
[absolute %$origin + _elf_filesz]
_data:
%endmacro


; ELF_ISTRUC, ELF_AT, and ELF_IEND work in the same fashion as Nasm's
; ISTRUCT, AT, and IEND builtin macros, with the exception that they
; define "uninitialized" memory, and therefore may be used inside an
; ELF_DATA section.

%macro ELF_ISTRUC 1
%push elf_istruc
%define	%$strucname %1
%$strucstart:
%endmacro

%macro ELF_AT 1-2+
resb %1-($-%$strucstart)
%2
%endmacro

%macro ELF_IEND 0
resb %{$strucname}_size - ($ - %$strucstart)
%pop
%endmacro


; ELF_BSTRUC is a more succinct method for using a Nasm structure
; definition within an ELF_DATA section. The first argument names a
; previously defined structure. The following arguments indicate the
; members of that structure to declare here.
;
; Please note that the fields of the structure must have been defined
; as local labels (i.e., with a dot prefix).

%macro ELF_BSTRUC 1-*
%push foo
%define %$strucname %1
%%top_%$strucname:
%rep %0 - 1
%rotate 1
resb %{$strucname}%1 - ($ - %%top_%$strucname)
%1:
%endrep
resb %{$strucname}_size - ($ - %%top_%$strucname)
%pop
%endmacro


; END_ELF marks the end of an ELF image. No instructions or
; pseudo-instructions should appear after it. Its placement determines
; the size of the file and the memory image.

%macro END_ELF 0
_elf_memsz	equ	$ - %$origin
%ifctx elfdata
_elf_phdr_flags	equ	7
%else
_elf_filesz	equ	_elf_memsz
_elf_phdr_flags	equ	5
%endif
%pop
%endmacro


%endif
