#!/bin/sh

cat >/etc/fstab <<EOF
UUID=$ROOT_UUID / ext4 rw,relatime,x-systemd.growfs 0 1
UUID=$EFI_UUID /boot/efi vfat rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,errors=remount-ro    0 2
EOF
