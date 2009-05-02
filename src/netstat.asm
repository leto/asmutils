;; netstat for asmutils
;; Copyright (C) 2002 by Scott Lanning,
;; under the GNU General Public License. No warranty.
;; Usage: netstat [-latuw] [--unix] [--inet] [--ipx]
;; -l = show listening (servers) only
;; -a = show both listening and non-listening
;; If neither of -l or -a is given, only non-listening sockets are shown.
;; -t = show TCP
;; -u = show UDP
;; -w = show raw
;; If none of -t, -u, or -w is given, all three are shown.
;; Those options could be separate (-a -t -p) or combined (-atp).
;; --unix = show AF_UNIX sockets
;; --inet = show AF_INET sockets
;; --ipx = show AF_IPX sockets
;; If none of those options is given, all three are shown.
;; Notes:
;;	1) There is an implicit -n option.
;;	2) Recv-Q and Send-Q fields are omitted. (should be added?)
;;      3) Unix 'Path' field is truncated to 22 bytes.
;;	4) Doesn't handle IPv6.
;; TODO:
;;	Add more options (-p, -c, -e...)
;;      Decrease executable size... :/
;;
;; $Id: netstat.asm,v 1.1 2002/03/15 19:40:10 konst Exp $

%include "system.inc"

;; I never use IPX, so IPX is conditionally assembled,
;; and it only prints the raw /proc/net/ipx output.
;; (I didn't even try to do AX25, netrom, ...)
;; '%define IPX' if you want this minimal IPX support
;; and about 100 more bytes.

%undef IPX


CODESEG

%define BUFSIZE 4096
%define LINESIZE 256

;; "protocol offsets"
%define TCP_OFFSET 0
%define UDP_OFFSET 1
%define RAW_OFFSET 2
%define UNIX_OFFSET 3
%define IPX_OFFSET 4

procnet_file:
	;; AF_INET
.tcp	db '/proc/net/tcp',  0
.udp	db '/proc/net/udp',  0
.raw	db '/proc/net/raw',  0
	;; AF_UNIX
.unix	db '/proc/net/unix', 0
%ifdef	IPX
	;; AF_IPX
.ipx	db '/proc/net/ipx',  0
%endif

proto_str:
.tcp	db	'tcp   '
.udp	db	'udp   '
.raw	db	'raw   '
.unix	db	'unix  '
%ifdef	IPX
.ipx	db	'ipx   '
%endif

inet_label	db 'Active Internet connections'
	inet_label_len	equ	$ - inet_label
unix_label	db 'Active UNIX domain sockets'
	unix_label_len	equ	$ - unix_label
%ifdef	IPX
ipx_label	db 'Active IPX sockets'
	ipx_label_len	equ	$ - ipx_label
%endif

listening_only_label	db	' (only servers)', __n
	listening_only_label_len equ $ - listening_only_label
nonlistening_only_label	db	' (w/o servers)', __n
	nonlistening_only_label_len equ $ - nonlistening_only_label
alllistening_label	db	' (servers and established)', __n
	alllistening_label_len equ $ - alllistening_label

inet_header:
.proto	db	'Proto '
	proto_str_len	equ	$ - inet_header
.local_address	db	'Local Address           '
	addr_buf_len	equ	$ - inet_header.local_address
.foreign_address	db	'Foreign Address         '
.state	db	'State       '
	inet_state_len	equ	$ - inet_header.state
	db	__n
	inet_header_len	equ	$ - inet_header

unix_header:
	;; XXX: must be same length as inet_header.proto
.proto	db	'Proto '
;;	proto_str_len	equ	$ - unix_header
.refcnt	db	'RefCnt '
	refcnt_len	equ	$ - unix_header.refcnt
.flags	db	'Flags       '
	flags_len	equ	$ - unix_header.flags
.type	db	'Type       '
	type_len	equ	$ - unix_header.type
.state	db	'State         '
	unix_state_len	equ	$ - unix_header.state
.inode	db	'I-Node '
	inode_len	equ	$ - unix_header.inode
.path	db	'Path                  '
	path_len	equ	$ - unix_header.path
	db	__n
	unix_header_len	equ	$ - unix_header

inet_state:
	;; inet_state_len in inet_header
	db	'            '	; TCP close == UDP ""
	db	'ESTABLISHED '	; state numbers start at 1
	db	'SYN_SENT    '
	db	'SYN_RECV    '
	db	'FIN_WAIT1   '
	db	'FIN_WAIT2   '
	db	'TIME_WAIT   '
.close	db	'CLOSE       '
	db	'CLOSE_WAIT  '
	db	'LAST_ACK    '
	db	'LISTEN      '
	db	'CLOSING     '

unix_state:
	;; unix_state_len in unix_header
	db	'FREE          '	; SS_FREE == 0
	;; if (state==SS_UNCONNECTED && flags==SO_ACCEPTCON)
	;; (leave blank otherwise)
.listening	db	'LISTENING     '	; SS_UNCONNECTED
	db	'CONNECTING    '	; SS_CONNECTING
	db	'CONNECTED     '	; SS_CONNECTED
	db	'DISCONNECTING '	; SS_DISCONNECTING
unix_flags:
.so_acceptcon	db	'ACC '
	flags_acceptcon_len	equ	$ - unix_flags.so_acceptcon
.so_waitdata	db	'W '
	flags_waitdata_len	equ	$ - unix_flags.so_waitdata
.so_nospace	db	'N '
	flags_nospace_len	equ	$ - unix_flags.so_nospace
unix_type:
.SOCK_STREAM	db	'STREAM     '	; SOCK_STREAM == 1
.SOCK_DGRAM	db	'DGRAM      '
.SOCK_RAW	db	'RAW        '
.SOCK_RDM	db	'RDM        '
.SOCK_SEQPACKET	db	'SEQPACKET  '


%define	CLOSE		7
%define	LISTENING	10
%define SS_UNCONNECTED	1
%define SO_ACCEPTCON	1<<16
%define SO_WAITDATA	1<<17
%define SO_NOSPACE	1<<18

%define INET_LINE	0
%define UNIX_LINE	1
%define	IPX_LINE	2


START:
	pop	ebx		; argc
	dec	ebx
	jz	.done_reading_options

	pop	ebx		; ignore argv[0]
.next_argv:
	pop	ebx
	or	ebx, ebx
	jz	.done_reading_options

	cmp	byte [ebx], '-'
	jnz	.next_argv	; skip args with no leading dash
	inc	ebx
	cmp	byte [ebx], '-'
	jz	.process_double_dash
.process_single_dash:
	call	do_single_dash_opts
	jmp	.next_argv
.process_double_dash:
	inc	ebx
	call	do_double_dash_opts
	jmp	.next_argv

.done_reading_options:
	call	finish_opt_state

;;; AF_INET
show_inet_title:
	cmp	byte [show_inet_p], 0
	;; XXX: it's almost too far to jump to show_unix_title...
	je	show_unix_title

	_mov	ecx, inet_label
	_mov	edx, inet_label_len
	call	show_title
	sys_write STDOUT, inet_header, inet_header_len

	call	show_inet

;;; AF_UNIX
show_unix_title:
	cmp	byte [show_unix_p], 0
%ifdef	IPX
	je	show_ipx_title
%else
	je	exit
%endif

	mov	ecx, unix_label
	mov	edx, unix_label_len
	call	show_title	
	sys_write STDOUT, unix_header, unix_header_len

show_unix:
	cmp	byte [show_unix_p], 0
%ifdef	IPX
	je	show_ipx
%else
	je	exit
%endif

	_mov	ecx, proto_str_len
	_mov	esi, proto_str.unix
	_mov	edi, unix_line.proto
	rep	movsb
;	call	update_proto_field
	_mov	ebx, procnet_file.unix
	_mov	edi, parse_unix_line	; parser function
	call	show_info

%ifdef	IPX
;;; AF_IPX
show_ipx_title:
	cmp	byte [show_inet_p], 0
	je	exit

show_ipx:
	cmp	byte [show_ipx_p], 0
	je	exit

	_mov	ecx, proto_str_len
	_mov	esi, proto_str.ipx
	_mov	edi, ipx_line.proto
	rep	movsb
;	call	update_proto_field

	_mov	ebx, procnet_file.ipx
	;; If IPX is implemented, this should be changed to
	;; _mov ecx, parse_ipx_line
	;; call show_info
	call	show_unparsed_info
%endif

	;; drop through to exit
exit:
	sys_exit


do_single_dash_opts:
;; Do processing for single dash (-) command-line options.
;; Sets predicate variables: show_listening_p, show_nonlistening_p,
;; a_flag_present_p, show_tcp_p, show_udp_p, show_raw_p, show_pid_p.
;; Requires ebx to point after the dash.
	push	eax
	push	ecx
	;; Six possible options. (Note: if user enters something
	;; like -aaatauw, the characters after the 6th one are ignored)
	_mov	ecx, 6
	dec	ebx
.check_next_character:
	inc	ebx
.check_null:
	cmp	byte [ebx], 0
	je	.ret_single
.check_a:
	cmp	byte [ebx], 'a'
	jnz	.check_l
	inc	byte [a_flag_present_p]
	mov	byte [show_listening_p], LISTENING
	inc	byte [show_nonlistening_p]
%if	__OPTIMIZE__ != __O_SIZE__
	loop	.check_next_character
%endif
.check_l:
	cmp	byte [ebx], 'l'
	jnz	.check_t
	;; Test if we already found an -a flag.
	cmp	byte [a_flag_present_p], 0
	test	eax, eax
	jnz	.check_t	; skip -l, we already found -a
	mov	byte [show_listening_p], LISTENING
	mov	byte [show_nonlistening_p], 0
%if	__OPTIMIZE__ != __O_SIZE__
	loop	.check_next_character
%endif
.check_t:
	cmp	byte [ebx], 't'
	jnz	.check_u
	inc	byte [show_tcp_p]
	inc	byte [tuw_flag_present_p]
%if	__OPTIMIZE__ != __O_SIZE__
	loop	.check_next_character
%endif
.check_u:
	cmp	byte [ebx], 'u'
	jnz	.check_w
	inc	byte [show_udp_p]
	inc	byte [tuw_flag_present_p]
%if	__OPTIMIZE__ != __O_SIZE__
	loop	.check_next_character
%endif
.check_w:
	cmp	byte [ebx], 'w'
	jnz	.check_p
	inc	byte [show_raw_p]
	inc	byte [tuw_flag_present_p]
%if	__OPTIMIZE__ != __O_SIZE__
	loop	.check_next_character
%endif
.check_p:
	cmp	byte [ebx], 'p'
	jnz	.no_pid
	inc	byte [show_pid_p]
.no_pid:
	loop	.check_next_character

.ret_single:
	pop	ecx
	pop	eax
	ret

do_double_dash_opts:
;; Do processing for double dash (--) command-line options.
;; Sets predicate variables: show_unix_p, show_ipx, show_inet.
;; Requires ebx to point after the dashes.
.check_unix:
	cmp	dword [ebx], 'unix'
%ifdef	IPX
	jnz	.check_ipx
%else
	jnz	.check_inet
%endif
	inc	byte [show_unix_p]
	inc	byte [family_flag_present_p]
%ifdef	IPX
.check_ipx:
	cmp	dword [ebx], 'ipx\0'
	jnz	.check_inet
	inc	byte [show_ipx_p]
	inc	byte [family_flag_present_p]
%endif
.check_inet:
	cmp	dword [ebx], 'inet'
	jnz	.ret_double
	inc	byte [show_inet_p]
	inc	byte [family_flag_present_p]
.ret_double:
	ret	

finish_opt_state:
	;; If none of -t,-u,-w given, show them all.
	cmp	byte [tuw_flag_present_p], 0
	jne	.tuw_flag_present
	inc	byte [show_tcp_p]
	inc	byte [show_udp_p]
	inc	byte [show_raw_p]
.tuw_flag_present:

	;; If none of -a or -l given, show non-listening only.
	cmp	byte [a_flag_present_p], 0
	jne	.all_flag_present
	cmp	byte [show_listening_p], 0
	jne	.listening_flag_present
	inc	byte [show_nonlistening_p]
.all_flag_present:
.listening_flag_present:

	;; If no double-dash flags given, show them all.
	cmp	byte [family_flag_present_p], 0
	jne	.family_flag_present
	inc	byte [show_unix_p]
	inc	byte [show_inet_p]
%ifdef	IPX
	inc	byte [show_ipx_p]
%endif
.family_flag_present:
	ret

show_title:
	;; Write "title" line above output for each address family.
	;; REQUIRES: ecx contains label, edx contains label length
	sys_write STDOUT, EMPTY, EMPTY

	cmp	byte [a_flag_present_p], 0
	je	.not_both_listening_inet
	sys_write STDOUT, alllistening_label, alllistening_label_len
	jmp	.ret_title
.not_both_listening_inet:
	cmp	byte [show_nonlistening_p], 0
	je	.not_nonlistening_inet
	sys_write STDOUT, nonlistening_only_label, nonlistening_only_label_len
	jmp	.ret_title
.not_nonlistening_inet:
	;; It must be listening-only, then.
	sys_write STDOUT, listening_only_label, listening_only_label_len

.ret_title:
	ret

show_inet:
.show_tcp:
	cmp	byte [show_tcp_p], 0
;	je	show_unix_title
	je	.show_udp

	_mov	ecx, proto_str_len
	_mov	esi, proto_str.tcp
	_mov	edi, inet_line.proto
	rep	movsb
;	call	update_proto_field

	_mov	ebx, procnet_file.tcp	; /proc/net/tcp
	_mov	edi, parse_inet_line	; parser function
	call	show_info

.show_udp:
	cmp	byte [show_udp_p], 0
;	je	show_unix_title
	je	.show_raw

	_mov	ecx, proto_str_len
	_mov	esi, proto_str.udp
	_mov	edi, inet_line.proto
	rep	movsb
;	call	update_proto_field

	_mov	ebx, procnet_file.udp
	_mov	edi, parse_inet_line	; parser function
	call	show_info

	;; Note: I didn't test raw sockets.
.show_raw:
	cmp	byte [show_raw_p], 0
	je	.ret_show_inet

	_mov	ecx, proto_str_len
	_mov	esi, proto_str.raw
	_mov	edi, inet_line.proto
	rep	movsb
;	call	update_proto_field

	_mov	ebx, procnet_file.raw
	_mov	edi, parse_inet_line	; parser function
	call	show_info

.ret_show_inet:
	ret

show_unparsed_info:
	;; Show information for IPX
	;; REQUIRES: ptr to /proc file in ebx
	sys_open EMPTY, O_RDONLY
	sys_read eax, buf, BUFSIZE
	sys_write STDOUT, buf, eax
	ret

show_info:
	;; Show socket information for TCP, UDP, raw, ...
	;; REQUIRES: ebx is ptr to filename, edi points
	;;     to the parsing function (parse_inet_line,parse_unix_line,...)
	pusha

	;; XXX: I tried to read chunks into a buffer then parse
	;; line-by-line, but... I suck.

	;; Read /proc/net/ file
	sys_open EMPTY, O_RDONLY	; finished with ebx now
	test	eax, eax
	js	.ret_show_info
	mov	ebx, eax
	;; .ret_show_info is too far to jump......
	call	process_lines

.ret_show_info:
	popa
	ret

process_lines:
	;; Read a line into 'line_buf'

.read_one_line:

	;; eek -- clear line_buf first (path field)
	pusha
	_mov	eax, ' '
	_mov	ecx, LINESIZE
	_mov	edi, line_buf
	rep	stosb
	popa

	_mov	esi, line_buf
.read_one_char:
	sys_read EMPTY, esi, 1
	cmp	eax, 0
	jle	.ret_dont_show
	lodsb
	cmp	eax, __n
	je	.parse
	jmp	.read_one_char

.parse:
	;; Skip the 1st line
	;; AF_INET
	cmp	dword [line_buf], '  sl'
	je	.read_one_line
	;; AF_UNIX
	cmp	dword [line_buf], 'Num '
	je	.read_one_line
%ifdef	IPX
	;; AF_IPX
	cmp	dword [line_buf], '????'
	je	.read_one_line
%endif

.not_skipping_header:
;	call	parse_inet_line
	;; This is confusing because edi is passed through
	;; several functions.. edi is a parser function:
	;; either parse_inet_line or parse_unix_line.
	call	edi
	call	print_one_line

	jmp	.read_one_line
.ret_dont_show:
	ret

print_one_line:
	;; Print line from the /proc file depending on the
	;; command-line flags.
	pusha

	;; if ((state == LISTENING || state == CLOSE
	;;	|| (state==unix_state.listening && flags==SO_ACCEPTCON))
	;;	&& show_listening_p)
	;; (this depends on LISTENING of TCP being larger than
	;; states in other protocols)
	cmp	byte [socket_state], LISTENING
	je	.is_listening

	;; What a tangled web I weave..
	;; Eek, if state==0, then it might be SS_FREE for AF_UNIX!
	;; Or it might be UDP CLOSE that I reset stupidly before.

	;; If proto unix is set, that means we must be processing
	;; unix because unix comes after inet.
	cmp	dword [unix_line.proto], 'unix'
	jne	.do_udp

	cmp	byte [socket_state], SS_UNCONNECTED
	jne	.not_listening
	_mov	ebx, dword [flags]
	and	ebx, SO_ACCEPTCON
	cmp	ebx, 0
	je	.not_listening
	jmp	.is_listening

.do_udp:
	;; (This case is the UDP equivalent to LISTENING)
;	cmp	byte [socket_state], CLOSE
	;; XXX:  D'OH! I reset that to zero if it's CLOSE....
	cmp	byte [socket_state], 0
	jne	.not_listening

.is_listening:	
	cmp	byte [show_listening_p], 0
	jne	.print_line
	jmp	.ret_print_one_line
.not_listening:
	;; if (show_nonlistening_p)
	cmp	byte [show_nonlistening_p], 0
	je	.ret_print_one_line

.print_line:
	
%ifdef	IPX
.print_ipx_line:
	cmp	byte [line_num], IPX_LINE
	jne	.print_inet_line
	_mov	ecx, ipx_line
	_mov	edx, ipx_line_len
	jmp	.finally_print_it
%endif
.print_inet_line:
	cmp	byte [line_num], INET_LINE
	jne	.print_unix_line
	_mov	ecx, inet_line
	_mov	edx, inet_line_len
	jmp	.finally_print_it
.print_unix_line:
	cmp	byte [line_num], UNIX_LINE
	jne	.print_nothing		; shouldn't happen
	_mov	ecx, unix_line
	_mov	edx, unix_line_len
	;; fall through
.finally_print_it:
	sys_write STDOUT, EMPTY, EMPTY
.print_nothing:

.ret_print_one_line:
	popa	
	ret	

parse_inet_line:
	;; Parse line_buf into inet_line struct.
	pusha

	;; set flag to indicate that the current line being
	;; parsed is an inet line (required later..)
	mov	byte [line_num], INET_LINE

	;; Clear inet_line
	_mov	eax, ' '
	;; don't clear the Proto field
	_mov	ecx, inet_line_clear_len
	_mov	edi, inet_line.local_address
	rep	stosb
	_mov	eax, __n
	stosb

	_mov	esi, line_buf

	;; Local address
	add	esi, proto_str_len	; offset of local address
	_mov	edi, inet_line.local_address
	call	hexintstr2ip

	_mov	eax, ':'
	stosb

	;; Local port
	inc	esi		; offset of local port
	call	hexwordstr2str

	;; Foreign address
	add	esi, 1		; offset of foreign address
	_mov	edi, inet_line.foreign_address
	call	hexintstr2ip

	_mov	eax, ':'
	stosb

	;; Foreign port
	inc	esi		; offset of foreign port
	call	hexwordstr2str

	;; State
	inc	esi
	call	hexbytestr2int
	_mov	[socket_state], eax

	;; Now move corresponding string into inet_line
	;; XXX: surely I'm doing this wrongly. Maybe make them
	;; into arrays of (char *), then access by index.
	mov	ecx, eax
	_mov	esi, inet_state

	;; If UDP, translate TCP_CLOSE to ""
	cmp	ecx, CLOSE
	jne	.next_state_offset
	;; check if it's UDP
	cmp	dword [inet_line.proto], 'udp '
	jne	.next_state_offset
	xor	ecx, ecx	; 0th state is blank for this reason
	_mov	[socket_state], ecx
	jmp	.udp_offset_set

.next_state_offset:
	add	esi, inet_state_len
	loop	.next_state_offset

.udp_offset_set:
	_mov	edi, inet_line.state
	_mov	ecx, inet_state_len
	rep	movsb

	popa
	ret

parse_unix_line:
	;; Parse line_buf into unix_line struct.
	pusha

	;; set flag to indicate that the current line being
	;; parsed is a unix line (required later..)
	mov	byte [line_num], UNIX_LINE

	;; Clear line
	_mov	eax, ' '
	;; don't clear the Proto field
	_mov	ecx, unix_line_clear_len
	_mov	edi, unix_line.refcnt
	rep	stosb

	_mov	eax, __n
	stosb

	_mov	esi, line_buf

	;; RefCnt
	add	esi, 10		; offset of refcnt
	_mov	edi, unix_line.refcnt
	call	hexintstr2str

	;; Flags
	add	esi, 10		; skip over Protocol (8 bytes + 2 spaces)
	call	hexintstr2int
	_mov	edi, flags
	stosd			; save for State field

	push	esi
	mov	ebx, eax	; save a copy
	_mov	edi, unix_line.flags
	_mov	ax, '[ '
	stosw

.so_acceptcon:
	mov	eax, ebx
	_mov	ecx, SO_ACCEPTCON
	and	eax, ecx
	cmp	eax, 0
	je	.so_waitdata
	_mov	esi, unix_flags.so_acceptcon
	_mov	ecx, flags_acceptcon_len
	rep	movsb
.so_waitdata:
	mov	eax, ebx
	_mov	ecx, SO_WAITDATA
	and	eax, ecx
	cmp	eax, 0
	je	.so_nospace
	_mov	esi, unix_flags.so_waitdata
	_mov	ecx, flags_waitdata_len
	rep	movsb
.so_nospace:
	mov	eax, ebx
	_mov	ecx, SO_NOSPACE
	and	eax, ecx
	cmp	eax, 0
	je	.last_flag
	_mov	esi, unix_flags.so_nospace
	_mov	ecx, flags_nospace_len
	rep	movsb
.last_flag:

	_mov	al, ']'
	stosb
	pop	esi

	;; Type
	inc	esi		; space
	call	hexwordstr2int
	push	esi
	;; Move corresponding string into unix_line
	mov	ecx, eax
	_mov	esi, unix_type
	sub	esi, type_len
.next_type_offset:
	add	esi, type_len
	loop	.next_type_offset

	_mov	edi, unix_line.type
	_mov	ecx, type_len
	rep	movsb
	pop	esi

	;; State
	inc	esi
	_mov	edi, unix_line.state
	call	hexbytestr2int
	_mov	[socket_state], eax

	push	esi
	;; special case: state==UNCONNECTED
	cmp	eax, SS_UNCONNECTED
	jne	.not_unconnected
	;; if (flags==SO_ACCEPTCON) state="LISTENING"
	_mov	ebx, dword [flags]
	and	ebx, SO_ACCEPTCON
	cmp	ebx, 0
	je	.not_listening
	_mov	esi, unix_state.listening
	jmp	.state_offset_set
.not_unconnected:
	
	;; Move corresponding string into unix_line
	mov	ecx, eax
	_mov	esi, unix_state
	sub	esi, unix_state_len
.next_state_offset:
	add	esi, unix_state_len
	loop	.next_state_offset

.state_offset_set:
	_mov	edi, unix_line.state
	_mov	ecx, unix_state_len
	rep	movsb
.not_listening:
	pop	esi

	;; inode -- copy directly
	;; XXX: I assumed the inode field in /proc/net/unix
	;; is always 5 chars long
	inc	esi
	_mov	edi, unix_line.inode
	inc	edi		; they spell it 'I-Node' for some reason...
	_mov	ecx, 5
	rep	movsb

	;; path -- copy directly (up to 22 bytes, but stop at newline)
	inc	esi
	_mov	edi, unix_line.path
	_mov	ecx, path_len
.next_path_char:
	lodsb
	cmp	al, __n
	je	.last_path_char
	stosb
	loop	.next_path_char
.last_path_char:

	popa	
	ret

%ifdef IPX
parse_ipx_line:
	;; set flag to indicate that the current line being
	;; parsed is an inet line (required later..)
	mov	byte [line_num], IPX_LINE

	ret
%endif

;;; Following are a bunch of conversion functions used to
;;; parse each line of input.

	;; The first two functions are "lowest-level" functions
	;; that move esi and edi as we parse the line_buf and put
	;; the result in inet_line/unix_line.

hexbytestr2int:
	;; Convert a 2-digit hex string to integer. ('7F' => 127)
	;; This is a lowest-level function, and it moves ESI.
	;; REQUIRES: esi points to high digit of hex string
	;; RETURNS: the integer in eax
	;; MODIFIES: esi points after the 2-digit hex string

	push	ebx
	push	ecx
	push	edx

	xor	eax, eax
	xor	ebx, ebx
	lodsw
	_mov	ecx, 2
	mov	ebx, eax
	and	ebx, 0x000000FF		; higher digit
.next_hex_digit:
	cmp	ebx, '9'
	jg	.hex_uppercase_letter
	sub	ebx, '0'
	jmp	.done_ascii	
.hex_uppercase_letter:
	cmp	ebx, 'Z'
	jg	.hex_lowercase_letter
	sub	ebx, 'A' - 10
	jmp	.done_ascii
.hex_lowercase_letter:
	sub	ebx, 'a' - 10
.done_ascii:

	dec	ecx
	cmp	ecx, 0
	je	.finish_last_digit

	shl	ebx, 4		; multiply by 16
	
	mov	edx, ebx
	;; now do lower-digit
	and	eax, 0x0000FF00
	shr	eax, 8

	mov	ebx, eax
	jmp	.next_hex_digit
.finish_last_digit:
	add	edx, ebx
	mov	eax, edx

	pop	edx
	pop	ecx
	pop	ebx
	ret

int2str:
	;; Print an integer as a decimal string
	;; REQUIRES: integer(dividend) in eax,
	;;	edx = 0 before calling (holds remainder),
	;; 	string destination in edi
	;; MODIFIES: edi

	push	eax
	push	ebx
	push	ecx
	push	edx

	or	eax, eax
	jnz	.keep_recursing
	;; special case of zero
	or	edx, edx
	jz	.write_remainder
	jmp	.break_recursion

.keep_recursing:
	mov	edx, 0
	mov	ebx, 10
	div	ebx

	call	int2str

.write_remainder:
	mov	eax, edx
	add	eax, '0'
	stosb

.break_recursion:
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	ret


	;; The next two functions use hexbytestr2int and int2str
	;; to parse hex strings in 2-digit pieces. They don't touch
	;; esi or edi themselves, but let the previous two functions
	;; take care of that.

hexwordstr2int:
	push	ebx
	push	edx

	call	hexbytestr2int
	shl	eax, 8
	mov	edx, eax
	call	hexbytestr2int
	add	edx, eax
	mov	eax, edx

	pop	edx
	pop	ebx
	ret	

hexwordstr2str:
	;; This is used to translate the port number from a (two-byte)
	;; hex string to an integer string.
	;; REQUIRES: ptr to hex word string (big-endian order) in esi,
	;; ptr to destination in edi
	;; RETURNS: integer string (little-endian order) at edi
	;; MODIFIES: edi
	push	eax
	push	edx
	call	hexwordstr2int
	_mov	edx, 0
	call	int2str
	pop	edx
	pop	eax
	ret

hexintstr2str:
	;; This is used to translate a 4-byte hex string
	;; to an integer string. Similar to hexwordstr2str.
	;; REQUIRES: ptr to hex word string (big-endian order) in esi,
	;; ptr to destination in edi
	;; RETURNS: integer string (little-endian order) in edi
	;; MODIFIES: edi
	push	eax
	push	ebx
	push	edx

	call	hexintstr2int

	_mov	edx, 0
	call	int2str

	pop	edx
	pop	ebx
	pop	eax	
	ret

hexintstr2ip:
	;; Take a four-byte hex string like '0100007F' and turn it
	;; into an ascii IP address like '127.0.0.1'.
	;; REQUIRES: esi is ptr to beginning of hex string
	;; and edi is ptr to place to write the result

	push	eax
	push	edx

	call	hexintstr2int

	;; Now convert the network-order integer to an ascii string.
	_mov	[ip_number], edx

	push	esi
	_mov	esi, ip_number
	call	int2ip
	pop	esi

	pop	edx
	pop	eax
	ret

hexintstr2int:
	;; REQUIRES: esi points to source hex int string
	call	hexbytestr2int
	mov	edx, eax
	shl	edx, 24
	call	hexbytestr2int
	shl	eax, 16
	add	edx, eax
	call	hexbytestr2int
	shl	eax, 8
	add	edx, eax
	call	hexbytestr2int
	add	edx, eax
	mov	eax, edx
	ret

int2ip:
	;; Convert a network-order integer into an IP address ("127.0.0.1").
	;; REQUIRED: esi points to the integer, edi points to result string
	;; RETURNS: IP string at edi
	push	eax
	push	ebx
	push	ecx
	push	edx

	_mov	ecx, 4		; over 4 bytes
	_mov	eax, 0
.ntoipl_next_byte:
	lodsb
	_mov	edx, 0		; for int2str
	call	int2str

	dec	ecx
	cmp	ecx, 0
	je	.done_ip
	_mov	eax, '.'
	stosb
	jmp	.ntoipl_next_byte

.done_ip:
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	ret

	
UDATASEG

;;; These options are implicitly off (zero) by default.
show_pid_p		resb	1
show_route_p		resb	1
show_listening_p	resb	1
show_nonlistening_p	resb	1
a_flag_present_p	resb	1
show_unix_p		resb	1
show_inet_p		resb	1
%ifdef	IPX
show_ipx_p		resb	1
%endif
family_flag_present_p	resb	1
show_tcp_p		resb	1
show_udp_p		resb	1
show_raw_p		resb	1
tuw_flag_present_p	resb	1

buf			resb	BUFSIZE
line_buf		resb	LINESIZE
addr_buf		resb	addr_buf_len

	;; /proc/net/tcp
;  sl  local_address rem_address   st tx_queue rx_queue tr tm->when retrnsmt   uid  timeout inode                                                     
;   0: 0100007F:0019 00000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0 916 1 d70d0540 300 0 0 2 -1                               
	;; /proc/net/udp
;  sl  local_address rem_address   st tx_queue rx_queue tr tm->when retrnsmt   uid  timeout inode                               
;  28: 00000000:039C 00000000:0000 07 00000000:00000000 00:00000000 00000000     0        0 874 2 d70d0080                      

inet_input_line:
	;; sizes include trailing space (or colon)
.sl			resb	6
.local_address		resb	14
.rem_address		resb	14
.st			resb	3
.tx_queue		resb	9
.rx_queue		resb	9
.tr			resb	3
.tm_when		resb	9
.retrnsmt		resb	9
.uid			resb	6
.timeout		resb	9
.inode			resb	59 ; tcp = 59, udp = 37...
inet_input_line_len	equ	$ - inet_input_line

inet_line:
.proto			resb	proto_str_len
.local_address		resb	addr_buf_len
.foreign_address	resb	addr_buf_len
.state			resb	inet_state_len
inet_line_clear_len	equ	$ - inet_line.local_address
.lf			resb	1
inet_line_len	equ	$ - inet_line

unix_line:
.proto			resb	proto_str_len
.refcnt			resb	refcnt_len
.flags			resb	flags_len
.type			resb	type_len
.state			resb	unix_state_len
.inode			resb	inode_len
.path			resb	path_len
unix_line_clear_len	equ	$ - unix_line.refcnt
.lf			resb	1
unix_line_len	equ	$ - unix_line

%ifdef	IPX
ipx_line:
ipx_line_len	equ	$ - ipx_line
%endif

socket_state		resb	1
ip_number		resd	1
line_num		resb	1
flags			resd	1
	
END
