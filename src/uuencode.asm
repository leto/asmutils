; 2002 Christopher M. Brannon <cbrannon@wilnet1.com>
; This program is released under the GNU General Public License.
;
; uuencode [nearly GNU-compatible]
; Usage: uuencode [-m] [infile] headername
; The -m option causes this program to use base64 encoding instead of standard
; uuencoding.
; This utility reads stdin by default, but it will read from a file if
; infile is supplied.
; It always writes to standard output; there is no way to specify an output
; file.
; The "headername" argument is required.  It should be the name you wish
; the file to have when it is decoded on a remote system.  This name is
; used to construct the header of the output.
; If an error occurs during a system call, uuencode exits with an exit
; status equal to errno.  My error messages are no substitute for strerror
; or perror.
; This program is very similar to the C version from GNU Sharutils.
;
; $Id: uuencode.asm,v 1.3 2006/02/09 07:56:03 konst Exp $

; 0.01 initial release
; 0.02. strcat replaced by my own version.  Many extraneous instructions
; have been removed from loops.  The loop which reads input is far more
; efficient.  Input data is loaded into registers using lodsd.

%assign BUFSIZE 8190
; BUFSIZE must be divisible by 3 because we work with multiples of 3 bytes.
%assign OUTBUFSIZE 11300
; OUTBUFSIZE is determined by the formula (BUFSIZE / 3) * 4 + 364.

; These next four are constants for extracting groups of 6 bits during the
; encoding process.
%assign FIRSTGROUP 0xfc0000
%assign SECONDGROUP 0x03f000
%assign THIRDGROUP 0xfc0
%assign LASTGROUP 0x3f

; This is the trailer line for uuencoded files.  Consisting of 'end' + NL
%assign TRAILERTEXT 0x0a646e65 ; in little endian format

%include "system.inc"

CPU 486

CODESEG

START:
	_mov edi, header
	_mov [edi], dword "begi"
	_mov [edi + 4], byte "n"
	add edi, byte 5
	; All headers start with "begin", regardless of whether the program is using
	; standard uuencoding or base64 encoding.
_processArgs:
	pop eax
	pop ebx
	cmp eax, byte 2
	jl near _argError
	dec eax
	pop ebx
	cmp word [ebx], '-m'
	; This only tests a word value.  Not very robust option processing.
	jne _setStd
	_mov dword [trans_ptr], base64_table ; Pointer to the translation table.
	_mov [edi], dword "-bas"
	_mov [edi + 4], dword "e64 "
	; Standard uuencode starts with "begin ", but base64 uses begin-base64
	add edi, byte 8
	_mov [edi], byte 0
	pop ebx ; Make sure processFiles has a string in ebx
	dec eax ; and remove -m from argc
	jmp short _processFiles
_setStd:
	_mov dword [trans_ptr], uu_table
	_mov [edi], word 0x0020
	inc edi
_processFiles:
	cmp eax, byte 2
	ja near _argError
	jb _oneFile
	pop esi ; esi contains the filename used in the header
	push eax
	sys_stat EMPTY, statbuf
	test eax, eax
	jnz near _statError
	_mov eax, [statbuf.st_mode]
	and eax, S_IRWXU | S_IRWXG | S_IRWXO
	call otoa
	add edi, byte 3
	_mov [edi], word 0x0020
	dec edi
	call strcat
	; header = "begin" + (" " || "-base64 ") + perms + outfilename
	xor edx, edx
	sys_open EMPTY, O_RDONLY
	test eax, eax
	js near _openError
	_mov [filedes], eax
	pop eax
	jmp short _endArgProc
_oneFile:
	cmp eax, byte 1 ; eax (argc) might equal 0.
	jne near _argError
	_mov [edi], dword '644 '
	add edi, byte 4
	_mov [edi], byte 0x00
	dec edi
	_mov esi, ebx
	call strcat
	_mov [filedes], dword STDIN
_endArgProc:
	mov esi, header
	call strlen
	mov [esi + edx], byte __n
	inc edx
	sys_write STDOUT, header
_topread:
	_mov dword [to_read], BUFSIZE
	readloop:
		_mov ebx, BUFSIZE
		_mov edx, [to_read]
		test edx, edx
		jz _process
		sub ebx, edx ; Compute offset into buffer of where to start reading.
		_mov ecx, buffer
		add ecx, ebx
		sys_read [filedes]
		_mov [last_read], eax
		test eax, eax
		js near _readError
		_mov ebx, [to_read]
		sub ebx, eax
		_mov [to_read], ebx
		test ebx, ebx
		jz _process
		test eax, eax
jnz readloop
	_process:
		; First, calculate the input length.
		_mov esi, buffer
		_mov edi, outbuf
		_mov edx, BUFSIZE
		sub edx, ebx
		; End calculation to determine input length.
		test edx, edx
		jz near _uufinished ; special case, zero-length buffer
		_mov [col], dword 0
		_mov ebx, [trans_ptr]
		cmp ebx, base64_table
		je _uuloop
		; Create the initial length byte of the first line for standard uuencoding
		_mov eax, edx
		cmp eax, byte 45
		jb _firstLengthEndif
		_mov al, byte 45
		; Lines of output can represent no more than 45 characters of input.
		_firstLengthEndif:
		add al, ' '
		stosb
	_uuloop:
		cmp edx, byte 2 ; while(edx > 2) {
		jna _handleRemain
		cmp dword [col], byte 45
			jl _loopNoNL
				call _insert_newline
		_loopNoNL: ; Slightly misnamed label.
		lodsd
		bswap eax
		shr eax, 8
		dec esi ; We loaded a dword, we only need 3 bytes
		_mov ecx, eax ; Store our value away, so it isn't clobbered
		and eax, FIRSTGROUP
		shr eax, 18
		xlatb
		stosb
		_mov eax, ecx
		and eax, SECONDGROUP
		shr eax, 12
		xlatb
		stosb
		_mov eax, ecx
		and ax, THIRDGROUP
		shr ax, 6
		xlatb
		stosb
		_mov eax, ecx
		and al, LASTGROUP
		xlatb
		stosb
		sub edx, byte 3
		add dword [col], byte 3
		jmp short _uuloop
; This is jumped over if not needed.
_handleRemain:
	test edx, edx
	jz _uufinished
	cmp dword [col], byte 45
		jl _remainderNoNL
		call _insert_newline
	_remainderNoNL:
	xor eax, eax
	cmp edx, byte 1
	je _oneByte
	lodsw
	xchg ah, al
	shl eax, 2
	_mov ecx, eax
	and eax, SECONDGROUP
	shr eax, 12
	xlatb
	stosb
	_mov eax, ecx
	and eax, THIRDGROUP
	shr eax, 6
	xlatb
	stosb
	_mov eax, ecx
	and eax, LASTGROUP
	xlatb
	stosb
	cmp ebx, base64_table
	jne _twoBytesElse
	_mov al, '='
	jmp short _twoBytesEndif
_twoBytesElse:
	_mov al, 0
	xlatb
_twoBytesEndif:
	stosb
	jmp short _uufinished
_oneByte:
	lodsb
	shl ax, 4
	_mov cx, ax
	and ax, THIRDGROUP
	shr ax, 6
	xlatb
	stosb
	_mov al, cl
	and al, LASTGROUP
	xlatb
	stosb
	cmp ebx, base64_table
	jne _oneByteElse
	_mov al, '='
	jmp short _oneByteEndif
_oneByteElse:
	_mov al, 0
	xlatb
_oneByteEndif:
	_mov ah, al
	stosw

_uufinished:
	cmp edi, outbuf
	; This happens if the input file is empty.
	je _trailerLine
	_mov [edi], byte __n
	inc edi
	_mov esi, outbuf
	sub edi, esi
	sys_write STDOUT, esi, edi
	_mov eax, [last_read]
	test eax, eax
	jnz near _topread
	_trailerLine:
	_mov edi, outbuf
	cmp dword [trans_ptr], uu_table
	jne _base64Trailer
	; uuencode ends its output with a line containing one ` character, followed
	; by a line containing the word end
	_mov  word [edi], 0x0a60
	_mov dword [edi + 2], TRAILERTEXT
	; Unfortunate that we can't use hex in char/string constants
	sys_write STDOUT, outbuf, 6
	jmp short _exit
	_base64Trailer:
		; base64 uses a line containing 4 '=' characters as a trailer.
		_mov [edi], dword '===='
		_mov [edi + 4], byte __n
		sys_write STDOUT, edi, 5
_exit:
	sys_close [filedes]
	sys_exit [errnum] ; errnum = 0 unless we jumped here after an error condition.
; The following are subroutines.
_insert_newline:
	_mov al, byte __n
	stosb
	cmp ebx, base64_table ; No, we don't want a length byte when doing base64
	je _insertReturn
	cmp edx, byte 45
	jb _lengthByteElse
	_mov al, byte 45
	jmp short _lengthByteEndif
	_lengthByteElse:
		_mov al, dl
	_lengthByteEndif:
		add al, ' '
		stosb
	_insertReturn:
		_mov [col], dword 0
		ret


; This converts the last 3 digits of the octal value in eax to a string.
; Specifically written for uuencode.
otoa:
	push ebx
	_mov ebx, eax
	and ebx, 700q
	shl ebx, 10
	_mov bh, al
	and bh, 070q
	shr bh, 3
	_mov bl, al
	and bl, 7q
	shl ebx, 8
	or ebx, 0x30303000
	; What we have here is a zero-terminated string, in little endian format
	; in the eax register.
	; When written to memory, this reads left to right, as expected.
	bswap ebx
	_mov [edi], ebx
	pop ebx
	ret

; strlen borrowed from Dmitry Bakhvalov's cp utility.
; esi=string
; edx=strlen
strlen:
    		mov     edx,esi
    		dec     edx
.do_strlen:
                inc     edx
                cmp     [edx],byte 0
                jnz     .do_strlen
                sub     edx,esi
                ret

; esi=source
; edi=dest
strcat:
	pushad
	xchg esi, edi
	call strlen
	xchg esi, edi
	add edi, edx
	_strcatLoop:
	lodsb
	stosb
	test al, al
	jnz _strcatLoop
	popad
	ret

; source: esi
; dest: edi

strcpy:
	push esi
	push edi
	_strcpyLoop:
lodsb
stosb
		test al, al
		jnz _strcpyLoop
		pop edi
		pop esi
		ret

; The following code segments handle specific errors.
_argError:
	sys_write STDERR, _argErrorMsg, _argErrorSlen
	jmp _exit

_statError:
	neg eax
	_mov [errnum], eax
	_mov esi, ebx
	_mov edi, _errorStr
	call strcpy
	_mov esi, _statErrorMsg
	call strcat
	_mov esi, edi
	call strlen
	sys_write STDERR, _errorStr
	jmp _exit

_openError:
	neg eax
	_mov [errnum], eax
	_mov esi, _openErrorMsg
	_mov edi, _errorStr
	call strcpy
	_mov esi, ebx
	call strcat
	_mov esi, edi
	call strlen
	_mov [edi + edx], word 0x000a
	inc edx ; strlen after adding newline
	sys_write STDERR, _errorStr
	jmp _exit

_readError:
	neg eax
	_mov [errnum], eax
	sys_write STDERR, _readErrorMsg, _readErrorSlen
	jmp _exit

DATASEG

uu_table db '`!"#', "$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_"
base64_table db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
_argErrorMsg db "Usage: uuencode [-m] [infile] header", __n
_argErrorSlen equ $-_argErrorMsg
_openErrorMsg db "uuencode: unable to open ", 0x0
_statErrorMsg db ": no such file or directory", __n, 0x0
_readErrorMsg db "uuencode encountered a read error, exiting now", __n
_readErrorSlen equ $-_readErrorMsg

UDATASEG

alignb 4

errnum resd 1
trans_ptr resd 1
to_read resd 1
last_read resd 1
col resd 1
filedes resd 1
buffer resb BUFSIZE + 2
outbuf resb OUTBUFSIZE
statbuf B_STRUC Stat, .st_mode
_errorStr resb 0x800
header resb 0x800

END
