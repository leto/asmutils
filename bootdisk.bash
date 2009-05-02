#!/bin/bash

# Script to generate a Linux bootdisk with asmutils binaries
#
# Copyright (C) 2001	Karsten Scheibler <karsten.scheibler@bigfoot.de>
#
# $Id: bootdisk.bash,v 1.5 2002/08/17 08:14:35 konst Exp $


TMP_DIR=/tmp/bootdisk-$$
LOG_FILE="$TMP_DIR"/cmdlog
MOUNT_POINT="$TMP_DIR"/mnt
BOOTDISK_IMAGE="$TMP_DIR"/bootdisk
ROOT_IMAGE="$TMP_DIR"/rootraw
ROOT_IMAGE_SIZE=1024

function echo2
	{
	echo "$1" 1>&2 | cat >/dev/null
	}

function echo2n
	{
	echo -n "$1" 1>&2 | cat >/dev/null
	}

function error
	{
	echo2 "$1"
	exit 1
	}

function check
	{
	eval $@ 2>"$LOG_FILE"
	if [ $? -ne 0 ]; then
		echo2 "error"
		sed -e 's/^/    /' "$LOG_FILE" 1>&2 | cat >/dev/null
		exit 1
	else
		echo2 "ok"
	fi
	}

function check2
	{
	eval $@ >"$LOG_FILE" 2>&1
	if [ $? -ne 0 ]; then
		echo2 "error"
		sed -e 's/^/    /' "$LOG_FILE" 1>&2 | cat >/dev/null
		exit 1
	else
		echo2 "ok"
	fi
	}

function create_rc
{
cat <<EOF >"$1" 
#!/bin/sh

export TERM=linux
export PATH=/bin:/sbin
export HOME=/tmp
export SHELL=/bin/sh

echo -e "\033[2J\033[3;1H\t\033[1;37mWelcome to the \033[34masmutils\033[37m bootdisk! [\033[32mhttp://linuxassembly.org\033[37m]\033[0;37m\n\n\n"

echo -e "mounting /proc..\c"
mount -t proc none /proc
&& echo -e "done"

hostname alpha

echo -e "configuring network..\c"
ifconfig lo 127.0.0.1
&& ifconfig eth0 192.168.0.1
&& echo -e "starting daemons..\c"
&& httpd /etc/httpd/ 80 /etc/httpd/404.html
&& ftpd /etc/ftpd.conf 20
&& echo -e "done\n"

EOF
chmod 555 "$1"
}


if [ `id -u` -ne 0 -o `uname` != "Linux" ]; then
	error "this script must be run as root under Linux"
fi

if [ $# -ne 2 ]; then
	echo2 "Usage: $0 kernelfile path_to_asmutils_binaries"
	echo2
	echo2 "Given kernel must support ramdisk, minix fs and floppy drive."
	error "Resulting bootdisk is written to stdout."
fi

KERNEL_FILE="$1"
ASMUTILS_PATH="$2"

trap 'umount "$ROOT_IMAGE" >/dev/null 2>&1; rm -rf "$TMP_DIR"' 0

if ! mkdir "$TMP_DIR" 2>/dev/null; then
	error "can't create '$TMP_DIR'"
fi

echo2n "creating root image mount point ... "
check2 'mkdir -m 755 "$MOUNT_POINT"'

echo2n "creating root image ... "
check2 'dd if=/dev/zero of="$ROOT_IMAGE" bs=1k count="$ROOT_IMAGE_SIZE"'

echo2n "creating root filesystem ... "
check2 'echo y | mkfs.minix "$ROOT_IMAGE"'

echo2n "mounting root image ... "
check2 'mount -o loop -t minix "$ROOT_IMAGE" "$MOUNT_POINT"'

echo2n "copying data to root filesystem ... "
check2 '
mkdir -m 755 "$MOUNT_POINT"/bin &&
mkdir -m 755 "$MOUNT_POINT"/dev &&
mkdir -m 755 "$MOUNT_POINT"/etc &&
mkdir -m 755 "$MOUNT_POINT"/proc &&
mkdir -m 777 "$MOUNT_POINT"/tmp &&
chmod 1777 "$MOUNT_POINT"/tmp &&
mkdir -m 755 "$MOUNT_POINT"/dev/pts &&
mknod -m 600 "$MOUNT_POINT"/dev/console c 4 0 &&
mknod -m 600 "$MOUNT_POINT"/dev/tty c 5 0 &&
mknod -m 600 "$MOUNT_POINT"/dev/tty0 c 4 0 &&
mknod -m 600 "$MOUNT_POINT"/dev/tty1 c 4 1 &&
mknod -m 600 "$MOUNT_POINT"/dev/tty2 c 4 2 &&
mknod -m 600 "$MOUNT_POINT"/dev/tty3 c 4 3 &&
mknod -m 600 "$MOUNT_POINT"/dev/tty4 c 4 4 &&
mknod -m 600 "$MOUNT_POINT"/dev/tty5 c 4 5 &&
mknod -m 600 "$MOUNT_POINT"/dev/tty6 c 4 6 &&
mknod -m 600 "$MOUNT_POINT"/dev/tty7 c 4 7 &&
mknod -m 600 "$MOUNT_POINT"/dev/tty8 c 4 8 &&
mknod -m 600 "$MOUNT_POINT"/dev/tty9 c 4 9 &&
mknod -m 600 "$MOUNT_POINT"/dev/vcs0 c 7 0 &&
mknod -m 600 "$MOUNT_POINT"/dev/vcs1 c 7 1 &&
mknod -m 600 "$MOUNT_POINT"/dev/vcs2 c 7 2 &&
mknod -m 600 "$MOUNT_POINT"/dev/vcs3 c 7 3 &&
mknod -m 600 "$MOUNT_POINT"/dev/vcs4 c 7 4 &&
mknod -m 600 "$MOUNT_POINT"/dev/vcs5 c 7 5 &&
mknod -m 600 "$MOUNT_POINT"/dev/vcs6 c 7 6 &&
mknod -m 600 "$MOUNT_POINT"/dev/vcs7 c 7 7 &&
mknod -m 600 "$MOUNT_POINT"/dev/vcs8 c 7 8 &&
mknod -m 600 "$MOUNT_POINT"/dev/vcs9 c 7 9 &&
mknod -m 600 "$MOUNT_POINT"/dev/vcsa0 c 7 128 &&
mknod -m 600 "$MOUNT_POINT"/dev/vcsa1 c 7 129 &&
mknod -m 600 "$MOUNT_POINT"/dev/vcsa2 c 7 130 &&
mknod -m 600 "$MOUNT_POINT"/dev/vcsa3 c 7 131 &&
mknod -m 600 "$MOUNT_POINT"/dev/vcsa4 c 7 132 &&
mknod -m 600 "$MOUNT_POINT"/dev/vcsa5 c 7 133 &&
mknod -m 600 "$MOUNT_POINT"/dev/vcsa6 c 7 134 &&
mknod -m 600 "$MOUNT_POINT"/dev/vcsa7 c 7 135 &&
mknod -m 600 "$MOUNT_POINT"/dev/vcsa8 c 7 136 &&
mknod -m 600 "$MOUNT_POINT"/dev/vcsa9 c 7 137 &&
mknod -m 600 "$MOUNT_POINT"/dev/mem c 1 1 &&
mknod -m 600 "$MOUNT_POINT"/dev/audio c 14 4 &&
mknod -m 600 "$MOUNT_POINT"/dev/dsp c 14 3 &&
mknod -m 600 "$MOUNT_POINT"/dev/fb0 c 29 0 &&
create_rc "$MOUNT_POINT/etc/rc" &&
echo "/dev/ram0 / minix rw 0 0" > "$MOUNT_POINT"/etc/mtab &&
  ( cd "$ASMUTILS_PATH"; ls -1 | while read FILE; do if [ -x "$FILE" ]; then
  cp -a "$FILE" "$MOUNT_POINT"/bin/; fi; done;
  chown root.root "$MOUNT_POINT"/bin/*; chmod 555 "$MOUNT_POINT"/bin/* )'

echo2n "copying kernel ... "
check2 'dd if="$KERNEL_FILE" of="$BOOTDISK_IMAGE" bs=1024'

echo2n "umounting root image ... "
check2 'umount "$ROOT_IMAGE"'

echo2n "compressing root image ... "
check2 'gzip -9 "$ROOT_IMAGE"'

set `ls -li $BOOTDISK_IMAGE`
let KERNEL_SIZE=$6/1024+1
echo2 "Kernelsize: $KERNEL_SIZE KB"

let RAMDISK_WORD=$KERNEL_SIZE+16384
echo2 "Ramdisk Flags: $RAMDISK_WORD"

set `ls -li $ROOT_IMAGE.gz`
let COMPRESSED_ROOT_IMAGE_SIZE=$6/1024+1
echo2 "compressed root image size: $COMPRESSED_ROOT_IMAGE_SIZE KB"

let ROOT_AND_KERNEL=$COMPRESSED_ROOT_IMAGE_SIZE+$KERNEL_SIZE
echo2 "compressed root image + kernel: $ROOT_AND_KERNEL KB"

if [ "$ROOT_AND_KERNEL" -le 1440 ]; then 
	echo2 "disk image fits on 1.44MB floppy disk ;-)"
else
	error "disk image is too large for a 1.44MB floppy disk ;-O"
fi

echo2n "setting kernel root device ... "
check2 'rdev "$BOOTDISK_IMAGE" /dev/fd0'

echo2n "setting kernel root filesystem to rw ... "
check2 'rdev -R "$BOOTDISK_IMAGE" 0'

echo2n "setting kernel ramdisk word ... "
check2 'rdev -r "$BOOTDISK_IMAGE" "$RAMDISK_WORD"'

echo2n "setting kernel video mode ... "
check2 'rdev -v "$BOOTDISK_IMAGE" 768'

echo2n "appending root filesystem to kernel ... "
check2 'dd if="$ROOT_IMAGE".gz of="$BOOTDISK_IMAGE" bs=1024 seek="$KERNEL_SIZE"'

echo2n "outputting bootdisk ... "
check 'cat "$BOOTDISK_IMAGE"'
