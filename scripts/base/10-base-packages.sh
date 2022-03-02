#!/bin/sh
set -e

pacman --noconfirm -R linux-aarch64
pacman --noconfirm -Syu
pacman --noconfirm -S asahi-scripts mkinitcpio linux-asahi grub iwd
