;  cda2raw.asm
;
;  dump cdaudio data to raw file(s)
;
;  (c) 2k2.11(24) Maciej Hrebien
;
;  USAGE: cda2raw [[-s] [-txx-yy]] [/dev/cdrom]
;
;    -s      - separate each track to his own rawfile
;    -txx-yy - grab only [xx,yy] track(s)
;
;      xx & yy are 2 char nrs in range 1-99, ie:
;              "... -t03-17" will grab tracks from 3 to 17
;                    -^- this "0" is needed, as yet :)
;
;  NOTE: by default whole /dev/cdrom is dumped to "track00.raw" file.
;
; $Id: cda2raw.asm,v 1.2 2006/02/09 08:05:12 konst Exp $

%include "system.inc"

CPU 486

%assign CDROMREADTOCHDR		0x5305
%assign CDROMREADTOCENTRY	0x5306
%assign CDROMREADAUDIO		0x530e
%assign CDROMCLOSETRAY		0x5319
%assign CDROM_DRIVE_STATUS	0x5326
%assign CDROM_DISC_STATUS	0x5327

%assign CDROM_MSF		0x02
%assign CDROM_LEADOUT		0xaa
%assign CDROM_DATA_TRACK	0x04

%assign CDS_NO_INFO		0
%assign CDS_NO_DISC		1
%assign CDS_TRAY_OPEN		2
%assign CDS_DRIVE_NOT_READY	3
%assign CDS_DISC_OK		4

%assign CD_FRAMES		75
%assign CD_FRAMESIZE_RAW	2352

CODESEG

; convert ascii 2-char decimal to binary
; in:  %esi - as a ptr
; out: %al, %ah = 0, CF set if err

 dec2bin:
	lodsb
	or	al,al
	jz	short _err

	mov	ah,al
	lodsb

	sub	ah,'0'
	jc	short _ret

	sub	al,'0'
	jc	short _ret

	cmp	ah,9
	jg	short _err

	cmp	al,9
	jg	short _err

	aad
	clc
	ret
 _err:	stc
 _ret:	ret


; main routine :)

 START:
	pop	eax			; argc
	pop	eax			; argv[0]

	mov	ebp,cdrom		; default path
 argv:
	pop	esi			; argv[n]

	or	esi,esi
	jz	short dev_open

	lodsb				; what we have in argv[n]?
	cmp	al,'-'			; flag?
	je	short got_flag

	cmp	al,'/'			; cdrom dev path?
	je	short got_path

	jmp	print_help		; ee.. ?!

 got_flag:

	lodsb
	cmp	al,'s'			; is it s-flag..
	je	short got_s_flag

	cmp	al,'t'			; or t-flag?
	je	short got_t_flag

	jmp	print_help		; ee.. ?!

 got_s_flag:

	lodsb
	or	al,al			; not really (stand alone) s-flag?
	jnz	near print_help

	inc	byte [s_flag]		; yup, we've got s-flag, note that!
	jmp	short argv

 got_t_flag:

	inc	byte [t_flag]		; yup, we've got t-flag, note that & analize..

	call	dec2bin
	jna	near print_help		; CF = 1 (err) or ZF = 1 (al can't be 0, trks
					; are numbered from 1!) ?
	mov	dl,al

	lodsb
	cmp	al,'-'			; yes, i am pedantic in here! ;)
	jne	near print_help

	call	dec2bin
	jna	near print_help		; the same thing, err or can't be 0, 1 at least!

	cmp	dl,al			; -t xx > yy ?
	jg	near err

	mov	dh,al
	mov	[start_trk],dx		; = mov [start_trk],dl; mov [end_trk],dh

	lodsb
	or	al,al			; not really (stand alone) t-flag?
	jnz	near print_help

	jmp	short argv

 got_path:

	lea	ebp,[esi-1]		; yup, dev path!
	jmp	short argv

 dev_open:

	sys_open ebp,O_RDONLY|O_NONBLOCK

	or	eax,eax
	js	near err

	xchg	ebp,eax

 get_status:

;	sys_ioctl ebp,CDROM_DRIVE_STATUS,0
	sys_ioctl ebp,CDROM_DRIVE_STATUS,EMPTY

	cmp	eax,CDS_NO_DISC
	je	near err

	cmp	eax,CDS_TRAY_OPEN
	je	short close_tray

	cmp	eax,CDS_DRIVE_NOT_READY
	je	near err

	jmp	short disc_ok		; or no info!

 close_tray:

;	sys_ioctl ebp,CDROMCLOSETRAY,0
	sys_ioctl ebp,CDROMCLOSETRAY,EMPTY

	or	eax,eax
	js	near err

	jmp	short get_status

 disc_ok:

	push	dword 0

	sys_ioctl ebp,CDROMREADTOCHDR,esp

	or	eax,eax
	js	near err

	mov	ebx,start_trk
	pop	eax

	cmp	[ebx+2],byte 0		; t_flag set? chck it according to toc_hdr..
	je	short without_t

	cmp	[ebx],al		; = cmp [start_trk],al
	jl	near err

	cmp	[ebx+1],ah		; = cmp [end_trk],ah
	jg	short to_end		; to BIG #.. grab it to the end, i mean leadout..

	jmp	short t_chcked

 without_t:
	mov	[ebx],al		; = mov [start_trk],al
 to_end:
	mov	[ebx+1],ah		; = mov [end_trk],ah
 t_chcked:

	mov	[ebx-1],ah		; = mov [cd_end_trk],ah, note what trk (#) is
					; at the end of our disc
	mov	esi,fname

	cmp	[ebx+3],byte 0		; = cmp [s_flag],byte 0, if s-flag is set..
	jz	fopen
 adj:
	lea	edi,[esi+5]		; adjust fname to something like "trackxx.raw"
	mov	al,[start_trk]		; where xx is the # of trk going to be grabbed..
	aam
	add	ax,'0' << 8 | '0'
	xchg	ah,al
	stosw
 fopen:
;	sys_open esi,O_CREAT|O_WRONLY|O_TRUNC,0644
	sys_open esi,O_CREAT|O_WRONLY|O_TRUNC,0x1a4

	or	eax,eax
	js	near err

	xchg	edi,eax
 grab:
	mov	eax,CDROM_MSF << 16
	mov	al,[start_trk]

	push	dword 0			; get start_trk's msf_addr from disc..
	push	dword 0
	push	eax

	sys_ioctl ebp,CDROMREADTOCENTRY,esp

	or	eax,eax
	js	near err

	pop	eax			; skip if data trk..
	push	eax
	test	ah,CDROM_DATA_TRACK << 4
	jnz	near skip_trk

	mov	eax,CDROM_MSF << 16
	mov	al,[start_trk]
	inc	al

	cmp	[cd_end_trk],al		; is next trk the leadout?
	jnl	not_leadout

	mov	al,CDROM_LEADOUT

 not_leadout:

	push	dword 0			; get (start_trk + 1) msf_addr from disc..
	push	dword 0
	push	eax

	sys_ioctl ebp,CDROMREADTOCENTRY,esp

	or	eax,eax
	js	near err
					; note: from now on start_trk's msf_adr will be
 do_grab:				; moving ahead till (start_trk + 1) msf_addr
					; isn't reached..
	push	dword frame
	push	dword 1			; read & store 1 frame dep on start_trk's
	push	dword CDROM_MSF		; msf_addr..
	push	dword [esp+28]

	sys_ioctl ebp,CDROMREADAUDIO,esp

	or	eax,eax
	js	near err

	sys_write edi,[esp+12],CD_FRAMESIZE_RAW

	or	eax,eax
	js	err

	pop	eax			; inc start_trk's msf_addr..
	add	esp,12

	bswap	eax			; al - frame, ah - second..
	shr	eax,8

	inc	al

	cmp	al,CD_FRAMES
	jl	short store_jmp

	xor	al,al
	inc	ah

	cmp	ah,60
	jl	short store_jmp

	xor	ah,ah
	add	eax,0x10000		; inc minute

 store_jmp:

	shl	eax,8
	bswap	eax
	mov	[esp+16],eax		; store inc-ed start_trk's msf_addr

	cmp	[esp+4],eax		; done with this trk?
	jne	near do_grab

	add	esp,12			; seems to..

 skip_trk:

	add	esp,12

	mov	ebx,start_trk
	mov	al,[ebx+1]		; = mov al,[end_trk]
	inc	byte [ebx]

	cmp	al,[ebx]		; done with all trks?
	jl	short exit

	cmp	[ebx+3],byte 0		; = cmp [s_flag],byte 0, are we grabbing to one file
	jz	near grab		; or splitting?

;	sys_close edi

	jmp	adj

 print_help:
	sys_write STDERR,help,40
 err:
;	sys_close ebp
;	sys_close edi
	sys_exit 1
 exit:
;	sys_close ebp
;	sys_close edi
	sys_exit 0

 _rodata:

 cdrom	db "/dev/cdrom",0x0
 help	db "$ cda2raw [[-s] [-txx-yy]] [/dev/cdrom]",0xa

DATASEG

 fname	db "track00.raw",0x0

UDATASEG

 frame		resb CD_FRAMESIZE_RAW
 cd_end_trk	resb 1
 start_trk	resb 1
 end_trk	resb 1
 t_flag		resb 1
 s_flag		resb 1

END
