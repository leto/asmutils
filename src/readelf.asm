;|----------------------------------------------------------------------------|
;| ReadELF utility, copywrong (c) 2k by Radu Bogdan RUSU <veedee@asmania.com> |
;|----------------------------------------------------------------------------|
;|                                                                            |
;| File          : readelf.asm                                                |
;| Version	 : 0.1 (first release)                                        |
;|                 0.2 - reduced the binary size using "%assign" instead of   |
;|                       "equ $-"                                             |
;| Last modified : Tue Oct 24 14:55:07 2000                                   |
;| Author        : Radu Bogdan Rusu <veedee@asmania.com>                      | 
;|                 http://asmania.com/~veedee                                 |
;| Assembler     : nasm 0.98                                                  |
;| Description   : Shows informations concerning the ELF internal structure of|
;|                 an ELF executable file. A good utility (if I may say so ;).|
;| Comment       : Currently it only displays informations about the ELF      |
;|                 Header, the Section Header Table (SHT) and the Program     |
;|                 Header Table (PHT). Future versions (0.2+) will support the|
;|                 Symbol Table, Relocation, Dynamic Structures...everything  |
;|                 that should be here and (for some reasons) it's not.       |
;|                 I had the readelf utility (written in C by hjl@lucon.org   |
;|                 probably) distributed with the binutils package in mind, so|
;|                 the output should look almost the same.                    |
;| Requires	 : asmutils package, nasm                                     |
;|----------------------------------------------------------------------------|
;
; $Id: readelf.asm,v 1.5 2002/02/19 12:36:43 konst Exp $                                                                         

BITS 32

%include "system.inc"		;include Konstantin's macros

%include "elfheader.inc" 	;include the ELF Header structures

%assign lf	0Ah
%define DEC	10
%define HEXA	16

%assign IDstrlen	31
%assign ARCHstrlen	30
%assign Byteslen	19
%assign BytesSlen	9
%assign Magiclen	11
%assign CLASSlen	37
%assign Class32len	27
%assign Class64len	27
%assign DATAlen		37
%assign dataLSBlen	42
%assign dataMSBlen	39
%assign IDlen		37
%assign ARCHlen		37
%assign VERlen		37
%assign VERcurrentlen	29
%assign VERinvalidlen	26
%assign ENTRYlen	37
%assign PHTlen		37
%assign SHTlen		37
%assign FLAGSlen	39
%assign ELFlen		37
%assign PHTSizelen	37
%assign PHTentrylen	37
%assign SHTSizelen	37
%assign SHTentrylen	37
%assign SHTindexlen	37

%assign Classunknownlen	37
%assign Datalen		40
%assign IDunknownlen	34
%assign IDproclen	28
%assign ARCHunknownlen	30
%assign VERunknownlen	24
%assign ENTRYunklen	13
%assign sectionstrlen	81
%assign segmentstrlen	81
%assign SHTnumberlen	57
%assign PHTnumberlen	55
%macro Nr2ASCII 4
;Expects:
; %1 = number to convert
; %2 = DEC/HEXA conversion
; %3 = address of buffer to put the ASCII string on
; %4 = variable to store the length of the resulted ASCII string
	pushad
%ifnidn %1, EMPTY
	mov eax, %1
%endif
%ifnidn %2, EMPTY
	mov ecx, %2
%endif
%ifnidn %3, EMPTY
	mov edi, %3
%endif
	call NumberToString	;conver the number to an ASCII string and
	mov [%4], esi		;get its length in ESI
	popad
%endmacro

CODESEG

%assign usagelen	345
%assign noelflen	79
%assign elflen		13
%assign Sectionlen	19
%assign Segmentlen	18
%assign filelen		10
%assign nosectionslen	38
%assign nosegmentslen	45
usage	db 'Usage is: readelf <options> [file name]',lf
	db 'Where <options> are: -H = Display the ELF file header', lf
	db '                     -S = Display the section headers', lf
	db '                     -P = Display the program headers', lf
	db '                     -A = Show informations about all the above',lf
	db 'You are curently using readelf v0.2. Please report bugs to veedee@asmania.com',lf,lf
noelfmsg	db 'readelf: Error: Not an ELF file - it has the wrong magic bytes at the start',lf,07h,07h,07h
elfmsg		db lf,'ELF Header:',lf
Sectionmsg	db lf,lf,'Section Headers:',lf
Segmentmsg	db lf,lf,'Program Header:',lf
filemsg		db 'Analyzing '
nosections	db lf,'There are no sections in this file.',lf,lf
nosegments	db lf,'There are no program headers in this file.',lf,lf


;
; Beginning of actual code
;
START:
; Check the number of parameters and get the 1st parameter.
	pop eax			;get argument counter (argc)
	cmp eax, byte 3		;we need at least 3 parameters
	jae .getparam
.noparam:
	sys_write EMPTY, usage, usagelen	;write the "HOWTO" :)
	jmp do_exit		;and return to caller

.getparam:
	pop eax			;get our own name (argv[0])
	pop eax			;get the first parameter (argv[1])
	cmp byte [eax], '-'
	jne .noparam

	cmp byte [eax+1], 'H'
	jne .noheader
	inc byte [Header]
.noheader:
	cmp byte [eax+1], 'S'
	jne .noSHT
	inc byte [Sect]
.noSHT:
	cmp byte [eax+1], 'P'
	jne .noPHT
	inc byte [Segm]
.noPHT:
	cmp byte [eax+1], 'A'
	jne .noALL
	inc byte [Segm]
	inc byte [Sect]
	inc byte [Header]
.noALL:
	pop eax
	mov ecx, eax		;get the 2nd parameter in ECX
	push ecx		;and save its address on stack

;==============================================================================
; Reading and displaying informations about the ELF header
;==============================================================================
; Open the file specified as the 1st parameter.
	xchg eax, ebx		;put the pathname in EBX
	sys_open EMPTY, O_RDONLY
	xchg eax, ebx		;put the FD in EBX
	mov [fhandle], ebx

; Read the entire ELF Header in memory (e_ident[16] + 36 bytes)
	sys_read EMPTY, ehdr, ELF32_Ehdr_size

; Check the first four bytes and see if they match the ELF 'magic number'
	cmp dword [ecx], ELFMAG		;ecx = ehdr.e_ident
	je ELF

	pop ecx			;clear the stack (previously saved argv[1])
	sys_close EMPTY				;close the FD
	sys_write STDOUT, noelfmsg, noelflen	;the file is not ELF
do_exit:
	sys_exit eax

; File is an ELF... let's do our thang'
;======================================
ELF:
	sys_write STDOUT, filemsg, filelen
		
	pop ecx			;pop it from stack
	mov edx, ecx		;mark the beginning
.loopfind:
	inc ecx			;check each character
	cmp byte [ecx], 0	;end of string?
	jne .loopfind
	xchg edx, ecx		;get the argv[1]'s address back in ECX
	sub edx, ecx		;and adjust the length
	
	sys_write		;write the argv[1]
	sys_write EMPTY, elfmsg, 1

; -----------[ Write informations about the ELF header to STDOUT ]-----------
	cmp byte [Header], 0
	je .noheader
	call describeheader
; -----------[ Write informations about the Section Header Table ]-----------
.noheader:
	cmp byte [Sect], 0
	je .noSHT
	call readSHT
; -----------[ Write informations about the Program Header Table ]-----------
.noSHT:
	cmp byte [Segm], 0
	je .close
	call readPHT

; Close the file
.close:
	sys_close [fhandle]
	jmp do_exit


;==============================================================================
; Reading and Displaying informations about the Program Header Table
;==============================================================================
readPHT:
	xor eax, eax
	mov ax, word [ehdr.e_phnum]
	cmp ax,0 		;no entries in the PHT?
	jne .goPHT
	sys_write STDOUT, nosegments, nosegmentslen
	ret
.goPHT:
	Nr2ASCII EMPTY, DEC, PHTnumber+11, length
	Nr2ASCII [ehdr.e_phoff], HEXA, PHTnumber+50, length 
	sys_write STDOUT, PHTnumber, PHTnumberlen

	sys_write EMPTY, Segmentmsg, Segmentlen
	sys_write EMPTY, segmentstr, segmentstrlen
; Seek to the beginning of the PHT
	sys_lseek [fhandle], [ehdr.e_phoff], SEEK_SET
	xor ecx, ecx
.describePHT:
	push ecx
	sys_read [fhandle], phdr, ELF32_Phdr_size
	pop ecx
	call describePHT
	inc ecx
	cmp cx, word [ehdr.e_phnum]
	jne .describePHT
	ret

; ----------------------------------------------------------------------------
;             ---[ Make all the entries in the PHT readable ]---
; ############################################################################
describePHT:
	pushad
	xor eax, eax
	mov edi, PHTLine
	mov al, ' '
	mov ecx, 80
	rep stosb

; -------------- p_type --------------
	push ebp
	xor ebp, ebp
	mov eax, [phdr.p_type]
.PTYPEcheck:
	cmp eax, [ebp+PTYPEstrings]
	jne .PTYPErecheck

	mov esi, PTYPEstrings+4	;copy from PTYPEstrings to PHTLine
	add esi, ebp
	mov ecx, PTYPElen
	mov edi, PHTLine+2
	rep movsb
	jmps .poffset
.PTYPErecheck:
	add ebp, PTYPElen+4
	cmp ebp, PTYPEstringslen
	jne .PTYPEcheck

; -------------- p_offset --------------
.poffset:
	pop ebp
	mov word [PHTLine+17], '0x'
	mov eax, [phdr.p_offset]
	mov ebx, 6
	mov edi, PHTLine+19
	call addZeros

; -------------- p_vaddr --------------
	mov word [PHTLine+26], '0x'
	mov eax, [phdr.p_vaddr]
	mov ebx, 8
	mov edi, PHTLine+28
	call addZeros

; -------------- p_paddr --------------
	mov word [PHTLine+37], '0x'
	mov eax, [phdr.p_paddr]
	mov ebx, 8
	mov edi, PHTLine+39
	call addZeros
	
; -------------- p_filesz --------------
	mov word [PHTLine+48], '0x'
	mov eax, [phdr.p_filesz]
	mov ebx, 5
	mov edi, PHTLine+50
	call addZeros
	
; -------------- p_memsz --------------
	mov word [PHTLine+56], '0x'
	mov eax, [phdr.p_memsz]
	mov ebx, 5
	mov edi, PHTLine+58
	call addZeros
	
; -------------- p_flags --------------	
	mov edi, PHTLine+64
	mov eax, [phdr.p_flags]
	test eax, PF_R
	jz .write
	mov [edi], byte 'R'
.write:
	inc edi
	test eax, PF_W
	jz .exec
	mov [edi], byte 'W'
.exec:
	inc edi
	test eax, PF_X
	jz .palign
	mov [edi], byte 'X'
	
; -------------- p_aling --------------
.palign:
	mov word [PHTLine+68], '0x'
	Nr2ASCII [phdr.p_align], HEXA, PHTLine+70, length
	
asd:
	mov byte [PHTLine+80], lf
	sys_write STDOUT, PHTLine, 81
	popad
	ret

;==============================================================================
; Reading and Displaying informations about the Section Headers
;==============================================================================
readSHT:
	xor eax, eax
	mov ax, word [ehdr.e_shnum]

	cmp ax, 0		;no entries in the SHT?
	jne .goSHT
	sys_write STDOUT, nosections, nosectionslen
	ret
.goSHT:
	Nr2ASCII EMPTY, DEC, SHTnumber+11, length
	Nr2ASCII [ehdr.e_shoff], HEXA, SHTnumber+52, length 
	sys_write STDOUT, SHTnumber, SHTnumberlen

	sys_write STDOUT, Sectionmsg, Sectionlen
	sys_write EMPTY, sectionstr, sectionstrlen

	mov eax, ELF32_Shdr_size
	mov ebx, [ehdr.e_shstrndx]	;SHT index of the section string table
	mul ebx				;point to the String Table in the SHT
	add eax, [ehdr.e_shoff]		;eax = String Table offset in the file
	sys_lseek [fhandle], eax, SEEK_SET
; Read the Section String Table
	sys_read EMPTY, shdr, ELF32_Shdr_size	
; Read (without seeking) all the names of the sections
;	sys_pread EMPTY, shstring, [shdr.sh_size], [shdr.sh_offset]
	sys_lseek EMPTY, [shdr.sh_offset], SEEK_SET
	sys_read EMPTY, shstring, [shdr.sh_size]
; Seek to the beginning of the SHT
	sys_lseek [fhandle], [ehdr.e_shoff], SEEK_SET
	xor ecx, ecx
.describeSHT:
	push ecx
	sys_read [fhandle], shdr, ELF32_Shdr_size
	pop ecx
	call describeSHT
	inc ecx
	cmp cx, word [ehdr.e_shnum]	;have we described all the sections?
	jne .describeSHT
	ret

; ----------------------------------------------------------------------------
;             ---[ Make all the entries in the SHT readable ]---
; ############################################################################
describeSHT:
	pushad
	mov edi, SHTLine+3	;put the section number
	cmp cl, 9
	ja .sectokay
	inc edi
.sectokay:
	Nr2ASCII ecx, DEC, EMPTY, length
	
	xor eax, eax
	mov edi, SHTLine+6
	mov al, ' '
	mov ecx, 80-6
	rep stosb		;clean the line for impurities :)

; -------------- sh_name --------------
	mov eax, shstring
	add eax, [shdr.sh_name]	;point to the name of the current section

	mov esi, eax
	mov edi, SHTLine+7
.namecopy:
	lodsb			;char in AL
	stosb			;and store it in EDI
	test al, al		;end of string?
	jnz .namecopy

	mov al, ' '
	dec edi
	stosb

; -------------- sh_type --------------	
	push ebp
	xor ebp, ebp
	mov eax, [shdr.sh_type]
.TYPEcheck:
	cmp eax, [ebp+TYPEstrings]
	jne .TYPErecheck

	mov esi, TYPEstrings+4	;copy from TYPEstring to SHTLine
	add esi, ebp
	mov ecx, TYPElen
	mov edi, SHTLine+25	;put the section type
	rep movsb
	jmps .shaddr
.TYPErecheck:
	add ebp, TYPElen+4	;=21 bytes (4=sh_type, 17=length of string)
	cmp ebp, TYPEstringslen ;21*20
	jne .TYPEcheck

; -------------- sh_addr --------------
.shaddr:
	pop ebp
	mov eax, [shdr.sh_addr]
	mov ebx, 8
	mov edi, SHTLine+41
	call addZeros

; -------------- sh_offset --------------
	mov eax, [shdr.sh_offset]
	mov ebx, 6
	mov edi, SHTLine+50
	call addZeros

; -------------- sh_size --------------
	mov eax, [shdr.sh_size]
	mov edi, SHTLine+57
	call addZeros

; -------------- sh_entsize --------------
	mov edi, SHTLine+64
	mov eax, [shdr.sh_entsize]
	cmp al, 15
	ja .entokay
	mov [edi], byte '0'
	inc edi
.entokay:
	Nr2ASCII EMPTY, HEXA, EMPTY, length

; -------------- sh_flags --------------
	mov edi, SHTLine+67
	mov eax, [shdr.sh_flags]
	test eax, SHF_WRITE 
	jz .alloc
	mov [edi], byte 'W'
.alloc:
	inc edi
	test eax, SHF_ALLOC
	jz .exec
	mov [edi], byte 'A'
.exec:
	inc edi
	test eax, SHF_EXECINSTR
	jz .shlink
	mov [edi], byte 'X'

; -------------- sh_link --------------
.shlink:
	mov edi, SHTLine+71
	mov eax, [shdr.sh_link]
	cmp al, 9
	ja .linkokay
	inc edi
.linkokay:
	Nr2ASCII EMPTY, DEC, EMPTY, length	
	
; -------------- sh_info --------------
	mov edi, SHTLine+75
	mov eax, [shdr.sh_info]
	cmp al, 15
	ja .infookay
	inc edi
.infookay:
	Nr2ASCII EMPTY, HEXA, EMPTY, length

; -------------- sh_addralign--------------
	Nr2ASCII [shdr.sh_addralign], DEC, SHTLine+78, length

	sys_write STDOUT, SHTLine, 81
	popad
	ret


; ----------------------------------------------------------------------------
;                        Describe the ELF Header
; ############################################################################
describeheader:
	pushad
        sys_write EMPTY, elfmsg, elflen		;write the "ELF Header:" string
;---> Display the magic numbers <---
;-----------------------------------
	;write the "Magic:" string
	sys_write EMPTY, Magicmsg, Magiclen

	push ebp
	xor ebp, ebp
.magicloop:
	xor eax, eax		;clear EAX
	mov edi, Buf
	mov al, byte [ehdr.e_ident+ebp]	;get each value from e_ident
	cmp al, 9
	ja .magicok
	mov byte [Buf], '0'	;add a '0' in front of the nrs < 9
	inc edi			;get to the 2nd position in buffer
.magicok:
	Nr2ASCII EMPTY, HEXA, EMPTY, length	;convert it to a number
	mov byte [Buf+2], ' '		;add a space
	sys_write EMPTY, Buf, length

	inc ebp			;get next value
	cmp ebp, byte EI_NIDENT	;end of the magic numbers?
	jne .magicloop
	pop ebp

	sys_write EMPTY, newl, 1

;---> Display the file's CLASS <---
;----------------------------------
	;write the "Class:" string
	sys_write EMPTY, CLASSmsg, CLASSlen

	xor eax, eax
	mov al, byte [ehdr.e_ident+4]	;get the file's class or capacity

	cmp al, ELFCLASS32	;32-bit object?
	je .class32
	cmp al, ELFCLASS64	;64-bit object?
	je .class64

	Nr2ASCII EMPTY, HEXA, Classunknown+2, length
	mov ecx, Classunknown
	mov edx, Classunknownlen
	jmps .classwrite
.class32:
	mov ecx, Class32msg
	mov edx, Class32len
	jmps .classwrite
.class64:
	mov ecx, Class64msg
	mov edx, Class64len
.classwrite:
	sys_write EMPTY

;---> Display the data encoding <---
;-----------------------------------
	;write the "Data:" string
	sys_write EMPTY, DATAmsg, DATAlen

	xor eax, eax
	mov al, byte [ehdr.e_ident+5]	;data encoding of the cpu-specific data
					; in the object file
	cmp al, ELFDATA2LSB	;lsb?
	je .dataLSB
	cmp al, ELFDATA2MSB	;msb?
	je .dataMSB

	Nr2ASCII EMPTY, HEXA, Dataunk+2, length
	mov ecx, Dataunk
	mov edx, Datalen
	jmps .datawrite
.dataLSB:
	mov ecx, dataLSBmsg
	mov edx, dataLSBlen
	jmps .datawrite
.dataMSB:
	mov ecx, dataMSBmsg
	mov edx, dataMSBlen
.datawrite:
	sys_write EMPTY
	
;---> Display File IDentification <---
;-------------------------------------
	;write the "Type:" string
	sys_write EMPTY, IDmsg, IDlen

	xor eax, eax		;clear EAX
	mov ax, word [ehdr.e_type]	;file identification

	push ebp
	xor ebp, ebp
.IDcheck:
	cmp ax, word [ebp+IDstrings]	;check if the ID is in our table
	jne .IDrecheck

	mov ecx, IDstrings+2	;get the address of the string in ECX
	add ecx, ebp		
	mov edx, IDstrlen	;length of string
	jmp .IDwrite
.IDrecheck:
	add ebp, IDstrlen+2	;=33 bytes (+2=e_type,+31=length of string)
	cmp ebp, IDstringslen	;33*7
	jne .IDcheck

	cmp ax, ET_LOPROC
	jb .IDunk
	cmp ax, ET_HIPROC
	ja .IDunk

	Nr2ASCII EMPTY, HEXA, IDproc+2, length
	mov ecx, IDproc		;must be processor-specific then 
	mov edx, IDproclen
	jmps .IDwrite	
.IDunk:
	Nr2ASCII EMPTY, HEXA, IDunknown+2, length
	mov ecx, IDunknown	;unknown object file type
	mov edx, IDunknownlen
.IDwrite:
	pop ebp
	sys_write EMPTY

;---> Display the required ARCHitecture <---
;-------------------------------------------
	;write the "Machine:" string
	sys_write EMPTY, ARCHmsg, ARCHlen

	xor eax, eax		;clear EAX
	mov ax, word [ehdr.e_machine]	;file architecture
	
	push ebp
	xor ebp, ebp
.ARCHcheck:
	cmp ax, word [ebp+ARCHstrings]	;check the architecture of the file
	jne .ARCHrecheck

	mov ecx, ARCHstrings+2	;get the address of the string in ECX
	add ecx, ebp
	mov edx, ARCHstrlen	;length of string
	jmp .ARCHwrite
.ARCHrecheck:
	add ebp, ARCHstrlen+2	;=32 bytes (2=e_machine,30=length of string)
	cmp ebp, ARCHstringslen	;32*18
	jne .ARCHcheck

	Nr2ASCII EMPTY, HEXA, ARCHunknown+2, length
	mov ecx, ARCHunknown	;unknown machine architecture
	mov edx, ARCHunknownlen
.ARCHwrite:
	pop ebp
	sys_write EMPTY

;---> Display the object file version <---
;-----------------------------------------
	;write the "Version:" string
	sys_write EMPTY, VERmsg, VERlen

	mov eax, [ehdr.e_version]	;file architecture

	cmp eax, byte EV_NONE
	je .VERinval
	cmp eax, byte EV_CURRENT
	je .VERcurr

	Nr2ASCII EMPTY, HEXA, VERunknown+2, length
	mov ecx, VERunknown
	mov edx, VERunknownlen
	jmps .VERwrite
.VERinval:
	mov ecx, VERinvalid
	mov edx, VERinvalidlen
	jmps .VERwrite
.VERcurr:
	mov ecx, VERcurrent
	mov edx, VERcurrentlen
.VERwrite:
	sys_write EMPTY

;---> Display the entry point address <---
;-----------------------------------------
	;write the "Entry point address:" string
	sys_write EMPTY, ENTRYmsg, ENTRYlen

;virtual address to which the system transfers control, thus starting process
	Nr2ASCII [ehdr.e_entry], HEXA, ENTRYunk+2, length
	sys_write EMPTY, ENTRYunk, ENTRYunklen

;---> Display the PHT (program header table) offset <---
;-------------------------------------------------------
	;write the "Start of program headers:" string
	sys_write EMPTY, PHTmsg, PHTlen

	call Cleanbuffer
	Nr2ASCII [ehdr.e_phoff], DEC, Buf, length	;PHT's file offset
	call PHTSHTwrite
	
;---> Display the SHT (section header table) offset <---
;-------------------------------------------------------
	;write the "Start of section headers:" string
	sys_write EMPTY, SHTmsg, SHTlen

	call Cleanbuffer
	Nr2ASCII [ehdr.e_shoff], DEC, Buf, length	;SHT's file offset
	call PHTSHTwrite

;---> Display the processor-specific flags <---
;----------------------------------------------
	;write the "Flags:" string
	sys_write EMPTY, FLAGSmsg, FLAGSlen

	call Cleanbuffer
	Nr2ASCII [ehdr.e_flags], HEXA, Buf, length	;cpu-specific flags
	mov byte [Buf+11], lf

	sys_write EMPTY, Buf, length

;---> Display the ELF header size <--- 
;-------------------------------------
	;write the "Size of this header:" string
	sys_write EMPTY, ELFmsg, ELFlen
	
	xor eax, eax
	mov ax, word [ehdr.e_ehsize]	;ELF header's size in bytes
	call Cleanbuffer
	Nr2ASCII EMPTY, DEC, Buf, length
	call Sizewrite

;---> Display the size in bytes of one entry in the PHT <---
;-----------------------------------------------------------
	;write the "Size of program headers:" string
	sys_write EMPTY, PHTSizemsg, PHTSizelen

	xor eax, eax
	mov ax, word [ehdr.e_phentsize]	;size of an entry in the PHT
	call Cleanbuffer
	Nr2ASCII EMPTY, DEC, Buf, length
	call Sizewrite

;---> Display the number of entries in the PHT <---
;--------------------------------------------------
	;write the "Number of program headers:" string
	sys_write EMPTY, PHTentrymsg, PHTentrylen
	
	xor eax, eax
	mov ax, word [ehdr.e_phnum]	;number of entries in PHT
	call Cleanbuffer
	Nr2ASCII EMPTY, DEC, Buf, length
	mov byte [Buf+11], lf

	sys_write EMPTY, Buf, length

;---> Display the size in bytes of one entry in the SHT <---
;-----------------------------------------------------------
	;write "Size of section headers:" string
	sys_write EMPTY, SHTSizemsg, SHTSizelen	

	xor eax, eax
	mov ax, word [ehdr.e_shentsize]	;size of an entry in SHT
	call Cleanbuffer
	Nr2ASCII EMPTY, DEC, Buf, length
	call Sizewrite

;---> Display the number of entries in the SHT <---
;--------------------------------------------------
	;write "Number of section headers:" string
	sys_write EMPTY, SHTentrymsg, SHTentrylen

	xor eax, eax
	mov ax, word [ehdr.e_shnum]	;number of entries in SHT
	call Cleanbuffer
	Nr2ASCII EMPTY, DEC, Buf, length
	mov byte [Buf+11], lf
	
	sys_write EMPTY, Buf, length

;---> Display the SHT index <---
;-------------------------------
	;write "Section header string table index:" string
	sys_write EMPTY, SHTindexmsg, SHTindexlen

	xor eax, eax
	mov ax, word [ehdr.e_shstrndx]	;SHT index of the entry associated
					;with the section name string table
	call Cleanbuffer
	Nr2ASCII EMPTY, DEC, Buf, length
	mov byte [Buf+11], lf

	sys_write EMPTY, Buf, length
	popad
	ret

PHTSHTwrite:
; Expects EBX = STDOUT
	sys_write EMPTY, Buf, length
	sys_write EMPTY, Bytes, Byteslen ;write the "(bytes into file)" string
	ret

Sizewrite:
; Expects EBX = STDOUT
	sys_write EMPTY, Buf, length
	sys_write EMPTY, BytesS, BytesSlen	;write the "(bytes)" string
	ret

Cleanbuffer:
	pushad
	mov edi, Buf		;point to our buffer
	xor eax, eax		;fill the buffer with 0 values
	mov ecx, Buflen		;size of buffer
	rep stosb
	popad
	ret


NumberToString:
; -< mainly used by Nr2ASCII >-
; Expects:
;	EAX = number to convert
;	ECX = type of conversion (10 = Decimal / 16 = Hexadecimal)
;	EDI = address of string
; Returns:
;	ESI = address of a variable that will contain the length of the string
	xor ebx, ebx
.divide:
	xor edx, edx		;clear the reminder
	div ecx			;divide the number by ECX
	cmp dl, 10		;decimal number?
	jb .decimal
	add dl, 'A'-10		;hexadecimal number (A..F)
	jmps .continue
.decimal:
	add dl, '0'		;change from number to ASCII character
.continue:
	push edx		;save the converted number on stack
	inc ebx			;length=length+1
	test eax, eax		;reminder = 0?
	jnz .divide
	mov esi, ebx		;put the string length in [ESI]
.store:
	pop eax			;get the converted number (ASCII) from stack
	stosb			;save it in our buffer (EDI)
	dec ebx			;length=length-1
	test ebx, ebx		;are we done?
	jnz .store
	ret

addZeros:
; Expects:
;	EAX = number to add '0's in front
;	EBX = how many '0's to add
;	EDI = address of an ASCII string
; Returns:
;	buffer at EDI gets filled up with the number (and the 0's)

	pushad
	Nr2ASCII EMPTY, HEXA, EMPTY, length
	cmp byte [length], 8
	jae .addZexit

	xchg ebx, ecx
	sub ecx, [length]	;how many zeros to put
;	int 3
;	nop
	or ecx,ecx
	jz .not_dead
	pushad
	mov al, '0'
.addZ:
	stosb
	loop .addZ
	popad
.not_dead:
	add edi, ecx
 	Nr2ASCII EMPTY, HEXA, EMPTY, length
.addZexit:
	popad
	ret

IDstrings:
	dw 0
IDstr:
	db 'ET_NONE (No file type)        ',lf
	dw 1
	db 'ET_REL (Relocatable file)     ',lf
	dw 2
	db 'ET_EXEC (Executable file)     ',lf
	dw 3
	db 'ET_DYN (Shared object file)   ',lf
	dw 4
	db 'ET_CORE (Core file)           ',lf
	dw 0xff00
	db 'ET_LOPROC (Processor-specific)',lf
	dw 0xffff
	db 'ET_HIPROC (Processor-specific)',lf
IDstringslen	equ $-IDstrings

ARCHstrings:
	dw 0
ARCHstr:
	db 'EM_NONE (No machine)         ',lf
	dw 1
	db 'EM_M32 (AT&T WE 32100)       ',lf
	dw 2
	db 'EM_SPARC (SPARC)             ',lf
	dw 3
	db 'EM_386 (Intel 80386)         ',lf
	dw 4
	db 'EM_68K (Motorola 68000)      ',lf
	dw 5
	db 'EM_88K (Motorola 88000)      ',lf
	dw 6
	db 'EM_486 (DISUSED!)            ',lf
	dw 7
	db 'EM_860 (Intel 80860)         ',lf
	dw 8
	db 'EM_MIPS (MIPS R3000)         ',lf
	dw 10
	db 'EM_MIPS_RS4_BE (MIPS R4000)  ',lf
	dw 15
	db 'EM_PARISC (HPPA)             ',lf
	dw 18
	db 'EM_SPARC32PLUS (Suns v8plus) ',lf
	dw 20
	db 'EM_PPC (PowerPC)             ',lf
	dw 42
	db 'EM_SH (SuperH)               ',lf
	dw 43
	db 'EM_SPARCV9 (SPARC v9 64-bit) ',lf
	dw 50
	db 'EM_IA_64 (HP/Intel IA-64)    ',lf
	dw 0x9026
	db 'EM_ALPHA (interim value!)    ',lf
	dw 0xA390
	db 'EM_S390 (interim value!)     ',lf
ARCHstringslen equ $-ARCHstrings

Bytes		db ' (bytes into file)',lf
BytesS		db ' (bytes)',lf
Magicmsg	db '  Magic:   '
CLASSmsg	db '  Class:                             '
Class32msg	db 'ELFCLASS32 (32-bit object)',lf
Class64msg	db 'ELFCLASS64 (64-bit object)',lf
DATAmsg		db '  Data:                              '
dataLSBmsg	db 'ELFDATA2LSB (2 complement, little endian)',lf
dataMSBmsg	db 'ELFDATA2MSB (2 complement, big endian)',lf
IDmsg		db '  Type:                              '
ARCHmsg 	db '  Machine:                           '	
VERmsg		db '  Version:                           '
VERcurrent 	db 'EV_CURRENT (Current version)',lf
VERinvalid	db 'EV_NONE (Invalid version)',lf
ENTRYmsg	db '  Entry point address:               '
PHTmsg		db '  Start of program headers:          '
SHTmsg		db '  Start of section headers:          '
FLAGSmsg	db '  Flags:                             0x'
ELFmsg		db '  Size of this header:               '
PHTSizemsg	db '  Size of program headers:           '
PHTentrymsg	db '  Number of program headers:         '
SHTSizemsg	db '  Size of section headers:           '
SHTentrymsg	db '  Number of section headers:         '
SHTindexmsg	db '  Section header string table index: '
newl		db lf

TYPEstrings:
	dd 0
TYPEstr:
	db 'SHT_NULL         '
TYPElen equ $-TYPEstr
	dd 1
	db 'SHT_PROGBITS     '
	dd 2
	db 'SHT_SYMTAB       '
	dd 3
	db 'SHT_STRTAB       '
	dd 4
	db 'SHT_RELA         '
	dd 5
	db 'SHT_HASH         '
	dd 6
	db 'SHT_DYNAMIC      '
	dd 7
	db 'SHT_NOTE         '
	dd 8
	db 'SHT_NOBITS       '
	dd 9
	db 'SHT_REL          '
	dd 10
	db 'SHT_SHLIB        '
	dd 11
	db 'SHT_DYNSYM       '
	dd 0x70000000
	db 'SHT_LOPROC       '
	dd 0x7fffffff
	db 'SHT_HIPROC       '
	dd 0x80000000
	db 'SHT_LOUSER       '
	dd 0xffffffff
	db 'SHT_HIUSER       '
	dd 0x70000000
	db 'SHT_MIPS_LIST    '
	dd 0x70000002
	db 'SHT_MIPS_CONFLICT'
	dd 0x70000003
	db 'SHT_MIPS_GPTAB   '
	dd 0x70000004
	db 'SHT_MIPS_UCODE   '
TYPEstringslen equ $-TYPEstrings

PTYPEstrings:
	dd 0
PTYPEstr:
	db 'PT_NULL        '
PTYPElen equ $-PTYPEstr
	dd 1
	db 'PT_LOAD        '
	dd 2
	db 'PT_DYNAMIC     '
	dd 3
	db 'PT_INTERP      '
	dd 4
	db 'PT_NOTE        '
	dd 5
	db 'PT_SHLIB       '
	dd 6
	db 'PT_PHDR        '
	dd 0x70000000
 	db 'PT_LOPROC      '
	dd 0x7fffffff
	db 'PT_HIPROC      '
	dd 0x70000000
	db 'PT_MIPS_REGINFO'
PTYPEstringslen equ $-PTYPEstrings

DATASEG
Header		db 0
Sect		db 0
Segm		db 0
fhandle		db 1


Classunknown	db '0x   (Unknown or invalid file class)',lf
Dataunk		db '0x   (Unknown or invalid data encoding)',lf
IDunknown	db '0x     (Unknown object file type)',lf
IDproc		db '0x     (Processor-specific)',lf
ARCHunknown	db '0x     (Unknown architecture)',lf
VERunknown	db '0x     (Unknown version)',lf
ENTRYunk	db '0x          ',lf
sectionstr	db '  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al',lf
SHTLine		db '  [  ]                                                                          ',lf
segmentstr	db '  Type           Offset   VirtAddr   PhysAddr   FileSiz MemSiz  Flg Align       ',lf
SHTnumber	db lf,'There are    section headers, starting at offset 0x     '
PHTnumber	db lf,'There are    program headers, starting at offset      '


UDATASEG
ehdr I_STRUC ELF32_Ehdr	;define our temporary buffer for the ELF Header
	.e_ident 	resb EI_NIDENT
	.e_type		Elf32_Half	;resw 1
	.e_machine	Elf32_Half	;resw 1
	.e_version	Elf32_Word	;resd 1
	.e_entry	Elf32_Addr	;resd 1
	.e_phoff	Elf32_Off	;resd 1
	.e_shoff	Elf32_Off	;resd 1
	.e_flags	Elf32_Word	;resd 1
	.e_ehsize	Elf32_Half	;resw 1
	.e_phentsize	Elf32_Half	;resw 1
	.e_phnum	Elf32_Half	;resw 1
	.e_shentsize	Elf32_Half	;resw 1
	.e_shnum	Elf32_Half	;resw 1
	.e_shstrndx	Elf32_Half	;resw 1
I_END

shdr I_STRUC ELF32_Shdr	;define our temp buffer for the Section Header
	.sh_name	Elf32_Word	;resd 1
	.sh_type	Elf32_Word	;resd 1
	.sh_flags	Elf32_Word	;resd 1
	.sh_addr	Elf32_Addr	;resd 1
	.sh_offset	Elf32_Off	;resd 1
	.sh_size	Elf32_Word	;resd 1
	.sh_link	Elf32_Word	;resd 1
	.sh_info	Elf32_Word	;resd 1
	.sh_addralign	Elf32_Word	;resd 1
	.sh_entsize	Elf32_Word	;resd 1
I_END

phdr I_STRUC ELF32_Phdr
	.p_type		Elf32_Word	;resd 1
	.p_offset	Elf32_Off	;resd 1
	.p_vaddr	Elf32_Addr	;resd 1
	.p_paddr	Elf32_Addr	;resd 1
	.p_filesz	Elf32_Word	;resd 1
	.p_memsz	Elf32_Word	;resd 1
	.p_flags	Elf32_Word	;resd 1
	.p_align	Elf32_Word	;resd 1
I_END
PHTLine		resb 81
shstring	resb 1024	;all the names of the sections... pretty big :(

Buf		resb 11
Buflen		equ $-Buf
length		resb 1

END

