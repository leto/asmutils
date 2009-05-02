;Copyright (C) 2002 Stephan Walter <stephan.walter@gmx.ch>
;
;$Id: deflate.asm,v 1.1 2002/10/01 17:06:09 konst Exp $
;
; deflate/inflate - compression tool
; based on MHC archiver for MenuetOS
;          by Nikita Lesnikov (nlo_one@mail.ru, Republic of Belarus, Sluck)
;
; syntax:	deflate
;		inflate
; reads from stdin, prints to stdout
;
; WARNING:	max file size = 1meg
;		uses ~2.3meg virtual memory
;
; TODO:		split up the input file in multiple chunks
;		implement LZSS (or better) algorithm
;		error-handling (wrong file format)
;
;0.01: 18-Aug-2002	Initial release (SW)
;
;==============================================================================
;
; Brief file format description:
;
;--------+------+-------------------------------------------------------
; Offset | Size | Description
;--------+------+-------------------------------------------------------
;      0 |    1 | Method ID
;        |      | Currently supported:
;        |      |    00    LZP (order-2, MenuetOS/MHC compatible)
;        |      | Planned:
;        |      |    01    LZSS
;--------+------+-------------------------------------------------------
;      1 |    4 | Size of uncompressed file in bytes
;--------+------+-------------------------------------------------------
;      5 |    x | Compressed data
;--------+------+-------------------------------------------------------
;
; New methods can be easily added without loss of compatibility
; with older versions
;

;==============================================================================

%include "system.inc"

%assign	FBUFSIZE	1024*1024
%assign STD_METHOD	0	; standard method for compressing
%assign	NR_OF_METHODS	1	; Currently there's only one compression method

CODESEG

START:
	pop esi
	pop esi
.n1:				; how we are called?
	lodsb
	or al,al
	jnz .n1
	cmp byte [esi-8], 'i'
	je go_inflate
	mov eax, compress
	jmps go_call

go_inflate:
	mov eax, decompress

go_call:
	call eax
	sys_exit

;==============================================================================
; ======== compression/decompression engine ========
;==============================================================================

compr_jumptable		dd lzp_compress

compress:
	call fill_filebufs

	mov esi, ifile           ; init pointers
	mov edi, ofile

	sys_read STDIN, esi, FBUFSIZE

	push eax		; write header: ID0+4bfilesize => total 5 bytes
	mov al, STD_METHOD
	stosb
	pop eax
	stosd

	jmp [compr_jumptable+STD_METHOD*4]

compress_dumpdata:
	sys_write STDOUT, ofile, edx
	ret

;==============================================================================

decompr_jumptable	dd lzp_decompress

decompress:

	call fill_filebufs

	sys_read STDIN, ofile, FBUFSIZE

	xor eax, eax
	mov al, [ofile]
	cmp al, NR_OF_METHODS
	jb  right_method

	; print some kind of error msg...
	ret

right_method:
	jmp [decompr_jumptable+eax*4]

decompress_dumpdata:
	sys_write STDOUT, ifile, edx
	ret

;==============================================================================
fill_filebufs:             ; Fill filebufs with garbage to simplify matching
	pusha
	mov eax,0xF7D9A03F         ; <- "magic number" :) just garbage...
	mov ecx,(FBUFSIZE/2)
	mov edi,ifile
	rep stosd
	popa
	ret

;==============================================================================
; ==== algorithms section ====
;==============================================================================

; Method 0: LZP compression algorithm

lzp_compress:           ; EDX - how much bytes to dump

	call fillhashtable

	add eax,esi              ; calculate endpointer
	mov dword [endpointer],eax

	movsw                    ; copy three bytes
	movsb

	mov dword [controlp],edi
	inc edi

c_loop:
	cmp dword [endpointer],esi  ; check end of file
	ja  c_loop_ok
	jmp finish_c_loop
c_loop_ok:

	call chash
	call compare
	jz   two_match_c

	lodsb
	mov byte [literal],al
	call chash
	call compare
	jz   lit_match_c

	mov  al,0
	call putbit
	mov  al,byte [literal]
	stosb
	movsb
	jmp  c_loop

lit_match_c:
	mov al,1
	call putbit
	mov al,0
	call putbit
	mov al,byte [literal]
	stosb
	jmp encode_match

two_match_c:
	mov al,1
	call putbit
	call putbit

encode_match:
	call incpos
	call compare
	jz one_c
	mov al,0
	call putbit
	jmp c_loop
one_c:

	call incpos
	mov  al,1
	call putbit

	call compare
	jnz near ec1
	call incpos
	call compare
	jnz near ec2
	call incpos
	call compare
	jnz near ec3
	call incpos
	call putbit
	call putbit
	call compare
	jnz near ec4
	call incpos
	call compare
	jnz near ec5
	call incpos
	call compare
	jnz near ec6
	call incpos
	call compare
	jnz near ec7
	call incpos
	call compare
	jnz near ec8
	call incpos
	call compare
	jnz ec9
	call incpos
	call compare
	jnz ec10
	call incpos

	mov al,1
	call putbit
	call putbit
	call putbit
	xor  ecx,ecx

match_loop_c:
	cmp  esi,dword [endpointer]
	jae near out_match_loop_c
	call compare
	jnz near out_match_loop_c
	inc  ecx
	call incpos
	jmp  match_loop_c

ec10:
	call putbit
	call putbit
	mov al,0
	call putbit
	jmp c_loop

ec9:
	call putbit
ec2:
	mov al,0
	call putbit
	mov al,1
	call putbit
	jmp c_loop

ec8:
	call putbit
ec1:
	mov al,0
	call putbit
	call putbit
	jmp c_loop

ec7:
	mov al,0
	call putbit
	mov al,1
	call putbit
	call putbit
	jmp c_loop

ec4:
	mov al,0
	call putbit
	call putbit
	call putbit
	jmp c_loop

ec5:
	mov al,0
	call putbit
	call putbit
	mov al,1
	call putbit
	jmp c_loop

ec6:
	mov al,0
	call putbit
ec3:
	mov al,1
	call putbit
	mov al,0
	call putbit
	jmp c_loop

out_match_loop_c:
	mov al,0xFF
out_lg:
	cmp ecx,255
	jb  out_lg_out
	stosb
	sub ecx, 255
	jmp out_lg
out_lg_out:
	mov al,cl
	stosb
	jmp c_loop

finish_c_loop:
	mov eax,dword [controlp] ; store last tagbyte
	mov bl,byte [controld]
	mov [eax], byte bl

	sub edi,ofile ; calculate dump size
	mov edx,edi

	jmp compress_dumpdata

;==============================================================================

; LZP decompression algorithm

lzp_decompress:                        ; EDX - how many bytes to dump

	mov edi,ifile
	mov esi,ofile+1

	call fillhashtable

	lodsd

	mov ebx,edi
	add ebx,eax
	mov dword [endpointer],ebx

	movsw
	movsb

	lodsb
	mov byte [controld],al
	mov byte [controlb],0

d_loop:
	cmp dword [endpointer],edi
	ja d_loop_ok
	jmp finish_d_loop
d_loop_ok:

	call getbit
	cmp  al,0
	jnz  match_d
	call dhash
	movsb
	call dhash
	movsb
	jmps d_loop

match_d:
	call getbit
	cmp  al,0
	jnz  no_literal_before_match
	call dhash
	movsb
no_literal_before_match:

	call dhash
	mov ecx,1
	call copymatch

	call getbit
	cmp  al,0
	jz   d_loop
	mov  ecx,1
	call copymatch
	call getbit
	cmp  al,0
	jz   near dc2
	mov  ecx,2
	call copymatch
	call getbit
	cmp  al,0
	jz   d_loop
	mov  ecx,1
	call copymatch
	call getbit
	cmp  al,0
	jz   dc4
	mov  ecx,4
	call copymatch
	call getbit
	cmp  al,0
	jz   dc5
	call getbit
	cmp  al,0
	jz   dc6
	mov  ecx,3
	call copymatch

do:
	lodsb
	xor  ecx,ecx
	mov  cl,al
	call copymatch
	cmp  al,0xFF
	jnz  end_do
	jmp do

end_do:
	jmp d_loop

dc6:
	mov ecx,2
	call copymatch
	jmp  d_loop

dc4:
	call getbit
	cmp  al,0
	jz   ndc4
	call getbit
	mov  ecx,3
	cmp  al,1
	jz   ndcc4
	dec  ecx
ndcc4:
	call copymatch
	jmp  d_loop

ndc4:
dc2:
dc5:
	call getbit
	cmp  al,0
	jz   ndccc4
	mov  ecx,1
	call copymatch
ndccc4:
	jmp  d_loop

finish_d_loop:
	mov edx, dword [ofile+1]

	jmp decompress_dumpdata

;==============================================================================
; LZP subroutines

fillhashtable:
	pusha                   ; fill hash table
	mov eax, ifile
	mov edi, hashtable
	mov ecx, 65536
	rep stosd
	popa
	ret

putbit:                  ; bit -> byte tag, AL holds bit for output
	pusha
	mov cl,byte [controlb]
	shl al,cl
	mov bl,byte [controld]
	or  bl,al
	mov byte [controld],bl
	inc cl
	cmp cl,8
	jnz just_increment
	mov word [controlb], 0		; set controlb and controld to zero
	mov eax, [controlp]
	mov [eax], bl
	mov dword [controlp],edi
	popa
	inc edi
	ret
just_increment:
	mov byte [controlb],cl
	popa
	ret

;==============================================================================
getbit:                       ; tag byte -> bit, AL holds input
	push ecx
	mov al,byte [controld]
	mov cl,byte [controlb]
	shr al,cl
	and al,1
	inc cl
	cmp cl,8
	jnz just_increment_d
	mov byte [controlb],0
	push eax
	lodsb
	mov byte [controld],al
	pop  eax
	pop  ecx
	ret
just_increment_d:
	mov byte [controlb],cl
	pop ecx
	ret

;==============================================================================
chash:                        ; calculate hash -> mp -> fill position
	pusha
	xor  eax,eax
	mov  al, byte [esi-1]
	mov  ah, byte [esi-2]
	shl  eax,2
	add  eax,hashtable
	mov  edx,dword [eax]
	mov  dword [mp],edx
	mov  dword [eax],esi
	popa
	ret

;==============================================================================
dhash:                        ; calculate hash -> mp -> fill position
	pusha
	xor  eax,eax
	mov  al, byte [edi-1]
	mov  ah, byte [edi-2]
	shl  eax,2
	add  eax,hashtable
	mov  edx,dword [eax]
	mov  dword [mp],edx
	mov  dword [eax],edi
	popa
	ret

;==============================================================================
copymatch:                    ; ECX bytes from [mp] to [rp]
	push esi
	mov  esi,dword [mp]
	rep  movsb
	mov  dword [mp],esi
	pop  esi
	ret

;==============================================================================
compare:                      ; compare [mp] with [cpos]
	push edi
	push esi
	mov  edi,dword [mp]
	cmpsb
	pop  esi
	pop  edi
	ret

;==============================================================================
incpos:
	inc  dword [mp]
	inc  esi
	ret

;==============================================================================

; LZP algorithm data

controlb	db	0
controld	db	0

UDATASEG
endpointer	resd	1
mp		resd	1
controlp	resd	1
literal		resb	1
hashtable	resb	65536*4
ifile		resb	FBUFSIZE
ofile		resb	FBUFSIZE

END
