/*
	Copyright (C) 1999-2001 Konstantin Boldyshev
    
	$Id: test2.c,v 1.5 2001/03/18 07:08:25 konst Exp $

	test program for assembly libc
*/

#include <stdio.h>
//#include <stdlib.h>		because of __strtol_internal
#include <string.h>
#include <unistd.h>

#include "libc.h"

extern char *getenv(char *);

int main(int argc, char **argv, char **envp)
{
    char inp[10], tmp[10];
    char *ptmp;
    int len;

    FASTCALL(3);

    printf("\n\tprintf() test\nhex: %x, octal: %o, decimal: %d\n", 0x10, 010, 10);

    printf("\n\tstrtol() test\nInput some decimal number: ");
    len = read(STDIN_FILENO, inp, 10);
    memcpy(tmp, inp, len);
    ptmp = &tmp[0] + len - 1;
    printf("You have entered %d\n", (int)strtol(&tmp[0], &ptmp, 10));

    printf("\n\tmemset() test\n");
    memset(tmp, 0, 10);
    ptmp = &tmp[0] + 5;
    for (len = 9; len > 0; len --) {
	memset(tmp, '0'+len, 5);
	printf("%d ", (int)strtol(&tmp[0], &ptmp, 10));
    }

    printf("\n\n\tvariable test\n");
    write(-1, NULL, 0);
    printf("errno: %d\n", errno);

    printf("\n\tenvironment test\nPress ENTER to print envrionment\n");
    read(STDIN_FILENO, inp, 1);

    len = 0;
    while(envp[len]) {
	printf("%s\n", envp[len]);
	len++;
    }

    printf("\n\tgetenv(\"HOME\") test\n%s\n", getenv("HOME"));

    if (argc > 1) {
	int i;
	printf("\n\targuments test\n");
	for (i = 0; i < argc; i++) printf("%s\n", argv[i]);
    }

    printf("\n\tall tests done\n");

    return 0;
}
