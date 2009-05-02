;Copyright (C) 2001 Rudolf Marek <marekr2@fel.cvut.cz>, <ruik@atlas.cz>
;
;$Id: tar.asm,v 1.7 2003/05/13 16:01:42 konst Exp $
;
;hackers' tar
;
;Syntax tar [OPT] FILENAME
;OPT:	-t list archive
;	-x extracet archive
;	-c create archive
;Note: no time/date update yet
;
;If TAR_SECURE is defined, make tar suid-root to enable protection
;against malitious tarballs (works by chroot ".").

;All comments/feedback welcome.

;0.1	25-Sep-2001	initial release (RM)
;0.2	04-Aug-2002	added contiguous (append) files, chown/grp,
;			prefix processing,  "tar -xf -" for stdin,
;			selection of only certain filenames for "tar -x" (JH)
;0.3	02-Sep-2002	fixed bugs in TAR_CHOWN, octal_to_int, empty file
;			initial archive creation code: only self compat for now
;0.4			???
;0.5	04-Oct-2002	Fixed pipe bug in 2.0, TAR_SUID (JH)
;0.6	05-Dec-2002	Fixed a bug involving symlinks to SUID files
;0.7	26-Apr-2003	Code cleanup, Created archives can be read by GNUTAR
;			Also, some security fixes (JH)


%include "system.inc"

;------ Build configuration
;%define TAR_CONTIG
%define TAR_PREFIX
%define TAR_MATCH
%define TAR_CREATE
%define TAR_CHOWN
%define TAR_SECURE

;A tar archive consists of 512-byte blocks.
;  Each file in the archive has a header block followed by 0+ data blocks.
;   Two blocks of NUL bytes indicate the end of the archive.  */
;
; The fields of header blocks:
;   All strings are stored as ISO 646 (approximately ASCII) strings.
;
;  Fields are numeric unless otherwise noted below; numbers are ISO 646
;   representations of octal numbers, with leading zeros as needed.
;
;  linkname is only valid when typeflag==LNKTYPE.  It doesn't use prefix;
;   files that are links to pathnames >100 chars long can not be stored
;  in a tar archive.
;
;   If typeflag=={LNKTYPE,SYMTYPE,DIRTYPE} then size must be 0.
;
;   devmajor and devminor are only valid for typeflag=={BLKTYPE,CHRTYPE}.
;
;   chksum contains the sum of all 512 bytes in the header block,
;   treating each byte as an 8-bit unsigned value and treating the
;   8 bytes of chksum as blank characters.

;  uname and gname are used in preference to uid and gid, if those
;   names exist locally.

;   Field Name	Byte Offset	Length in Bytes	Field Type
;   name	0		100		NUL-terminated if NUL fits
;   mode	100		8
;   uid		108		8
;   gid		116		8
;   size	124		12
;   mtime	136		12
;   chksum	148		8
;   typeflag	156		1		see below
;   linkname	157		100		NUL-terminated if NUL fits
;   magic	257		6		must be TMAGIC (NUL term.)
;   version	263		2		must be TVERSION
;   uname	265		32		NUL-terminated
;   gname	297		32		NUL-terminated
;   devmajor	329		8
;   devminor	337		8
;   prefix	345		155		NUL-terminated if NUL fits

;   If the first character of prefix is '\0', the file name is name;
;   otherwise, it is prefix/name.  Files whose pathnames don't fit in that
;  length can not be stored in a tar archive.  */

;/* The bits in mode: */
%assign TSUID	04000q
%assign TSGID	02000q
%assign TSVTX	01000q
%assign TUREAD	00400q
%assign TUWRITE	00200q
%assign TUEXEC	00100q
%assign TGREAD	00040q
%assign TGWRITE	00020q
%assign TGEXEC	00010q
%assign TOREAD	00004q
%assign TOWRITE	00002q
%assign TOEXEC	00001q

;/* The values for typeflag:
;   Values 'A'-'Z' are reserved for custom implementations.
;   All other values are reserved for future POSIX.1 revisions.  */

%assign REGTYPE		'0'	;/* Regular file (preferred code).  */
%assign AREGTYPE	0	;/* Regular file (alternate code).  */
%assign LNKTYPE		'1'	;/* Hard link.  */
%assign SYMTYPE		'2'	;/* Symbolic link (hard if not supported).  */
%assign CHRTYPE		'3'	;/* Character special.  */
%assign BLKTYPE		'4'	;/* Block special.  */
%assign DIRTYPE		'5'	;/* Directory.  */
%assign FIFOTYPE	'6'	;/* Named pipe.  */
%assign CONTTYPE	'7'	;/* Contiguous file */

; /* (regular file if not supported).  */
;
;/* Contents of magic field and its length.  */
%define TMAGIC	'ustar'
%assign TMAGLEN	6

;/* Contents of the version field and its length.  */
%define TVERSION	" ",0
%assign TVERSLEN	2

%assign BUFF_DIV  011q
%assign BUFF_SIZE 2<<(BUFF_DIV-1)

%ifdef TAR_PREFIX
 %define FILENAME tarname
%else
 %define FILENAME tar.name
%endif

direntbufsize	equ	1024		; Reduce to use less RAM
					; I need tar in a 200K
					; free RAM situation.
CODESEG

START:
%ifdef TAR_SECURE
	sys_getuid		; Abandon ROOT privliges
	xchg	eax, ecx
	xor	ebx, ebx	; ruid = ROOT, euid = normal_UID
	mov	[normal_uid], ebx
	sys_setreuid
%endif
	pop     ebx
	pop	ebx
	pop 	ebx
	or 	ebx,ebx
	jz .usage
	cmp 	word [ebx],'-t'
	jz .list_archive
	cmp 	word [ebx],'-x'
	jz .extract_archive
%ifdef TAR_CREATE
	cmp	word [ebx],'-c'
	jz near create_archive
%endif
.usage:
	sys_write STDOUT,use,use_len
	sys_exit 0	

.list_archive:
	pop 	ebx
	call tar_archive_open
	call tar_list_files
	call tar_archive_close
	xor  	ebx,ebx
	jmps dexit
.extract_archive:
	pop 	ebx
	call tar_archive_open
%ifdef TAR_SECURE		; Chroot to . so that /etc/passwd is not
	sys_setuid	0	; dangerous.
	sys_chroot	path_dot
	sys_setuid	[normal_uid]
%endif
%ifdef TAR_MATCH
	mov	[tar_match], esp
%endif
	call tar_archive_extract
	push 	ebx
	call tar_archive_close
	pop 	ebx
dexit:
	sys_exit EMPTY

;*************************************************
;SUBS:
;*************************************************

octal_to_int:             ;stolen from chmod.asm
	push   	esi
	;mov    	edi,esi
	;add 	edi,012
	xor 	ecx,ecx
	xor 	eax,eax
	_mov	ebx,8         ;esi ptr to str
.next:
	mov	cl,[esi]
	or	cl,cl
	jz	.done_ok
	cmp 	cl,' '
	jz	.add
	sub	cl,'0'
	jb	.done_err
	cmp	cl,7
	ja	.done_err
	mul	ebx
	add	eax,ecx
.add:
	inc	esi
	cmp 	esi,edi
	jb 	.next
	jmps	.done_ok
.done_err:
	sys_exit 253
.done_ok:
	pop 	esi
	ret	

convert_size:		; Convert octal numbers in header to dwords
	mov 	esi, tar.size
	lea	edi, [esi + 12]
	call 	octal_to_int
	mov 	dword [esi],eax
	jmps 	convert_numbers
convert_block:
	mov 	esi, tar.devmajor
	lea	edi, [esi + 8]
	call 	octal_to_int
	mov 	dword [esi],eax
	mov	esi, edi
	lea	edi, [esi + 8]
	call 	octal_to_int
	mov 	dword [esi],eax
convert_numbers:
	mov 	esi, tar.mode
	lea	edi, [esi + 8]
	call 	octal_to_int
%ifndef TAR_CHOWN
	and	eax, 0777q	; If not chowning, clear suid bits to prevent
%endif				; a security error (unintentional suid-root)
	mov 	dword [esi],eax
	;lea 	esi,[tar.uid]
	mov	esi, edi
	lea	edi, [esi + 8]
	call 	octal_to_int
	mov 	dword [esi],eax
	;lea 	esi,[tar.gid]
	mov	esi, edi
	lea	edi, [esi + 8]
	call 	octal_to_int
	mov 	dword [esi],eax
	ret

%ifdef TAR_PREFIX
pref_tran:	; This routine copies the prefix and the name to a buffer
	pusha
	mov	edi, FILENAME
	mov	esi, tar.prefix
	xor	ecx, ecx
	mov	cl, 0156		; Stop one byte AFTER end of prefix
.prefc:	lodsb
	stosb
	or	al, al
	loopnz	.prefc
	dec	edi
	mov	esi, tar.name
	mov	cl, 100
.main:	lodsb
	stosb
	or	al, al
	loopnz	.main
	mov	al, 0
	stosb
	popa
	ret
%endif

;*************************
tar_list_files:
.next:
	sys_read [tar_handle],tar,0512
	or 	eax,eax
	jz 	.list_done
	cmp 	dword [tar.magic],'usta'
	jnz 	.next
%ifdef TAR_PREFIX
	call	pref_tran
%endif
	xor 	edx,edx
	mov 	ecx, FILENAME
.next_byte:
	cmp 	byte [ecx+edx],1
	inc 	edx
	jnc 	.next_byte
	mov 	word [ecx+edx-1],0x000a
	sys_write STDOUT,EMPTY,EMPTY
	mov 	edi, tar.typeflag
	cmp byte [edi],SYMTYPE
	jz .prnlink
	cmp byte [edi],LNKTYPE
	jz .prnlink
	jmps 	.next
.prnlink:
	sys_write EMPTY,arrow,5
	xor 	edx,edx
	mov 	ecx,tar.linkname
	mov  byte [edi],0
	jmps .next_byte	
.list_done:
  ret

tar_archive_open:
	xor	eax, eax
	cmp	[ebx], word '-'
	je	.ok
	sys_open EMPTY,O_RDONLY
	test 	eax,eax
	jns 	.ok
	sys_exit 255
.ok:
	mov 	[tar_handle],eax
	ret
tar_archive_close:
	sys_close [tar_handle]
	ret

tar_archive_extract:
.read_next:
	xor	edx, edx
	mov	dh, 2
	mov	ecx, tar
	mov	ebx, [tar_handle]
.read_next2:
	sys_read [tar_handle]
	or	eax, eax
	jna	near	.error_read
	add	ecx, eax
	sub	edx, eax
	ja	.read_next2
	;sys_write STDOUT, tar.name, 0100
	xor 	eax,eax
	cmp 	byte [tar.version],' '
	jz 	.ver_ok
	xor 	ebx,ebx
	ret
.ver_ok:
	cmp 	dword [tar.magic],'usta'
	jnz	near	.error_magic
%ifdef TAR_PREFIX
	call	pref_tran
%else
	cmp	byte [tar.prefix],0
	jz 	.ok
	int 3 ;we dont handle the prefix extension yet
.ok:
%endif
%ifdef TAR_MATCH
	mov	ebp, [tar_match]
	mov	edi, [ebp]
	or	edi, edi
	jz	.gotmatch
.trynext:
	mov	esi, FILENAME
	mov	edi, [ebp]
	or	edi, edi
	jz	.notmatch
	add	ebp, byte 4
.scmp:	lodsb
	mov	cl, [edi]
	inc	edi
	cmp	al, cl
	jnz	.notmatch
	or	al, cl
	jnz	.scmp
.gotmatch:
%endif
	xor 	eax,eax
	mov 	al,[tar.typeflag]
	or 	al,al
	jz 	.done_sel
	cmp 	al,CONTTYPE
	ja  	.error
	sub 	al,'0'
	jb  	.error
.done_sel:
	call [.lookup_table+eax*4]
	test 	eax,eax
	xchg 	eax,ebx
	js   	.error
%ifdef TAR_CHOWN
	sys_lchown FILENAME,[tar.uid],[tar.gid]
	cmp	[tar.typeflag], byte '2'
	je	.skipchmod
	sys_chmod	FILENAME, [tar.mode]
.skipchmod:
%endif
	jmp	.read_next	
.error_magic:
	;* UNUSED. lea 	eax,[0xDEADDEAD]
.error:
	neg 	ebx
.exit:
	ret

%ifdef TAR_MATCH
.notmatch:
	call	convert_size
	mov	ebp,	[tar.size]
	add	ebp,	511
	shr	ebp,	BUFF_DIV
	jz	.rd
	mov	ebx,	[tar_handle]
	mov	ecx,	buffer
	_mov	edx,	512
.readj	sys_read		; [tar_handle], buffer, 512
	dec	ebp
	jnz	.readj
.rd	jmp	.read_next
%endif

.create_contigous:
%ifdef TAR_CONTIG
	call convert_size
	sys_open FILENAME, O_CREAT|O_APPEND|O_WRONLY,[tar.mode]
	jmp	.crc		; Reenter create file code!
%else
	int 3		; Disabled
%endif
.create_dir:
	call convert_numbers
	sys_mkdir FILENAME,[tar.mode]
	xor eax,eax ;always OK
	ret

.create_hardlink:
	call convert_numbers
	sys_link tar.linkname,tar.name
	ret
.create_symlink:
	call convert_numbers
	sys_symlink tar.linkname,tar.name
	ret
.create_fifo:
	call convert_numbers
	mov 	ecx, tar.mode
	or 	dword [ecx],S_IFIFO
	sys_mknod tar.name,[ecx],EMPTY
	ret
.create_char:
	call convert_block
        or dword [tar.mode],S_IFCHR
	jmps .create_nod
.create_block:
	call convert_block
	or dword [tar.mode],S_IFBLK
.create_nod:
	mov	edx,[tar.devmajor]
	shl	edx,8
	mov	dl, [tar.devminor]
	sys_mknod FILENAME,[tar.mode],EMPTY
	ret
.create_file:
	call convert_size
%ifdef TAR_CHOWN		; No race conditions
	sys_open FILENAME, O_CREAT|O_WRONLY|O_TRUNC, 200q
%else
	sys_open FILENAME, O_CREAT|O_WRONLY|O_TRUNC, [tar.mode]
%endif
.crc	test 	eax,eax
	js 	near .error_open
	mov 	[file_handle],eax
	xchg	eax, ebx
	mov	esi, [tar.size]
	mov	ecx, buffer
.read_block:
	xor	edx, edx
	mov	dh, 2
.read_next_block:
	or	esi, esi
	jz	.empty
.reread_block:
	sys_read	[tar_handle]
	or	eax, eax
	jna	.error_read
	add	ecx, eax
	sub	edx, eax
	ja	.reread_block
	xor	edx, edx
	mov	dh, 2
	sub	esi, edx
	js	.lastblock
	sys_write	[file_handle], buffer
	jmps	.read_next_block
.lastblock:
	add	edx, esi
	sys_write	[file_handle], buffer
.empty:
	sys_close EMPTY
.error_open:
	ret

.error_read:
	sys_write	STDERR, .error_read_msg, .lookup_table - .error_read_msg
	sys_exit
.error_read_msg	db	'IO Error', 10

.lookup_table dd .create_file,.create_hardlink,.create_symlink,.create_char
              dd .create_block,.create_dir,.create_fifo,.create_contigous

%ifdef TAR_SECURE
path_dot	db	'.', 0
%endif

%ifdef TAR_CREATE
;************************************************************
; Acceptable version of tar archive creation
; TODO: gather up hard links (any volunteers <g>)
; TODO: fix checksum. It doesn't quite work yet
; TODO: add prefix generation if names are long.
;************************************************************
create_archive:
	pop	ebx
	or	ebx, ebx
	jz	near	dexit
	xor	eax, eax		; Set handle to stdout
	inc	eax			; (1)
	cmp	[ebx], word '-'		; For filename of -
	je	.openarchok
	sys_open	EMPTY, O_WRONLY|O_CREAT|O_TRUNC, 0666q
	or	eax, eax
	js	near	dexit
.openarchok:	
	mov	[tar_handle], eax
	; OK -- file open
	; For each file on command line, add to arch.
	; For each directory on command line, recursively add to arch.
.nextarg:
	pop	esi
	or	esi, esi
	jz	.endlist
	mov	edi, longbuf
	call	.copy
	call	.entry
	jmps	.nextarg

.endlist:
	call	.null_record
	sys_write	[tar_handle], tar, BUFF_SIZE
	sys_write
	call	tar_archive_close
	jmp	dexit

;************** SUBS *****************
.itoa8:		; integer to octal
		; EDI = buffer, EAX = NUM, ECX = SIZE, EDX = GARBAGE
	push	dword 0
	_mov	ebx, 8
	dec	ecx
.i81	xor	edx, edx
	div	ebx
	add	dl, '0'
	push	edx
	loop	.i81
.i82	pop	eax
	stosb
	or	eax, eax	; Null terminated 0ctals
	jnz	.i82
	ret

.null_record:			; Blank out the header
	xor	eax, eax
	xor	ecx, ecx
	mov	cl, 128
	mov	edi, tar
	rep	stosd
	ret

.copy:	lodsb			; Copy strings
	stosb
	or	al, al
	jnz	.copy
.ret1:	ret

;********** Main file creator -- recursive
.entry:		; Everything is created through here.
		; Arguments: longbuf = filename
		; May trash ALL registers
	mov	ebx, longbuf
	sys_lstat	EMPTY, sts
	or	eax, eax
	jnz	.ret1		; Doesn't exist: skip it
	call	.null_record
	mov	edi, tar.mode
	xor	ecx, ecx
	mov	cl, 8		; Buffer for numbers is 7 + null byte
	push	ecx		; +1
	mov	ax, [sts.st_mode]	; AX, not EAX. This took a long time
	;and	eax, 0177777q		; to find.
	call	.itoa8
	mov	ax, [sts.st_uid]	; 16 bit uid
	pop	ecx		; 0
	push	ecx		; +1
	call	.itoa8
	mov	ax, [sts.st_gid]	; 16 bit gid
	pop	ecx		; 0
	call	.itoa8
	mov	eax, [sts.st_mtime]
	mov	cl, 012		; Remember null byte
	add	edi, ecx	; Skip over size for now
	call	.itoa8
	mov	[edi + tar.magic - tar.chksum], dword 'usta'	; ID
	mov	[edi + tar.magic - tar.chksum + 4], dword 'r  '
	mov	esi, longbuf		; now filename into tar arch
	mov	edi, tar.name		; IGNORING PREFIX!!!
	call	.copy			; dangerous
	mov	esi, tar.typeflag
	mov	ax, [sts.st_mode]
	shr	eax, 12			; OK: detect file type
	cmp	al, 10
	je	.symlink
	cmp	al, 8
	je	near	.file
	cmp	al, 6
	je	.block
	cmp	al, 4
	je	near	.dir
	cmp	al, 2
	je	.char
	dec	eax
	jnz	near	.ret2	; ABORT - UNKNOWN TYPE
;.fifo:	
	call	.sizezero	; No size if not a file
	mov	[esi], byte FIFOTYPE
	jmps	.entrydone
.symlink:
	call	.sizezero
	mov	[esi], byte SYMTYPE
	sys_readlink	longbuf, tar.linkname, 0100
	jmps	.entrydone
.block:	mov	[esi], byte BLKTYPE
	jmps	.device
.char:	mov	[esi], byte CHRTYPE
.device:
	call	.sizezero	; Devices have no size
	mov	eax, [sts.st_rdev]
	xor	ebx, ebx	; But rdev needs to be stored.
	mov	bl, al
	;mov	ebx, eax
	;and	ebx, 255	; Might be fixing for other OSes...
	xor	eax, ebx	; Major in hand
	shr	eax, 8
	push	ebx	; +1
	mov	edi, tar.devmajor
	_mov	ecx, 08
	push	ecx	; +2
	call	.itoa8
	pop	ecx	; +1
	pop	eax	; +0	; Minor in hand
	call	.itoa8
.entrydone:			; Common code to complete entry
; Calculate checksum
; No way to tell if it works or not
	xor	eax, eax	; Clear checksum registers
	cdq
	mov	al, ' '		; First wipe checksum field with spaces
	mov	edi, tar.chksum
	push	edi
	_mov	ecx, 8
	rep	stosb
	mov	esi, tar
	_mov	ecx, BUFF_SIZE
.chloop	lodsb
	add	edx, eax	; Add all bytes together
	loop	.chloop
	xchg	eax, edx
	pop	edi
	mov	cl, 7		; Checksum field is six digits, a null
	call	.itoa8		; byte and a space (already present)
; And write it to disk
	sys_write	[tar_handle], tar, BUFF_SIZE
.ret2:	ret

.sizezero:			; Store size where it goes
	xor	eax, eax
.size:	mov	edi, tar.size
	mov	ecx, 011
	call	.itoa8
	ret

.file:	mov	eax, [sts.st_size]	; Write file entry and file
	call	.size
	mov	[esi], byte REGTYPE
	sys_open	longbuf, O_RDONLY
	or	eax, eax
	js	.ret2
	xchg	ebp, eax
	call	.entrydone	; convenient cheat -- write header
	mov	esi, [sts.st_size]
	add	esi, 511		; To end of buffer
	and	esi, ~511		; BUFF_SIZE must be a power of 2
	jz	.nowrite
	mov	edi, [tar_handle]
	_mov	ecx, buffer
.copyloop:
	sys_read	ebp, EMPTY, BUFF_SIZE
	or	eax, eax
	jna	.copydone
	sub	esi, eax
	js	.copyfix	; Fix growing file
	xchg	eax, edx
	sys_write	edi, buffer
	jmps	.copyloop

.copyfix:
	add	esi, eax
	jz	.nowrite
.copydone:
	call	.null_record	; Write nulls to fill to a block
	xchg	esi, edx
	sys_write	[tar_handle], tar
.nowrite:
	sys_close	ebp
.ret3:	ret

;********* Code to descend directories, grabbing everythings ******
.dir:	mov	[esi], byte DIRTYPE
	call	.entrydone	; Write entry record
	; Open directory
	sys_open	longbuf, 0
	xchg	eax, ebx
	or	ebx, ebx
	js	.ret3	;failed: no descend directory
	mov	edi, longbuf
	xor	ecx, ecx
%ifdef __BSD__
	push	ecx
%endif
	mov	eax, ecx
	dec	ecx
	repnz	scasb
	dec	edi		; Points to NULL terminator
	mov	al, '/'		; for holing new files
	stosb
	mov	[edi], byte 0
	push	ebx		; +1
	call	allocdirentry
	pop	ebx		; 0
	push	ecx		; +1
.requestmore:		; Walk thru all directory entries
	pop	ecx		; 0
%ifdef __BSD__
	mov	esi, esp
	sys_getdirentries	EMPTY, EMPTY, direntbufsize, esp
%else
	sys_getdents	EMPTY, EMPTY, direntbufsize
%endif
	or	eax, eax
	jna	.lastentry
	push	ecx		; +1
.scanentry:
%ifdef __BSD__
	cdq		; Shorter version of xor edx, edx
	cmp	[ecx + dirent.d_fileno], edx
	je	.nextentry
%endif
	lea	esi, [ecx + dirent.d_name]
	cmp	[esi], byte 0
	je	.nextentry	; Skip no file
	cmp	[esi], word 0x002E
	je	.nextentry	; Skip .
	cmp	[esi], word 0x2E2E
	jne	.doentry
	cmp	[esi + 2], byte 0
	je	.nextentry	; Skip ..
.doentry:		; Add this entry to the tar archive
	push	eax	; Save count
	push	ebx	; Save file handle
	push	ecx	; Save entry #
	push	edi	; Save longbuf position
	call	.copy
	cmp	edi, longbuf + 0100
	ja	.skipit		; OOPS... need prefix code
	call	.entry	; Recursive
.skipit:
	pop	edi	; restore longbuf
	pop	ecx	; Restore entry #
	pop	ebx	; Restore file handle
	pop	eax	; Restore count
.nextentry:
	movzx	edx, word [ecx + dirent.d_reclen]
;	or	edx, edx
;	jz	.requestmore
	add	ecx, edx
	sub	eax, edx
	jna	.requestmore
	jmps	.scanentry
.lastentry:
	sys_close	; No more entries
%ifdef __BSD__
	pop	eax
%endif
	call	freedirentry
	ret		; Return from directory entry

allocdirentry:		; Get new directory entries, reusing old buffers
			; if possible
	mov	ecx, [lastdirentry]
	or	ecx, ecx
	jz	.nospace
	mov	eax, [ecx]
	mov	[lastdirentry], eax
.af:	xor	ebx, ebx	
	mov	[ecx + direntbufsize], ebx
	add	ecx, 4
	ret
.nospace:
	_mov	ecx, direntbufsize + 4
	call	allocator
	xchg	eax, ecx
	jmps	.af

freedirentry:		; Make unused buffers available.
	sub	ecx, 4
	mov	eax, [lastdirentry]
	mov	[ecx], eax
	mov	[lastdirentry], ecx
	ret

allocator:		; Generic allocator w/o free enabled
	mov	ebx, [.highwater]	; If implementing hard linker,
	add	ebx, ecx		; Be sure to call this to get
	sys_brk				; RAM!
	or	eax, eax
	jna	.nomemory
	mov	eax, [.highwater]
	mov	[.highwater], ebx
	ret

.nomemory:
	sys_write	STDERR, .msg, 7
	mov	bl, 250
	sys_exit
.msg	db	"No RAM", 10

.highwater	dd	udata_end
%endif

;DEBUG:	pusha
;	sys_write	2, .DEBUG, 6
;	popa
;	ret
;.DEBUG	db	'DEBUG', 10

;*********************************************
; Misc. data
use:	db "Usage: tar [OPT] FILENAME",__n
%ifdef TAR_CREATE
	db "		-c create tar archive",__n
%endif	
	db "		-t list tar archive",__n
	db "		-x extract tar arcive",__n
use_len equ $-use
arrow db " |-> "

UDATASEG

tar_handle	resd 1
file_handle	resd 1
%ifdef TAR_SECURE
normal_uid	resd 1
%endif

%ifdef TAR_CREATE
longbuf		resb 256	; If we overrun this, we are dead anyway
sts:
%ifdef __BSD__
B_STRUC Stat,.st_ino,.st_mode,.st_nlink,.st_uid,.st_gid,.st_rdev,.st_mtime,.st_size,.st_blocks
%else
B_STRUC Stat,.st_ino,.st_mode,.st_nlink,.st_uid,.st_gid,.st_rdev,.st_size,.st_blocks,.st_mtime
%endif
%endif
%ifdef TAR_PREFIX
 FILENAME	resb 256
%endif
%ifdef TAR_MATCH
 tar_match	resd 1
%endif

tar:
.name		resb 0100
.mode		resb 0008
.uid		resb 0008
.gid		resb 0008
.size		resb 0012
.mtime		resb 0012
.chksum		resb 0008
.typeflag 	resb 0001
.linkname	resb 0100
.magic		resb 0006
.version	resb 0002
.uname		resb 0032
.gname		resb 0032
.devmajor	resb 0008
.devminor	resb 0008
.prefix		resb 0155

buffer resb BUFF_SIZE

%ifdef TAR_CREATE
.slop		resd 1
lastdirentry	resd 1
udata_end	resd 0
%endif

END
