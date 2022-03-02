#!/bin/sh
set -e

MODULES="ext2 part_gpt search"

mkdir -p /boot/efi

uuid="$ROOT_UUID"

cat > /tmp/grub-core.cfg <<EOF
search.fs_uuid $ROOT_UUID root
set prefix=(\$root)'/boot/grub'
EOF

# grub-install refuses to work without a mounted EFI partition... sigh.
echo "Installing GRUB..."
mkdir -p /boot/grub
touch /boot/grub/device.map
dd if=/dev/zero of=/boot/grub/grubenv bs=1024 count=1
cp -r /usr/share/grub/themes /boot/grub
cp -r /usr/lib/grub/arm64-efi /boot/grub/
rm -f /boot/grub/arm64-efi/*.module
mkdir -p /boot/grub/{fonts,locale}
cp /usr/share/grub/unicode.pf2 /boot/grub/fonts
for i in /usr/share/locale/*/LC_MESSAGES/grub.mo; do
    lc="$(echo "$i" | cut -d/ -f5)"
    cp "$i" /boot/grub/locale/"$lc".mo
done

echo "Generating GRUB image..."
grub-mkimage \
    --directory '/usr/lib/grub/arm64-efi' \
    -c /tmp/grub-core.cfg \
    --prefix "/boot/grub" \
    --output /boot/grub/arm64-efi/core.efi \
    --format arm64-efi \
    --compression auto \
    $MODULES

# This seems to be broken
rm -f /etc/grub.d/30_uefi-firmware

# grub-mkconfig is run during image creation
