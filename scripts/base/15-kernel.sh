#!/bin/sh

sed -i -e 's/^HOOKS=(base udev/HOOKS=(base asahi udev/' \
	/etc/mkinitcpio.conf

pacman --noconfirm -S linux-asahi
