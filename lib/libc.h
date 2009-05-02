/*

    Copyright (C) 1999-2001 Konstantin Boldyshev

    $Id: libc.h,v 1.3 2001/02/23 12:39:29 konst Exp $

    Header file for assembly libc, defines functions that:
	1) are not present in usual libc
	2) conflict with our libc
    We will use standard libc headers for the rest of functions for now.
*/

/*
    _fastcall() must be always fastcall
*/

extern void __attribute__ (( __regparm__(1) ))
	_fastcall(int);

#ifdef __FASTCALL__
#define FASTCALL(x) _fastcall(x)
#else
#define FASTCALL(x) _fastcall(0)
#endif

extern void __attribute__ (( __noreturn__ ))
	exit(int);

extern long strtol(const char *, char **, int);

extern volatile int errno;

/*
extern unsigned strlen(const char *);
extern void *memcpy(void *, const void *, int);
extern void *memset(void *, int, int);
*/
