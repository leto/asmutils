/*
	Copyright (C) 1999-2001 Konstantin Boldyshev

	$Id: test1.c,v 1.4 2001/02/23 12:39:29 konst Exp $

	test program for assembly libc
*/

#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>

#include "libc.h"

static char *fname = "_tst_",
	    *s = "Hello,world!\nType something, then press [Enter]\n",
	    buf[100];

static int fd, len;

int main(int argc, char **argv, char **envp)
{
    FASTCALL(3);

    len = strlen(s);

    fd = open(fname, O_CREAT | O_RDWR, 0600);
    write(fd, s, len);
    close(fd);

    fd = open(fname, O_RDONLY);
    lseek(fd, 0, SEEK_SET);
    len = read(fd, buf, len);
    close(fd);

    unlink(fname);

    write(STDOUT_FILENO, buf, len);

    len = read(STDIN_FILENO, buf, 10);
    write(STDOUT_FILENO, buf, len);

    return len;
}
