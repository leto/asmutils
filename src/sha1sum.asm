; Copyright (C) Julius C. Duque, 2002 <jcduque (at) lycos (dot) com>
;
; $Id: sha1sum.asm,v 1.2 2006/02/09 07:57:48 konst Exp $
;
; Syntax: sha1sum file1 [file2 file3 ...]
;
; Calculates SHA1 (Secure Hash Standard, FIPS 180-1) checksum of input files.
; See doc/sha1sum.html for details.
; Will NOT read from STDIN
;
; Some lines were taken from md5sum.asm and rmdsum.asm by
; Cecchinel Stephan <interzone (at) pacwan (dot) fr>

%include "system.inc"

CPU 486

CODESEG

%assign  base_N     16
%assign  hexFormat  0x27        ; 0x27 = lowercase hex
                                ; 0x07 = uppercase hex

%assign  regSize    8           ; use 8 if base_N = 16
                                ; use 32 if base_N = 2

%assign  INIT_PAD   10000000b   ; padding with leading '1'
%assign  BLOCKSIZE  64          ; size of W in bytes
%assign  BUFSIZE    BLOCKSIZE   ; temp. buffer
%assign  MASK       0x0000000f
%assign  SPACE      0x20
%assign  NEWLINE    0x0a

; +-------------------------------------------------+
; |                 MAGIC CONSTANTS                 |
; +-------------------------------------------------+

%assign  H0    0x67452301
%assign  H1    0xefcdab89
%assign  H2    0x98badcfe
%assign  H3    0x10325476
%assign  H4    0xc3d2e1f0

%assign  K0    0x5a827999
%assign  K1    0x6ed9eba1
%assign  K2    0x8f1bbcdc
%assign  K3    0xca62c1d6

START:
    call   SHA1_Init
    pop    ebx
    dec    ebx
    pop    ebp

NEXT_FILE:
    pop    ebx
    test   ebx, ebx
    jnz    short FILE_PRESENT
    sys_exit

FILE_PRESENT:
    _mov   [name], ebx
    sys_open EMPTY, O_RDONLY
    _mov   ebp, eax
    test   eax, eax
    jns    short READ
    jmp    short NEXT_FILE

READ:
    ; re-initialize buffer with zeroes
    call   INIT_BUFFER
    _mov   ecx, buffer
    _mov   edx, BUFSIZE
    sys_read ebp
    test   eax, eax
    js     short NEXT_FILE
    call   SHA1_UPDATE
    cmp    ecx, byte BUFSIZE
    jb     short NEXT_F2
    call   SHA1_UPDATE
    jmp    short READ

NEXT_F2:
    _mov   edi, W
    _mov   edx, [edi-(4*6)]   ; LoPart is 24 bytes behind W[0]
    _mov   ecx, [edi-(4*7)]   ; HiPart
    shld   ecx, edx, 3        ; see NASM doc for explanation
    _mov   [edi+(4*14)], ecx
    shl    edx, 3
    _mov   [edi+(4*15)], edx
    call   SHA1_TRANSFORM
    _mov   esi, HH0
    _mov   ecx, 5

PrintHash:
    lodsd
    push   ecx
    call   PrintNum
    pop    ecx
    loop   PrintHash
    _mov   edx, SPACE
    call   _PrintChar
    _mov   edx, SPACE
    call   _PrintChar
    call   SHA1_Init
    _mov   esi, [name]
    push   esi

STRLEN:
    lodsb
    test   al, al
    jnz    short STRLEN
    pop    edi
    sub    esi, edi
    dec    esi
    sys_write STDOUT, edi, esi

STRFINI:
    _mov   edx, NEWLINE
    call   _PrintChar
    jmp    near NEXT_FILE

; +-------------------------------------------------+
; |                 PRINT FUNCTIONS                 |
; |                                                 |
; | On entry, eax should already hold the number to |
; | be printed.                                     |
; +-------------------------------------------------+

PrintNum:
    _mov   ecx, base_N
    _mov   ebx, regSize

  _PushStack:
    xor    edx, edx
    div    ecx
    push   edx
    dec    ebx
    test   ebx, ebx
    jz     short _PopStack
    call   _PushStack

  _PopStack:
    pop    edx
    _add   edx, '0'
    cmp    edx, byte '9'
    jbe    short _PrintChar
    _add   edx, hexFormat

  _PrintChar:
    _mov   [t], edx
    sys_write STDOUT, t, 1
    ret

; +-------------------------------------------------+
; |                 ROUND FUNCTIONS                 |
; +-------------------------------------------------+

F0:
; The next 3 lines use the following facts:
; W = edi, E = edi-4, D = edi-8, C = edi-12, etc.
    _mov   ebx, [edi-16]  ; same as_mov ebx, [B]
    _mov   ecx, [edi-12]  ; same as_mov ecx, [C]
    _mov   edx, [edi-8]   ; same as_mov edx, [D]
    ret

F1:
    call   F0
    xor    ecx, edx
    and    ebx, ecx
    xor    edx, ebx       ; edx now holds result
    ret

F2:
    call   F0
    xor    edx, ecx
    xor    edx, ebx       ; edx now holds result
    ret

F3:
    call   F0
    or     ebx, ecx
    and    edx, ebx
    _mov   ebx, [edi-16]  ; revive old B
    and    ecx, ebx
    or     edx, ecx       ; edx now holds result
    ret

; +-------------------------------------------------+
; |               SHA1 INITIALIZATION               |
; +-------------------------------------------------+

SHA1_Init:
    _mov   edi, HH0
    _mov   eax, H0
    stosd
    _mov   eax, H1
    stosd
    _mov   eax, H2
    stosd
    _mov   eax, H3
    stosd
    _mov   eax, H4
    stosd
    xor    eax, eax
    stosd                 ; initialize HiPart to 0
    stosd                 ; initialize LoPart to 0
    ret

; +-------------------------------------------------+
; |               SHA1 TRANSFORMATION               |
; +-------------------------------------------------+

SHA1_TRANSFORM:
    pusha
    _mov   edi, A         ; re-initialize A to E
    _mov   esi, HH0
    _mov   ecx, 5
    rep    movsd
    xor    ebx, ebx       ; use ebx as counter
    _mov   edi, W         ; save address of W

.LOOP1:
    _mov   ecx, ebx
    and    ecx, MASK
    _mov   esi, ecx       ; save ecx in esi; use esi as extra register
    cmp    ebx, byte 16
    jb     short .SKIP
    _add   ecx, 13
    and    ecx, MASK
    _mov   eax, [edi+4*ecx]
    _mov   ecx, esi
    _add   ecx, 8
    and    ecx, MASK
    xor    eax, [edi+4*ecx]
    _mov   ecx, esi
    _add   ecx, 2
    and    ecx, MASK
    xor    eax, [edi+4*ecx]
    _mov   ecx, esi
    xor    eax, [edi+4*ecx]
    rol    eax, 1
    _mov   ecx, esi
    _mov   [edi+4*ecx], eax

  .SKIP:
    _mov   eax, [edi-20]  ; same as _mov eax, [A]
    rol    eax, 5
    add    eax, [edi-4]   ; same as add eax, [E]
    _mov   ecx, esi
    add    eax, [edi+4*ecx]
    cmp    ebx, byte 60
    jb     short .LESSTHAN60
    _add   eax, K3
    push   ebx            ; save counter before it is destroyed by call to F2
    call   F2
    jmp    short .CONTINUE

  .LESSTHAN60:
    cmp    ebx, byte 40
    jb     short .LESSTHAN40
    _add   eax, K2
    push   ebx            ; save counter before it is destroyed by call to F3
    call   F3
    jmp    short .CONTINUE

  .LESSTHAN40:
    cmp    ebx, byte 20
    jb     short .LESSTHAN20
    _add   eax, K1
    push   ebx            ; save counter before it is destroyed by call to F2
    call   F2
    jmp    short .CONTINUE

  .LESSTHAN20:
    _add   eax, K0
    push   ebx            ; save counter before it is destroyed by call to F1
    call   F1

  .CONTINUE:
    add    eax, edx
    push   eax            ; a = temp; save it

; We use the following facts:
; W = edi, E = edi-4, D = edi-8, C = edi-12,
; B = edi-16, A = edi-20, HH4 = edi-32,
; HH3 = edi-36, HH2 = edi-40, HH1 = edi-44,
; HH0 = edi-48

    _mov   eax, [edi-8]
    _mov   [edi-4], eax   ; [E] <- [D]
    _mov   eax, [edi-12]
    _mov   [edi-8], eax   ; [D] <- [C]
    _mov   eax, [edi-16]
    rol    eax, 30
    _mov   [edi-12], eax  ; [C] <- [B]
    _mov   eax, [edi-20]
    _mov   [edi-16], eax  ; [B] <- [A]
    pop    eax            ; revive temp
    _mov   [edi-20], eax  ; [A] <- temp
    pop    ebx            ; revive counter
    inc    ebx
    cmp    ebx, byte 80
    jb     near .LOOP1
    _mov   eax, [edi-20]
    add    [edi-48], eax  ; [HH0] += [A]
    _mov   eax, [edi-16]
    add    [edi-44], eax  ; [HH1] += [B]
    _mov   eax, [edi-12]
    add    [edi-40], eax  ; [HH2] += [C]
    _mov   eax, [edi-8]
    add    [edi-36], eax  ; [HH3] += [D]
    _mov   eax, [edi-4]
    add    [edi-32], eax  ; [HH4] += [E]
    popa
    ret

INIT_BUFFER:
    _mov   edi, buffer
    xor    eax, eax
    _mov   ecx, BUFSIZE/4
    rep    stosd
    ret

INIT_W:
    _mov   edi, W
    push   eax
    xor    eax, eax
    _mov   ecx, BLOCKSIZE/4   ; transfer is done 4 bytes at a time
    rep    stosd              ; always initialize W first before filling
    pop    eax
    ret

; +-------------------------------------------------+
; | Input: esi = buffer                             |
; | Output: edi = W                                 |
; +-------------------------------------------------+

TRANSFER:
    call   INIT_W
    sub    edi, byte BLOCKSIZE  ; same as _mov edi, W
    _mov   ecx, BLOCKSIZE/4   ; transfer is done 4 bytes at a time
    push   eax

  BYTE_REVERSE:
    lodsd
    bswap  eax            ; store in big-endian orientation
    stosd                 ; transfer contents of buffer to W
    loop   BYTE_REVERSE
    pop    eax
    ret

; +-------------------------------------------------+
; | Upon entry:                                     |
; |     eax = number of bytes read into buffer      |
; | On exit:                                        |
; |     ecx = number of bytes read into buffer      |
; +-------------------------------------------------+

SHA1_UPDATE:
    add    [LoPart], eax
    _mov   esi, buffer
    _mov   byte[esi+eax], INIT_PAD
    _mov   ecx, eax       ; save number of bytes read
    push   ecx            ; save number of bytes read

  UPD_LOOP:
    call   TRANSFER
    cmp    eax, byte BLOCKSIZE
    jb     short PARTIALBLOCK
    call   SHA1_TRANSFORM      ; full block
    sub    eax, byte BLOCKSIZE
    test   eax, eax
    jz     short BLOCK_EMPTY
    jmp    short UPD_LOOP

  PARTIALBLOCK:
    cmp    eax, byte BLOCKSIZE-8  ; not counting 8 bytes for HiPart & LoPart
    jb     short FIN
    call   SHA1_TRANSFORM    ; process partial block containing
                             ; 56 - 63 bytes, inclusive
  BLOCK_EMPTY:
    call   INIT_BUFFER    ; re-initialize buffer with zeroes
    call   INIT_W         ; re-initialize W with zeroes

FIN:
    pop    ecx
    ret

UDATASEG

name    resd  1           ; filename
HH0     resd  1
HH1     resd  1
HH2     resd  1
HH3     resd  1
HH4     resd  1
HiPart  resd  1
LoPart  resd  1
A       resd  1
B       resd  1
C       resd  1
D       resd  1
E       resd  1
W       resd  15
t       resd  1           ; also doubles as the last element of W
buffer  resb  BUFSIZE

END
