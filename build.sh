#!/bin/sh

set -e

BASE_IMAGE_URL="https://jp.mirror.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz"
BASE_IMAGE="$(basename "$BASE_IMAGE_URL")"

DL="$PWD/dl"
ROOT="$PWD/root"
FILES="$PWD/files"
IMAGES="$PWD/images"
IMG="$PWD/img"

EFI_UUID=2ABF-9F91
ROOT_UUID=725346d2-f127-47bc-b464-9dd46155e8d6
export ROOT_UUID EFI_UUID

if [ "$(whoami)" != "root" ]; then
    echo "You must be root to run this script."
    exit 1
fi

umount "$IMG" 2>/dev/null || true
mkdir -p "$DL" "$IMG"

if [ ! -e "$DL/$BASE_IMAGE" ]; then
    echo "## Downloading base image..."
    wget "$BASE_IMAGE_URL" -O "$DL/$BASE_IMAGE"
fi

umount "$ROOT" 2>/dev/null || true
rm -rf "$ROOT"
mkdir -p "$ROOT"

echo "## Unpacking base image..."
bsdtar -xpf "$DL/$BASE_IMAGE" -C "$ROOT" || true

cp -vr "$FILES" "$ROOT"

mount --bind "$ROOT" "$ROOT"

echo "## Installing keyring package..."
pacstrap "$ROOT" asahilinux-keyring

run_scripts() {
    group="$1"
    echo "## Running script group: $group"
    for i in "scripts/$group/"*; do
        echo "### Running $i"
        arch-chroot "$ROOT" /bin/bash <"$i"
    done
}

make_image() {
    imgname="$1"
    img="$IMAGES/$imgname"
    mkdir -p "$img"
    echo "## Making image $imgname"
    echo "### Cleaning up..."
    rm -f "$ROOT/var/cache/pacman/pkg"/*
    echo "### Calculating image size..."
    size="$(du -B M -s "$ROOT" | cut -dM -f1)"
    echo "### Image size: $size MiB"
    size=$(($size + ($size / 8) + 64))
    echo "### Padded size: $size MiB"
    rm -f "$img/root.img"
    truncate -s "${size}M" "$img/root.img"
    echo "### Making filesystem..."
    mkfs.ext4 -O '^metadata_csum' -U "$ROOT_UUID" -L "asahi-root" "$img/root.img"
    echo "### Loop mounting..."
    mount -o loop "$img/root.img" "$IMG"
    echo "### Copying files..."
    rsync -aHAX \
        --exclude /files \
        --exclude '/tmp/*' \
        --exclude '/etc/pacman.d/gnupg/*' \
        --exclude /etc/machine-id \
        --exclude '/boot/efi/*' \
        "$ROOT/" "$IMG/"
    echo "### Runnig grub-mkconfig..."
    arch-chroot "$IMG" grub-mkconfig -o /boot/grub/grub.cfg
    echo "### Unmounting..."
    umount "$IMG"
    echo "### Creating EFI system partition tree..."
    mkdir -p "$img/esp/EFI/BOOT"
    cp "$ROOT"/boot/grub/arm64-efi/core.efi "$img/esp/EFI/BOOT/BOOTAA64.EFI"
    echo "### Compressing..."
    rm -f "$img".zip
    ( cd "$img"; zip -r ../"$imgname".zip * )
    echo "### Done"
}

run_scripts base
make_image "asahi-base"

#run_scripts plasma
#make_image "asahi-plasma"
