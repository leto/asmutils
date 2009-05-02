# Copyright (C) 1999-2000 Konstantin Boldyshev <konst@linuxassembly.org>
#
# Top Makefile for asmutils (GNU make is required)
#
# $Id: Makefile,v 1.1 2000/09/03 16:13:53 konst Exp $

include MCONFIG

SUBDIRS = src lib
DO_MAKE = @ for i in $(SUBDIRS); do $(MAKE) -C $$i $@; done

all:	$(SUBDIRS)
	$(DO_MAKE)

clean:
	$(DO_MAKE)

install: all
	$(DO_MAKE)
