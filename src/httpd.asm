;Copyright (C) 1999-2002 Indrek Mandre <indrek@mare.ee>
;			 Konstantin Boldyshev <konst@linuxassembly.org>
;			 Rudolf Marek <marekr2@fel.cvut.cz>
;
;$Id: httpd.asm,v 1.23 2006/02/06 06:03:39 konst Exp $
;
;hackers' sub-1K httpd
;
;syntax: httpd document-root port [logfile [err404file] | err404file]
;
;example:	httpd /htdocs/ 8888
;		lynx http://localhost:8888/
;
;		httpd /htdocs/ 8888 /htdocs/httpd.log /htdocs/404.html
;
; - when / is the last symbol in request, appends index.html
; - in case of error just closes connection
; - takes 16kb + 16kb for every request in memory, forks on every request,
; - good enough to serve basic documentation.
;
;I tried to make it as secure as possible, there should be no buffer overflows.
;I at least tried not to make any. It ignores requests with included '..'.
;Here I did a bit testing and it served about 214.8688524590 pages per second.
;Perhaps I am wrong though, but this was the statistics :)
;
;Note that starting from version 0.02 IM no longer maintains httpd.
;Actually it was heavily rewritten since 0.04 and is now maintained by KB;
;however you can still find original IM code and notes throughout the source.
;
;0.01: 17-Jun-1999	initial release (IM)
;0.02: 04-Jul-1999	fixed bug with 2.0 kernel, minor changes (KB)
;0.03: 29-Jul-1999	size improvements (KB)
;0.04: 09-Feb-2000	portability fixes (KB)
;0.05: 25-Feb-2000	heavy rewrite of network code, size improvements,
;			portability fixes (KB)
;0.06: 05-Apr-2000	finally works on FreeBSD! (KB)
;0.07: 30-Jun-2000	added support for custom 404 error message,
;			enabled by %define ERR404 (KB)
;			thanks to Mooneer Salem <mooneer@earthlink.net>
;0.08: 10-Sep-2000	squeezed few more bytes (KB)
;0.09: 16-Jan-2001	added support for "Content-Type: text/plain"
;			for .text, .txt, .log and no-extension files,
;			enabled by %define SENDHEADER (KB)
;0.10  10-Jan-2002      added logging (IP||HEADER),
;			added err404file command line argument,
;			more content types (RM),
;			added extension-content type table,
;			fixed infinite loop if err404file is missing,
;			size improvements (KB)
;0.11  14-Mar-2002      added initial cgi support (SL),
;			'%' support in filenames (RM),
;			send default mimetype for unknown extensions (KB)
;0.12  30-Aug-2002	no longer runs as root if UID defined (JH)
;			fixed cgi build problem, sendfile support (saved 21 bytes) (RM)

%include "system.inc"

;Most useful option is SENDHEADER. It could be implemented using external file
;(like usual http servers do), but static implementation has advantages too.
;
;when both LOG and ERR404 are enabled:
;	logfile is 3rd command-line argument and err404file is 4th
;when only one of {LOG,ERR404} is enabled:
;	corresponding filename is 3rd command-line argument
;So, you must know compile-time configuration, but eventually
;this will be rewritten in a more suitable manner.

;There is a %define variable "CGI" to enable httpd to execve CGI scripts.
;There are some assumptions. Currently, it assumes the file is named ".cgi"
;and in the HTML document root with the other HTML files.
;Probably there should be a separate cgi-bin directory.
;The stdin/stdout of the script will be the socket fd.
;I put an empty environment list. There is no POST method yet;
;in case it is developed, then the data from POST body is passed
;to environment variables perhaps. There are several other environment
;variables for CGI as well, such as HTTP_REFERER, etc..
;Another assumption so far is the server assumes the output is HTML.
;I let the header be sent by the server, but usually the CGI script
;sends its own headers. I think this is easy enough to fix.

;%define	SENDHEADER
;%define	LOG
;%define	ERR404
;%define	CGI
;%define	PROC_HANDLE	;%
;%define UID	99

%ifdef	LOG
%define	LOG_HEADER
;%define	LOG_DEBUG
%endif

%ifdef  __LINUX__
    %if __KERNEL__ >=22
    %define USE_SENDFILE
    %endif
%endif

CODESEG

index_file	db	"index.html"	;must not exceed 10 bytes!

setsockoptvals	dd	1

START:
	pop	ebp
	cmp	ebp,byte 3	;at least 2 arguments must be there
%ifdef ERR404
	jb	near false_exit
%else
	jb	false_exit
%endif
	pop	esi		;our own name

	pop	dword [root]	;document root
	pop	esi		;port number

	xor	eax,eax
	xor	ebx,ebx
.n1:
	lodsb
	sub	al,'0'
	jb	.n2
	cmp	al,9
	ja	.n2
	imul	ebx,byte 10
	add	ebx,eax
	jmps	.n1
.n2:
	xchg	bh,bl		;now save port number into bindsock struct
	shl	ebx,16
	mov	bl,AF_INET	;if (AF_INET > 0xff) mov bx,AF_INET
	mov	[bindsockstruct],ebx
	
%ifdef LOG
	sub	ebp,byte 3
	jz	.begin
%elifdef ERR404
	sub	ebp,byte 3
	jz	.begin
%endif

%ifdef LOG
	pop	eax
	sys_open eax,O_WRONLY|O_APPEND|O_CREAT,S_IRUSR|S_IWUSR
	test	eax,eax
	js	.l0
	mov	[logfd],eax
.l0:
%ifdef ERR404
	dec	ebp
	jz	.l4
%endif
%endif

%ifdef ERR404
	pop	esi
	or	esi,esi
	jz	.l4
	mov	[err404],esi
	mov	ecx,esi
.l2:
	lodsb
	or	al,al
	jnz	.l2
	sub	esi,ecx
	dec	esi
	jz	.l4
	inc	esi
	mov	[err404len],esi
.l4:
%endif

.begin:
	sys_socket PF_INET,SOCK_STREAM,IPPROTO_TCP
	test	eax,eax
	js	false_exit

	xchg	ebp,eax		;socket descriptor

	sys_setsockopt ebp,SOL_SOCKET,SO_REUSEADDR,setsockoptvals,4
	or	eax,eax
	jz	do_bind

false_exit:
	_mov	ebx,1
real_exit:
	sys_exit

do_bind:
	sys_bind ebp,bindsockstruct,16	;bind(s, struct sockaddr *bindsockstruct, 16)
	or	eax,eax
	jnz	false_exit

	sys_listen ebp,5		;listen(s, 5)
	or	eax,eax
	jnz	false_exit

%ifdef UID
	sys_setgid	UID
	sys_setuid
%endif
	sys_fork			;fork after everything is done and exit main process
	or	eax,eax
	jz	acceptloop

true_exit:
	_mov	ebx,0
	jmps	real_exit

acceptloop:
	mov	[arg2],byte 16		;sizeof(struct sockaddr_in)
	sys_accept ebp,arg1,arg2	;accept(s, struct sockaddr *arg1, int *arg2)
	test	eax,eax
	js	acceptloop
	xchg	edi,eax			;our descriptor

;wait4(pid, status, options, rusage)
;there must be 2 wait4 calls! Without them zombies can stay on the system

	sys_wait4	0xffffffff,NULL,WNOHANG,NULL
	sys_wait4

%ifdef LOG
;	mov	edx,arg3
;        mov	byte [edx],0x10
;	sys_getpeername edi,filebuf,arg3
	mov	eax,[arg1+4]
	push	edi
	mov	edi,filebuf+020
	mov	esi,edi
	xchg	ah,al		
	ror	eax,16
	xchg	ah,al
	call	i2ip
	sub	esi,edi
	inc	edi
	mov	ebx,eax
	sys_write [logfd],edi,esi
	pop	edi
%endif

	sys_fork		;we now fork, child goes his own way, daddy goes back to accept
	or	eax,eax
	jz	.forward
	sys_close edi
	_jmp	acceptloop
.forward:
	sys_read edi,filebuf,0xfff
	cmp	eax,byte 7	;there must be at least 7 symbols in request 
	jb	near endrequest
.endrequestnot3:
	push	eax
%ifdef LOG_HEADER
	sys_write [logfd],filebuf,eax
%endif
	mov	ebx,finalpath
	mov	ecx,[root]
	mov	edx,ecx
.back:
;first, copy the document root
	mov	al,[ecx]
	mov	byte [ebx],al
	inc	ebx
	inc	ecx
	cmp	byte [ecx],0
	jne	.back

	sub	ecx,edx
	pop	eax
	add	ecx,eax
	cmp	ecx,0xfff
	ja	near endrequest

.endrequestnot2:

;now append the demanded

	mov	ecx,filebuf+4	;past "GET "
.loopme:
	cmp	word [ebx-2],".."
	jz	near endrequest	;security error, can't have '..' in request
.endrequestnot:
	mov	dl,[ecx]
;
;"With PROC_HANDLE defined, paths with %20's in will cause erroneous 404 messages"
	cmp	dl,' '
	jz	.loopout		; (rhs) Check if end of f'req.
; We HAVE to check for a space HERE, because if we do so in the old place,
; paths with %20's in'em will cause a bad 404 with PROC_HANDLE on.

%ifdef	PROC_HANDLE
	cmp	dl,'%'
	jnz	.not_proc
	call	convert_into_dl
.not_proc:
%endif
	mov	[ebx],dl
	or	dl,dl
	je	.loopout
	cmp	dl,' '
%ifdef CGI
	jb	toentrequest
%else
	jb	endrequest
%endif
	jz	.loopout
	cmp	dl,'?'
	jz	.loopout
	cmp	dl,0xd
	jz	.loopout
	cmp	dl,0xa
	jz	.loopout
	inc	ebx
	inc	ecx
	jmps 	.loopme
.loopout:
	mov	byte [ebx],0
	cmp	byte [ebx-1],'/'
	jne	index
	mov	eax,index_file		;move 10 bytes through FPU stack
	fld	tword [eax]
	fstp	tword [ebx]
;	mov	dword [ebx],"inde"	;append index.html :)
;	mov	dword [ebx+4],"x.ht"
;	mov	word [ebx+8],"ml"
index:
%ifdef LOG_DEBUG
	mov	ecx,finalpath
	sub	ebx,ecx
	sys_write [logfd],EMPTY,ebx
%endif

	sys_open finalpath,O_RDONLY
	test	eax,eax
%ifdef	ERR404
	js	error404
%else
	js	endrequest
%endif

%ifdef SENDHEADER
	call	sendheader
%endif

%ifdef CGI
	;; If filename ends ".cgi", sys_execve it
	push	edi
	push	eax
	_mov	edi,finalpath
	_mov	ecx,0xfff	;0xfff is max filename size
	_mov	eax,0
	repne	scasb		;find '\0' after URI
	sub	edi,byte 5	;".cgi\0"
	mov	ebx,edi
	pop	eax
	pop	edi

	cmp	dword [ebx],".cgi"
	jnz	sendnoncgi
	call	execcgi
toentrequest:
	jmp	endrequest	;should log error instead
sendnoncgi:
%endif

	mov	ebx,eax
	mov	esi,eax
	mov	ecx,filebuf
%ifdef USE_SENDFILE
;sendfile(int out_fd, int in_fd, off_t *offset, size_t count);
        push byte 0 ;we can leave this on stack
        sys_sendfile edi,eax,esp,0xffffffff  ;Linux 2.2+ support this
        sys_close ecx
%else
.writeloop:
	sys_read EMPTY,EMPTY,0xfff
	test	eax,eax
	js	.endread

	sys_write edi,EMPTY,eax
	mov	ebx,esi
	test	eax,eax
	jz	.endread
	jns	.writeloop
.endread:
	sys_close
%endif
;due the stupidity of netscape we need to send another packet newline \n,
;so it can handle one line data but I'm afraid it might break something,
;so watch this code carefully in the future
;	sys_write edi,nl,1

endrequest:
;	sys_read ebp,filebuf,0xff
;	sys_shutdown ebp,1		;shutdown(sock, how)
;	sys_close ebp
	jmp	true_exit

;nl	db	0xa

%ifdef	ERR404
error404:
	pusha
	mov	ecx,[err404len]
	or	ecx,ecx
	jz	.end

	mov	esi,[err404]
	mov	edi,finalpath

	push	ecx		;save values
	push	esi
	push	edi
	
	rep	cmpsb		;check if we can't open ourself
	jz	.end0

	pop	edi
	pop	esi
	pop	ecx
	rep	movsb		;copy to finalpath

	popa
	jmp	index

.end0:
	add	esp,byte 4*3
.end:
	popa
	jmp	endrequest

%endif

%ifdef	LOG
i2ip:
	std
	mov	byte [edi],__n
	dec	edi
.next:	
	mov	ebx,eax
	call	.conv
	xchg	eax,ebx
	mov	al,'.'
	stosb
	shr	eax,8
	jnz	.next
	cld
	inc	edi
	mov	byte [edi],' '
	ret
.conv:
	mov	cl,010
.divide:
	xor	ah,ah	
	div	cl     ;ah=reminder
	xchg	ah,al
	add	al,'0'
	stosb	
	xchg	ah,al
	or	al,al
	jnz	.divide
	ret
%endif

%ifdef	SENDHEADER

h1	db	"HTTP/1.1 200 OK",__n
	db	"Server: asmutils httpd",__n
	db      "Content-Type: "
_lenh1	equ	$ - h1
%assign	lenh1 _lenh1

c_plain	db	"text/plain",EOL
c_html	db	"text/html",EOL
c_jpeg	db	"image/jpeg",EOL
c_png	db	"image/png",EOL
c_gif	db	"image/gif",EOL
c_def	db	"application/octet-stream",EOL

ending	db	__n,__n

extension_tab:
	dd	"text",	c_plain
	dd	"txt",	c_plain
	dd	"log",	c_plain
	dd	"html",	c_html
	dd	"htm",	c_html
	dd	"jpeg",	c_jpeg
	dd	"jpg",	c_jpeg
	dd	"png",	c_png
	dd	"gif",	c_gif
%ifdef	CGI
	dd	"cgi",	c_html
%endif
	dd	0,	c_def

sendheader:
	pusha

	mov	esi,finalpath
	mov	ebx,esi
.cc1:
	lodsb
	or	al,al
	jnz	.cc1
.cc2:
	dec	esi
	cmp	esi,ebx
	jz	.return0
	cmp	byte [esi],'.'
	jnz	.cc2
.return0:
	mov	eax,[esi + 1]
	mov	edx,extension_tab - 8
.cc3:
	add	edx,byte 8
	mov	ecx,[edx]
	or	ecx,ecx
	jz	.write_content
	cmp	eax,ecx
	jnz	.cc3

.write_content:

	push	edx
	sys_write edi,h1,lenh1	;header
	pop	edx

	mov	ecx,[edx + 4]
	mov	edx,ecx
	dec	edx
.cc5:
	inc	edx
	cmp	[edx],byte EOL
	jnz	.cc5

	sub	edx,ecx
	
	sys_write		;write content type
	sys_write EMPTY,ending,2

.return:
	popa
	ret

%endif

%ifdef CGI
execcgi:
	pusha
	;; Make the socket stdin/stdout for the CGI program
	sys_dup2 edi,STDIN
	sys_dup2 EMPTY,STDOUT
	sys_close
	;; Execute the CGI program.
	;; argv[0] is finalpath and env is NULL. (?)
	mov	eax,finalpath
	mov	ecx,execve_argv
	mov	[ecx],eax
	sys_execve [ecx],ecx,0
	;; Hopefully we don't get here
	popa
	ret
%endif		

%ifdef PROC_HANDLE
;ecx - source % in our case
convert_into_dl:
		push 	eax
		inc 	ecx
		xor 	eax,eax
		xor	edx,edx
		mov 	al,[ecx]
		call	.check_b
		mov 	dl,al		
		shl	dl,4
		inc 	ecx
		mov 	al,[ecx]
		call	.check_b		
		add	edx,eax
		pop	eax
		ret
.check_b:
	    	sub	al,'0'
		jb	endrequest_jmp
		cmp 	al,010
		jb	.ok
    		and     al,0dfh                 ;force upper case
		cmp	al,010h
		jz	endrequest_jmp
		cmp	al,'F'-'0'
		ja	endrequest_jmp
    		add     al,9                    ;ok, add 9 for strip
.ok:
    		and     al,0fh                  ;strip high 4 bits
		ret
endrequest_jmp:	jmp 	endrequest
%endif

UDATASEG

%ifdef	ERR404
err404len	resd	1	;filename length
err404		resd	1	;pointer
%endif
%ifdef	LOG
logfd	resd	1
%endif
%ifdef	CGI
execve_argv	resd	2	;two ptrs, argv[0] and NULL
%endif

arg1	resb	0xff
arg2	resb	0xff

root	resd	1

bindsockstruct	resd	4

finalpath	resb	0x1010	;10 is for safety
filebuf		resb	0x1010

END
