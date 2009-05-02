# Copyright (C) 1999-2006 Konstantin Boldyshev <konst@linuxassembly.org>
#
# Makefile for asmutils (GNU make is required)
#
# $Id: Makefile,v 1.64 2006/02/09 07:51:31 konst Exp $

#DEBUG = y

BUILD_SRC = y

include ../MCONFIG

FILES = basename cal cat chmod chroot chown cmp cpuinfo cut date dc dd deflate dirname\
	echo env extname factor fromdos grep head hexdump hostname\
	id init kill ln lzss mkdir mknod nice nm nohup od rot13 paste\
	readelf readlink reboot renice scons sleep strings sync\
	tail tar tee tr true uname uuencode wc whoami yes\
	md5sum rmdsum rc6crypt sha1sum idea md5\

FILES += readkey less getty \
	 ftpd host httpd m_inetd nc netstat ping pop3d proxy scan\
	 telnet telnetd wget\
	 cp du ls mount mv pwd rm sh test touch watch which write\

LINKS = arch cpuspeed domainname false inflate mkfifo more rmdir size sln\
	todos umount usleep halt poweroff\

BDIR = bonus/

BONUS =	$(BDIR)execve $(BDIR)report $(BDIR)asmutils

ifdef LINUX
FILES += cda2raw chvt dmesg df eject fdisk finger free gi ifconfig\
	 killall ksyms lsmod lsusb mesg mkfs.minix ps\
	 softdog swapon sysctl truss tty update uptime users
LINKS += ccd deallocvt fingerd killall5 pidof rmmod route swapoff mkswap
BONUS += $(BDIR)leaves $(BDIR)fire256 $(BDIR)mandelbrot $(BDIR)hdragon\
	 $(BDIR)window  $(BDIR)snake $(BDIR)game
endif

ifdef FREEBSD
FILES += kldload
LINKS += kldunload kldstat
endif

all:	$(FILES) $(BONUS) links

links:	$(FILES)
	-@( mkln() { [ ! -e $$2 ] && [ -x $$1 ] && $(LN) $$1 $$2; };\
	mkln hostname domainname;\
	mkln ln sln;\
	mkln mkdir rmdir;\
	mkln mknod mkfifo;\
	mkln true false;\
	mkln uname arch;\
	mkln cpuinfo cpuspeed;\
	mkln fromdos todos;\
	mkln ifconfig route;\
	mkln swapon swapoff;\
	mkln swapon mkswap;\
	mkln chvt deallocvt;\
	mkln eject ccd;\
	mkln mount umount;\
	mkln reboot halt;\
	mkln reboot poweroff;\
	mkln lsmod rmmod;\
	mkln kldload kldunload;\
	mkln kldload kldstat;\
	mkln killall killall5;\
	mkln killall pidof;\
	mkln sleep usleep;\
	mkln less more;\
	mkln nm size;\
	mkln finger fingerd;\
	mkln deflate inflate;\
	cd $(BDIR); mkln execve regs;\
	)

install:$(FILES)
	$(MKDIR) $(INSTALLDIR)
	$(CP) $(FILES) $(LINKS) $(INSTALLDIR)

clean:
	$(RM) *.o $(FILES) $(LINKS) $(BONUS) $(BDIR)regs
