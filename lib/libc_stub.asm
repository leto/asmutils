;Copyright (C) 2001 Konstantin Boldyshev <konst@linuxassembly.org>
;
;$Id: libc_stub.asm,v 1.1 2001/03/01 12:34:55 konst Exp $
;
;hackers' libc stub
;
;0.01: 28-Jan-2001

%include "system.inc"

CODESEG

extern main
extern __start_main

START:
	push	dword main
	jmp	__start_main

END
