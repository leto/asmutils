; Copyright (C) 2002 by Joshua Hudson
;
; hacker's mkfs.minix
;
; usage: mkfs.minix [-i inodecount] device [size-in-blocks]
;
;NOTE:
; -c and -l are not supported. If someone decides to support them,
; please make it a compilation conditional. There is a good reason
; to omit them (e.g. ramdisk-only usage, as in a rescue floppy).
;
; $Id: mkfs.minix.asm,v 1.2 2002/06/24 16:55:10 konst Exp $

%include 'system.inc'

%ifndef BLKGETSIZE
 %define BLKGETSIZE 0x1260
%endif

%define BLOCKSIZE 1024
%define MAGIC 0x138F			; Minix v1, 30 char filenames
%define BITSPERBLOCK 1024 * 8
%define INODESPERBLOCK 32
%define INODESHIFT 5
%define SETINODEMASK 0xFFE0

CODESEG

compsize:
	sys_ioctl	eax, BLKGETSIZE, blocks
	mov	eax, [blocks]
	shl	eax, 9
	or	eax, eax
	jnz	.chk
	sys_lseek	EMPTY, 0, SEEK_END
.chk	cmp	eax, 6 * BLOCKSIZE
	js	error
	shr	eax, 10
	push	eax
	xor	ecx, ecx
	xor	edx, edx
	sys_lseek
	pop	eax
	jmps	gtsz
error:	sys_exit_false

START:
	pop	ebx
	pop	ebx
	pop	ebx
	or	ebx, ebx
	jz	error
	cmp	[ebx], word '-i'
	jne	getdev
	pop	ebx
	or	ebx, ebx
	jz	error
	call	atoi
	mov	[inodes], eax
	pop	ebx
	or	ebx, ebx
	jz	error
getdev:	sys_open	ebx, O_RDWR
	or	eax, eax
	js	error
	mov	[device], eax
	mov	[devst], ebx
	pop	ebx		; get number of blocks
	or	ebx, ebx
	jz	near compsize
	call	atoi
gtsz:	cmp	eax, 6
	jl	error
	mov	[blocks], eax

; Everyting is loaded from the command line
; ****************** SETUP TABLES *****************
	sys_write	STDOUT, disp1, disp1len
	mov	[superblock.logZoneSize], word BLOCKSIZE
	mov	[superblock.fsState], word 1
	mov	[superblock.fsMagic], word MAGIC
	mov	[superblock.nMaxSize], dword 1024 * (7 + 512 + 512 * 512)

	mov	eax, [inodes]		; Check number of inodes
	or	eax, eax
	jnz	inode_set
	mov	eax, [blocks]
	mov	[superblock.nZones], ax	; Why?
	xor	edx, edx
	xor	ecx, ecx
	mov	cl, 3
	div	ecx			; Inodes = Inodes ?: Blocks / 3
inode_set:
	add	eax, byte 31
	and	eax, SETINODEMASK	; Rounded to blocks

	mov	[inodes], eax
	mov	[superblock.nInodes], ax
	push	eax			; PUSH INODES (see below)
	xor	edx, edx		; find imaps
	_mov	ecx, BITSPERBLOCK
	add	eax, ecx	; Why not BITSPERBLOCK - 1 ?
	div	ecx		; ECX = BITSPERBLOCK
	mov	[superblock.nImapBlocks], ax
	shl	eax, 10
	mov	[imaps], eax		; IMAPS
	mov	eax, [blocks]
	pop	ebx			; Number of INODES
	shr	ebx, INODESHIFT		; Number of inodes per block
	sub	eax, ebx
	dec	eax
	dec	eax
	sub	ax, [superblock.nImapBlocks]

	; eax = available blocks
	; ZONES = [AVB * (BTB - 1) + 1] / (BTB + 1)
	; ZMAPS = AVB - ZONES
	; 32 bit internal arithmatic for a 16 bit filesystem
	push	eax
	dec	ecx
	mul	ecx			; ECX = BITSPERBLOCK
	inc	eax
	inc	ecx
	inc	ecx
	div	ecx
	pop	ebx
	sub	ebx, eax
	mov	[zones], eax
	mov	[superblock.nZmapBlocks], bx
	shl	ebx, 10
	mov	[zmaps], ebx

	mov	eax, space
	mov	[iptr], eax
	add	eax, [imaps]
	mov	[zptr], eax

	; ***************** Display computed data ***************
	mov	ecx, [devst]
	mov	esi, ecx
.strln:	lodsb
	or	al, al
	jnz	.strln
	dec	esi
	sub	esi, ecx
	mov	edx, esi
	sys_write	STDOUT  ; , [devst], strlen(devst)
	mov	edi, itoabuf
	push	edi
	push	edi
	mov	ax, ': '
	stosw
	mov	eax, [inodes]
	call	itoa
	pop	ecx
	mov	edx, edi
	sub	edx, ecx
	sys_write	STDOUT	;, [itoabuf], strlen(itoabuf)
	sys_write	EMPTY, disp2, disp2len
	pop	edi		; EDI = itoabuf
	mov	eax, [zones]
	push	edi
	call	itoa
	pop	ecx
	mov	edx, edi
	sub	edx, ecx
	sys_write	STDOUT	;, [itoabuf], strlen(itoabuf)
	sys_write	EMPTY, disp3, disp3len

;********************** FILL BITMAPS *************
	mov	edi, [iptr]
	mov	[edi], byte 3		; Junk and root inode used
	mov	ebx, [imaps]
	add	ebx, edi		; Stop block
	mov	eax, [inodes]
	shr	eax, 8 - INODESHIFT	; Bytes to keep clear
	add	edi, eax
	mov	al, 0xFE
	stosb

	mov	al, 0xFF		; Set all full bytes
ibf:	stosb
	cmp	edi, ebx
	jb	ibf

	mov	edi, [zptr]
	mov	ebx, [inodes]
	shr	ebx, INODESHIFT
	_mov	eax, 2			; Compute first zone
	add	ax, [superblock.nImapBlocks]
	add	ax, [superblock.nZmapBlocks]
	add	eax, ebx
	mov	[firstzone], eax
	mov	[superblock.nFirstZone], ax

	mov	edi, [zptr]
	mov	[edi], byte 3		; Always 3?

	_mov	ebx, 8	
	mov	eax, [zones]		; Set final bits
	inc	eax
	xor	edx, edx		; EDX = part bits to keep clear
	div	ebx			; EAX = where to start setting bits
	mov	ebx, [zmaps]
	add	ebx, edi		; Stop location
	add	edi, eax
	mov	al, 1			; Set the stop bits
	mov	cl, dl
	shl	al, cl
	dec	al
	not	al
	or	[edi], al
	inc	edi
	xor	eax, eax
	dec	eax
.zblk:	stosd				; We can afford to go over here
	cmp	edi, ebx
	jle	.zblk

;********************** WRITE THE FILESYSTEM *****
write_fs:
	sys_write	[device], nblock, BLOCKSIZE	; Empty block
	or	eax, eax
	js	near werror
	sys_write	EMPTY, superblock		; Superblock
	or	eax, eax
	js	near werror
	mov	edx, [imaps]
	add	edx, [zmaps]
	sys_write	EMPTY, [iptr]			; Inode bitmaps
	or	eax, eax				; and Zone bitmaps
	js	near werror

;********************** BUILD ROOT INODE **********
	add	ecx, edx
	mov	edi, ecx
	push	ecx
	push	ebx
	mov	ax, S_IFDIR | 0755q
	stosw
	sys_getuid
	stosw
	xor	eax, eax
	mov	ebx, eax
	mov	al, 64
	stosd
	sys_time
	stosd
	sys_getgid
	stosb
	mov	al, 2
	stosb
	mov	eax, [firstzone]
	stosw
	pop	ebx
	pop	ecx
	mov	edx, BLOCKSIZE
	mov	esi, [inodes]
	shr	esi, INODESHIFT
.wri:	sys_write					; Write ROOT inode
	mov	ecx, nblock
	or	eax, eax
	js	werror
	dec	esi
	jnz	.wri
.noin	sys_write	EMPTY, rootblock, 64
	sys_exit_true
werror:	sys_write	STDERR, errorm, errorlen
	sys_exit_false

;********************** LIBRARY ******************
atoi:	_mov	ecx, 10
	mov	esi, ebx
	xor	ebx, ebx
	xor	eax, eax
.nxt:	mov	bl, [esi]
	inc	esi
	sub	bl, '0'
	js	rtn
	mul	ecx
	add	eax, ebx
	jmp	.nxt

itoa:	xor	ecx, ecx
	_mov	ebx, 10
.nxt:	xor	edx, edx
	div	ebx
	inc	ecx
	push	edx
	or	eax, eax
	jnz	.nxt
.pop:	pop	eax
	add	al, '0'
	stosb
	loop	.pop
rtn:	ret

disp1	db	'asmutils mkfs.minix', 10
disp1len equ $ - disp1
disp2	db	' inodes, '
disp2len equ $ - disp2
disp3	db	' zones', 10
disp3len equ $ - disp3
errorm	db	'write error', 10
errorlen	equ $ - errorm

rootblock	db	1, 0, '.', 0
		dd	0, 0, 0, 0, 0, 0, 0	; 7 zeros!
		db	1, 0, '..'

UDATASEG

nblock	resb	1024
itoabuf	resb	16
devst	resd	1
device	resd	1
inodes	resd	1
blocks	resd	1
imaps	resd	1
zmaps	resd	1
zones	resd	1
iptr	resd	1
zptr	resd	1
firstzone	resd	1
superblock:
	.nInodes	resw	1
	.nZones		resw	1
	.nImapBlocks	resw	1
	.nZmapBlocks	resw	1
	.nFirstZone	resw	1
	.logZoneSize	resw	1
	.nMaxSize	resd	1
	.fsMagic	resw	1
	.fsState	resw	1
padptr	resb	0
padsize equ BLOCKSIZE - (padptr - superblock)
padd	resb	padsize
space	resb	1024		; Extended forever if necessary!

END
