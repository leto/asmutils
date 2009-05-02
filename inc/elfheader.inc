;
; The ELF header structure - (c) 2k by veedee
;
; $Id: elfheader.inc,v 1.2 2002/02/16 17:54:37 konst Exp $

; ---[ 32-Bit ELF base types ]---
%define Elf32_Addr	resb 4	;Unsigned program address
%define Elf32_Half	resb 2	;Unsigned medium integer
%define Elf32_Off	resb 4	;Unsigned file offset
%define Elf32_Sword	resb 4	;Signed large integer
%define Elf32_Word	resb 4	;Unsigned large integer
%define Elf32_Section	resb 2	;Type for section indices
%define Elf32_Versym	Elf32_Half	;Type for section indices

; ---[ e_ident[] constants ]---
;-> EI_MAG
%define ELFMAG0		0x7f	;(7Fh)
%define ELFMAG1		'E'	;(45h)
%define ELFMAG2		'L'	;(4Ch)
%define ELFMAG3		'F'	;(46h)
%define ELFMAG		464C457Fh
;-> EI_CLASS
%define ELFCLASSNONE	0	;Invalid class
%define ELFCLASS32	1	;32-bit objects
%define ELFCLASS64	2	;64-bit objects
%define	ELFCLASSNUM	3
;-> EI_DATA
%define ELFDATANONE	0	;Invalid data encoding
%define ELFDATA2LSB	1	;2's complement, little endian
%define ELFDATA2MSB	2	;2's complement, big endian
;-> EI_VERSION (e_version)
%define EV_NONE		0	;Invalid version
%define EV_CURRENT	1	;Current version
%define EV_NUM		2

; ---[ Elf32_Ehdr constants ]---
%define EI_NIDENT	16
;-> e_type (ELF file types)
%define ET_NONE		0	;No file type
%define ET_REL		1	;Relocatable file
%define ET_EXEC		2	;Executable file
%define ET_DYN		3	;Shared object file
%define ET_CORE		4	;Core file
%define ET_LOPROC	0xff00	;Processor-specific
%define ET_HIPROC	0xffff	;Processor-specific
;-> e_machine (various ELF target machines)
%define	EM_NONE		0	;No machine
%define EM_M32		1	;AT&T WE 32100
%define EM_SPARC	2	;SPARC
%define	EM_386		3	;Intel 80386
%define	EM_68K		4	;Motorola 68000
%define EM_88K		5	;Motorola 88000
%define EM_486		6	;(Perhaps disused)
%define EM_860		7	;Intel 80860
%define EM_MIPS		8	;MIPS R3000 (oficially, big-endian only)
%define EM_MIPS_RS4_BE 	10	;MIPS R4000 (big endian)
%define EM_PARISC	15	;HPPA
%define EM_SPARC32PLUS 	18	;Sun's "v8plus"
%define EM_PPC		20	;PowerPC
%define EM_SH		42	;SuperH
%define EM_SPARCV9	43	;SPARC v9 64-bit
%define EM_IA_64	50	;HP/Intel IA-64
%define EM_ALPHA	0x9026	;interim value for ALPHA
%define EM_S390		0xA390	;interim value for S390 architecture

; ---[ Elf32_Shdr constants ]---
;-> sh_type
%define SHT_NULL	0
%define SHT_PROGBITS	1
%define SHT_SYMTAB	2
%define SHT_STRTAB	3
%define	SHT_RELA	4
%define	SHT_HASH	5
%define	SHT_DYNAMIC	6
%define	SHT_NOTE	7
%define	SHT_NOBITS	8
%define	SHT_REL		9
%define	SHT_SHLIB	10
%define	SHT_DYNSYM	11
%define SHT_NUM		12
%define	SHT_LOPROC	0x70000000
%define	SHT_HIPROC	0x7fffffff
%define	SHT_LOUSER	0x80000000
%define	SHT_HIUSER	0xffffffff
%define	SHT_MIPS_LIST		0x70000000
%define	SHT_MIPS_CONFLICT	0x70000002
%define	SHT_MIPS_GPTAB		0x70000003
%define	SHT_MIPS_UCODE		0x70000004
;-> sh_flags
%define SHF_WRITE	0x1
%define SHF_ALLOC	0x2
%define SHF_EXECINSTR	0x4
%define SHF_MASKPROC	0xf0000000
%define SHF_MIPS_GPREL	0x10000000

; ---[ Elf32_Phdr constants ]---
;-> p_type
%define PT_NULL		0
%define PT_LOAD		1
%define PT_DYNAMIC	2
%define PT_INTERP	3
%define PT_NOTE		4
%define PT_SHLIB	5
%define PT_PHDR		6
%define PT_LOPROC	0x70000000
%define PT_HIPROC	0x7fffffff
%define PT_MIPS_REGINFO	0x70000000
;-> p_flags
%define PF_R		0x4
%define PF_W		0x2
%define PF_X		0x1

struc e_ident
	.EI_MAG		resb 4	;ELF "magic number" (0x7f, 'ELF')
	.EI_CLASS	resb 1	;file's class, or capacity
	.EI_DATA	resb 1	;data encoding of the cpu-specific data
	.EI_VERSION	resb 1	;ELF header version number (set to EV_CURRENT)
	.EI_PAD		resb 1	;marks the beginning of the unused bytes
	.EI_NIDENT	resb 8	;unused bytes in e_ident
endstruc

struc ELF32_Ehdr
	;see e_ident structure above
.e_ident        resb EI_NIDENT
	;identification word for the object file type
.e_type         Elf32_Half	;resw 1
	;specification for the required architecture for an individual file
.e_machine      Elf32_Half	;resw 1
	;identification for the object file version
.e_version      Elf32_Word	;resd 1
	;virtual address to which the system transfers control, thus
	;starting process
.e_entry        Elf32_Addr	;resd 1
	;PROGRAM header table's file offset in bytes
.e_phoff        Elf32_Off	;resd 1
	;SECTION header table's file offset in bytes
.e_shoff        Elf32_Off	;resd 1
	;processor-specific flags associated with the file
.e_flags        Elf32_Word	;resd 1
	;ELF header size in bytes
.e_ehsize       Elf32_Half	;resw 1
	;PROGRAM header table entry size
.e_phentsize    Elf32_Half	;resw 1
	;PROGRAM header table entry count
.e_phnum        Elf32_Half	;resw 1
	;SECTION header table entry size
.e_shentsize    Elf32_Half	;resw 1
	;SECTION header table entry count
.e_shnum        Elf32_Half	;resw 1
	;the section header table index of the entry associated with the
	;section name string table
.e_shstrndx     Elf32_Half	;resw 1
endstruc

struc ELF32_Shdr
	;name of the section
.sh_name	Elf32_Word	;resd 1
	;section's contents and semantics.section types:
.sh_type	Elf32_Word	;resd 1
	;1-bit flags that describe miscellaneous attributes
.sh_flags	Elf32_Word	;resd 1
	;the address at which the section's first byte should reside
.sh_addr	Elf32_Addr	;resd 1
	;the byte offset from the BOF to the first byte in the section
.sh_offset	Elf32_Off	;resd 1
	;the section's size in bytes
.sh_size	Elf32_Word	;resd 1
	;this member holds a section header table index link
	;-----
	;<sh_type>	<sh_link>			<sh_info>
	;SHT_DYNAMIC	The section header index of	0
	;	the string table used by entries in the section
	;
	;SHT_HASH	The section header index of	0
	;	the symbol table to which the hash applies
	;
	;SHT_REL	The section header index of	The section header
	;SHT_RELA	the associated symbol table	index of the section
	;						to which the
	;						relocation applies
	;SHT_SYMTAB	The section header index of	One greater than the 
	;SHT_DYNSYM	the associated string table	symbol table index of
	;						the last local symbol
	;other		SHN_UNDEF			0
.sh_link	Elf32_Word	;resd 1
	;extra informations
.sh_info	Elf32_Word	;resd 1
	;address alignment constraint
.sh_addralign	Elf32_Word	;resd 1
	;the size in bytes of each entry in a table of fixed-size entries
.sh_entsize	Elf32_Word	;resd 1
endstruc

struc ELF32_Phdr
	;the type of segment
.p_type		Elf32_Word	;resd 1
	;the offset from the BOF at which the 1st byte of the segment resides
.p_offset	Elf32_Off	;resd 1
	;the virtual address at which the 1st byte of the segment resides in
	;MEMORY
.p_vaddr	Elf32_Addr	;resd 1
	;reserved for the segment's physical address
.p_paddr	Elf32_Addr	;resd 1
	;the number of bytes in the FILE image of the segment
.p_filesz	Elf32_Word	;resd 1
	;the number of bytes in the MEMORY image of the segment
.p_memsz	Elf32_Word	;resd 1
	;flags relevant to the segment
.p_flags	Elf32_Word	;resd 1
	;the value to which the segments are aligned in memory and in the file
.p_align	Elf32_Word	;resd 1
endstruc

struc ELF32_Sym
	;Symbol name (string tbl index)
.st_name	Elf32_Word
	;Symbol value
.st_value	Elf32_Addr
	;Symbol size
.st_size	Elf32_Word
	;Symbol type and binding
.st_info	UCHAR	1
	;Symbol visibility
.st_other	UCHAR	1
	;Section index
.st_shndx	Elf32_Section
endstruc
