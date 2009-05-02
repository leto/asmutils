# Copyright (C) 1999-2001 Konstantin Boldyshev <konst@linuxassembly.org>
#
# Makefile for libc (GNU make is required)
#
# $Id: Makefile,v 1.12 2006/02/18 09:39:33 konst Exp $

# Target CPU (386,486,586,686)

CPU = 386

#

DEBUG = y

BUILD_LIB = y

include ../MCONFIG

BUILD_STATIC = y
BUILD_SHARED = y

LIBCRYPTO_OBJS = md5.o rc6.o rmd.o
LIBCRYPTO_A = libcrypto.a
LIBCRYPTO_SO = libcrypto.so.0

STUB_OBJS = libc_stub.o

LIBC_OBJS = libc.o
LIBC_A = libc.a
LIBC_SO = ./libc.so.0

LIBM_OBJS = libm.o
LIBM_A = libm.a
LIBM_SO = ./libm.so.0

CTESTS = test1 test2

CLEAN_CFLAGS := -D__CPU__=$(CPU) -Wall -O1 -Os -march=i386

ifdef DEBUG
CLEAN_CFLAGS += -g
else
CLEAN_CFLAGS += -fomit-frame-pointer
endif

CFLAGS := $(CLEAN_CFLAGS)

%.o:	%.c
	$(CC) $(CLEAN_CFLAGS) -c -o $@ $<

# we are testing our own library, not glibc headers and gcc inlines
# so, disable the damn thing

CFLAGS += -D__NO_STRING_INLINES -fno-builtin

# the same with all other glibc crap

CFLAGS += -nostartfiles -nostdlib
#-Wl,-e,main?

%:	%.c
ifdef	BUILD_SHARED
	$(CC) $(CFLAGS) -o $@-shared $< $(STUB_OBJS) $(LIBC_SO)
	$(CC) $(CFLAGS) -mregparm=3 -D__FASTCALL__\
		-o $@-shared-fastcall $< $(STUB_OBJS) $(LIBC_SO)
endif
ifdef	BUILD_STATIC
	$(CC) $(CFLAGS) -static -o $@-static $< $(STUB_OBJS) $(LIBC_A)
	$(CC) $(CFLAGS) -static -mregparm=3 -D__FASTCALL__\
		-o $@-static-fastcall $< $(STUB_OBJS) $(LIBC_A)
endif

all:	libc libm crypto testc testm

libc:	$(LIBC_OBJS) $(STUB_OBJS)
ifdef BUILD_STATIC
	$(AR) rcv $(LIBC_A) $(LIBC_OBJS)
endif
ifdef BUILD_SHARED
	$(LD) $(LDFLAGS) -shared -soname $(LIBC_SO) \
		-o $(LIBC_SO) $(LIBC_OBJS)
endif

libm:	$(LIBM_OBJS)
ifdef BUILD_STATIC
	$(AR) rcv $(LIBM_A) $(LIBM_OBJS)
endif
ifdef BUILD_SHARED
	$(LD) $(LDFLAGS) -shared -soname $(LIBM_SO) \
		-o $(LIBM_SO) $(LIBM_OBJS)
endif

crypto:	$(LIBCRYPTO_OBJS)
ifdef BUILD_STATIC
	$(AR) rcv $(LIBCRYPTO_A) $(LIBCRYPTO_OBJS)
endif
ifdef BUILD_SHARED
	$(LD) $(LDFLAGS) -shared -soname $(LIBCRYPTO_SO) \
		-o $(LIBCRYPTO_SO) $(LIBCRYPTO_OBJS)
endif

#CRYPTOFILES = ../src/md5sum.o
#cryptofiles: $(CRYPTOFILES)
#	ld -s -o aaa $(CRYPTOFILES) libcrypto.a

ifdef AOUT
testc:
testm:
else
testc: $(CTESTS)

#
# Build it with usual libc for now
#

testm:	testm.c
ifdef	BUILD_SHARED
	$(CC) $(CLEAN_CFLAGS) -o $@-shared $< $(LIBM_SO)
endif
ifdef	BUILD_STATIC
	$(CC) $(CLEAN_CFLAGS) -o $@-static $< $(LIBM_A)
endif

endif

install:

clean:
	rm -f *.o *.a *.so* $(TESTS) *-shared* *-static*
