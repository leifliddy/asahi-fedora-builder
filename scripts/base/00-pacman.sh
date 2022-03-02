#!/bin.sh
set -e

sed -i -e '/\[core\]/i [asahi]\nInclude = /etc/pacman.d/mirrorlist.asahi\n' /etc/pacman.conf

cp /files/mirrorlist.asahi /etc/pacman.d/mirrorlist.asahi

pacman-key --init
pacman-key --populate archlinuxarm asahilinux
