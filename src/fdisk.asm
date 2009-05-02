;Copyright (C) Rudolf Marek <marekr2@fel.cvut.cz>, <ruik@atlas.cz>
;			    
;$Id: fdisk.asm,v 1.3 2002/02/02 08:49:25 konst Exp $
;
;hackers' fdisk 
;
;syntax: fdisk device
;example: fdisk /dev/hda
;
; At this time it only writes down information about your partitions,
;including extended part.
;FIXME:
;start/len may vary a bit from reality due to p_start (63 sectors usally) 
;in extended partitions, this value add or sub from printed ones. I didn't
;write it in a program because I can't understand it why to to do it...

;All your base are belong to us

%include   "system.inc"
	   
%assign p_boot 	  0
%assign p_s_head  1
%assign p_s_sec   2
%assign p_s_track 3
%assign p_os_ind  4
%assign p_e_head  5
%assign p_e_sec   6
%assign p_e_track 7
%assign p_start   8
%assign p_len     012

CODESEG
newline db __n

do_exit:
	sys_exit 0

START:
	pop	eax
	cmp	eax,2
	jnz	do_exit
	pop	ebx
	pop	ebx
	sys_open EMPTY, O_RDONLY|O_LARGEFILE
	test   	eax,eax
	js	do_exit
	push   	eax
	xchg   	ecx,ebx
	mov    	edx,ecx
.next_c:
	cmp byte [edx],1
	inc 	edx
	jnb .next_c
	sub 	edx,ecx
	dec 	edx
	sys_write STDOUT,EMPTY,EMPTY
        pop 	ebx
	sys_ioctl EMPTY,HDIO_GETGEO,hd_geometry
        push 	ebx ;the handle for HDD
	sys_write STDOUT,print_chs,print_chs_l
	call .print_chs
	sys_write STDOUT,newline,1
	pop 	ebx
	sys_read EMPTY,sector,0x200
	mov 	[handle],ebx
	mov   	edi,p1
	xor   	edx,edx
.print_info_loop:    ;in this loop we print all 4 MBR part info
	push 	edx
	push 	edi
	call .print_info 
	pop 	edi
	pop 	edx
	inc 	dl
	add 	edi,016 ;BAD
	cmp 	edi,p1+(4*16)
	jnz 	.print_info_loop
%ifdef __LINUX__ ;this is for extended partiotions...
	mov 	ebp,edx  ;part no..
	mov 	eax,[extended_add]
	or 	eax,eax
	jz near .ok_end
	mov 	[extended_cur],eax
	mov 	edx,eax
	xor 	ecx,ecx
	shld 	ecx,edx,9
	shl 	edx,9  ;Now we have in ECX:EDX offset of first extended part
	push 	ecx
	push 	edx
.print_next:
	pop 	edx
	pop 	ecx
	sys_llseek [handle],EMPTY,EMPTY,result,SEEK_SET
	sys_read [handle],sector,0x200
	mov 	edx,ebp
	mov 	edi,p1
	xor 	esi,esi ;BAD bad ... mark in esi if we have visited this round ext part
.chk_ext_loop:
	cmp byte [edi+p_os_ind],5
	jz .next_extended
	cmp byte [edi+p_os_ind],0xf
	jz .next_extended
	cmp byte [edi+p_os_ind],0x85
	jz .next_extended
	cmp byte [edi+p_os_ind],0x0
	jz .empty
	;we have next part to print in ext par
	push 	edx
	push	edi
	push 	esi
	call .print_info 
	pop 	esi
	pop 	edi
	pop 	edx
	inc dl
	mov 	ebp,edx
.empty:
	add 	edi,016 ;BAD
	cmp 	edi,p1+(4*16)
	jnz .chk_ext_loop
	or 	esi,esi
	jnz .print_next
	jmps .ok_end
.next_extended:
	inc 	esi
	xor 	ecx,ecx
        mov edx,[edi+p_start]
	add edx,[extended_add]
	mov [extended_cur],edx ;Beware ... overflow might happen...
	adc 	ecx,0
	shld 	ecx,edx,9
	shl  	edx,9
	push 	ecx
	push 	edx
	jmps .empty  
%endif
.ok_end:
	sys_close [handle]
	sys_exit 0
    
.print_chs:
	movzx 	eax, word [c]
	call .print_eax
	sys_write STDOUT,print_slash,1
	movzx 	eax, byte [h]
	call .print_eax
	sys_write STDOUT,print_slash,1    
        movzx 	eax, byte [s]
	call .print_eax
	ret    

.print_info: ;edi points to part info edx which print
	cmp 	word [sig],0x55AA
	jz .ok_sig
	cmp 	word [sig],0xAA55
	jz .ok_sig
	sys_write STDOUT,bad,bad_l
	sys_exit 255
	ret    
.ok_sig:
	mov 	ebp,edx
	sys_write STDOUT,part,part_l
	mov 	eax,ebp
	mov 	ebp,edi
	inc 	eax
	call 	.print_eax
	push	 dword .print_type
	cmp byte [ebp+p_os_ind],6
	jnz .not_fat16
	mov 	ecx,fs_fat16
	_mov 	edx,fs_fat16_l
	ret
.not_fat16:
	cmp byte [ebp+p_os_ind],0xb
	jnz .not_fat32
.is_also_fat32:
	mov 	ecx,fs_fat32
	_mov 	edx,fs_fat32_l
	ret
.not_fat32:
	cmp byte [ebp+p_os_ind],0xc
	jz .is_also_fat32
	cmp byte [ebp+p_os_ind],0xa5
	jz .is_bsd
	cmp byte [ebp+p_os_ind],0xa6
	jz .is_bsd

	cmp byte [ebp+p_os_ind],0x82
	jnz .not_swap
	mov 	ecx,fs_swap
	_mov 	edx,fs_swap_l
        ret
.is_bsd:
	mov 	ecx,fs_bsd
	_mov 	edx,fs_bsd_l
	ret

.not_swap:
	cmp byte [ebp+p_os_ind],0x83
	jnz .not_linux
	mov 	ecx,fs_linux
	_mov 	edx,fs_linux_l
	ret
.not_linux:
	cmp byte [ebp+p_os_ind],0
	jnz .not_free
	mov	ecx,fs_free
	_mov	edx,fs_free_l
	ret
.not_free:
	cmp byte [ebp+p_os_ind],5
	jz .pextended
	cmp byte [ebp+p_os_ind],0xf
	jz .pextended
	cmp byte [ebp+p_os_ind],0x85
	jz .pextended
	mov 	ecx,fs_unk
	_mov 	edx,fs_unk_l
	ret
.pextended:
	mov 	eax,[ebp+p_start]
	mov 	[extended_add],eax
	mov 	ecx,fs_ext
	_mov 	edx,fs_ext_l
	ret
.print_type:
	sys_write STDOUT,EMPTY,EMPTY
	cmp byte [ebp+p_os_ind],0
	jz near .end_info
	cmp byte [ebp+p_boot],0x80
	jnz .not_active
	sys_write STDOUT,bootable,bootable_l
.not_active:
	sys_write STDOUT,newline,1
	sys_write EMPTY,start,start_l
	mov 	al,[ebp+p_s_head]
	mov 	[h],al
	mov 	al,[ebp+p_s_sec]
	and 	al,00111111b
	mov 	[s],al
	mov 	ah,[ebp+p_s_sec]
	shr 	ah,6
	mov 	al,[ebp+p_s_track]
	mov 	[c],ax
	call .print_chs
	sys_write STDOUT,stop,stop_l
        mov 	al,[ebp+p_e_head]
	mov 	[h],al
	mov 	al,[ebp+p_e_sec]
	and 	al,00111111b
	mov 	[s],al
	mov	ah,[ebp+p_e_sec]
	shr 	ah,6
	mov 	al,[ebp+p_e_track]
	mov 	[c],ax    
	call .print_chs
	sys_write STDOUT,newline,1
	sys_write EMPTY,lin,lin_l
	mov 	eax,[ebp+p_start]
	add 	eax,[extended_cur]
	call .print_eax
	sys_write STDOUT,print_slash,1
	mov 	eax,[ebp+p_len]
	call .print_eax    
.end_info:
	sys_write STDOUT,newline,1
	ret
.print_eax:
	mov 	edi,scratch_pad
	call .LongToStr
	sub	edi,scratch_pad+1
	mov 	edx,edi
	sys_write STDOUT,scratch_pad,EMPTY
	ret
.LongToStr:
	_mov 	ebx,10      
        push  byte  0
.next_dig:
        xor	edx, edx             
        div	ebx                  
        or      dl,'0'	                                     
        push	edx                  
        test	eax, eax             
	jnz	.next_dig
.pop_next:
        pop	eax
	stosb
	or al,al
	jnz .pop_next
        ret

start 		db "CHS start "
start_l 	equ $-start
stop		db " stop "
stop_l 		equ $-stop
part  		db "partition "
part_l 		equ $-part
lin  		db "lin start/len "
lin_l 		equ $ - lin
bootable  	db " is bootable (active)"
bootable_l 	equ $-bootable
print_chs    	db " has C/H"
print_slash: 	db "/S "
print_chs_l 	equ $ - print_chs
fs_fat16 	db	" FAT16"
fs_fat16_l 	equ $ - fs_fat16
fs_fat32 	db	" FAT32"
fs_fat32_l 	equ $ - fs_fat32
fs_ext   	db	" Extended"
fs_ext_l 	equ $ - fs_ext
fs_linux 	db	" Linux ext2"
fs_linux_l 	equ $ - fs_linux
fs_swap  	db	" Linux swap"
fs_swap_l 	equ $ - fs_swap
fs_bsd  	db	" BSD slice"
fs_bsd_l 	equ $ - fs_bsd
fs_unk  	db	" Unk update me!"
fs_unk_l 	equ $ - fs_unk
fs_free  	db	" Free"
fs_free_l 	equ $ - fs_free
bad  		db	"Bad sector signature ! - Do not panic might be fdisk bug...",__n
bad_l 		equ $ - bad

UDATASEG

result resd 2
handle resd 1
extended_add resd 1
extended_cur resd 1
hd_geometry:
h 	resb 1
s 	resb 1
c 	resw 1
startx 	resd 1
scratch_pad resd 4
sector:  
	resb 0446
p1   	resb 016
p2  	resb 016
p3   	resb 016
p4   	resb 016 
sig     resw 1

END
