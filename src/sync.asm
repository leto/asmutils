;Copyright (C) 1999-2000 Konstantin Boldyshev <konst@linuxassembly.org>
;
;$Id: sync.asm,v 1.2 2000/02/10 15:07:04 konst Exp $
;
;hackers' sync
;
;0.01: 05-Jun-1999	initial release
;0.02: 17-Jun-1999	size improvements
;0.03: 07-Feb-2000	portable way :)
;
;syntax: sync

%include "system.inc"

CODESEG

START:
	sys_sync			
	sys_exit eax

END
