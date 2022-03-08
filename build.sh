#!/bin/bash

mkosi_rootfs='mkosi.rootfs'
image_mnt='mnt_image'
image_dir='images'
image_name='asahi-base'

EFI_UUID=2ABF-9F91
ROOT_UUID=725346d2-f127-47bc-b464-9dd46155e8d6
export ROOT_UUID EFI_UUID

if [ "$(whoami)" != "root" ]; then
    echo "You must be root to run this script."
    exit 1
fi

mkdir -p $mkosi_rootfs $image_mnt


mkosi_create_rootfs() {
    umount $mkosi_rootfs 2>/dev/null || true
    mkosi clean
    rm -rf .mkosi-* 
    mkosi
}    


make_image() {
    echo "## Making image $image_name"
    echo '### Cleaning up...'
    rm -f $mkosi_rootfs/var/cache/dnf/*
    echo '### Calculating image size...'
    size=$(du -B M -s $mkosi_rootfs | cut -dM -f1)
    echo "### Image size: $size MiB"
    size=$(($size + ($size / 8) + 64))
    echo "### Padded size: $size MiB"
    rm -f $image_dir/$image_name/root.img
    truncate -s ${size}M $image_dir/$image_name/root.img
    echo '### Making filesystem...'
    mkfs.ext4 -O '^metadata_csum' -U $ROOT_UUID -L 'asahi-root' $image_dir/$image_name/root.img
    echo '### Loop mounting...'
    mount -o loop $image_dir/$image_name/root.img $image_mnt
    echo '### Copying files...'
    rsync -aHAX \
        --exclude '/tmp/*' \
        --exclude /etc/machine-id \
        --exclude '/boot/efi/*' \
    $mkosi_rootfs/ $image_mnt/
    echo '### Running grub-mkconfig...'
    arch-chroot $image_mnt grub2-mkconfig -o /boot/grub2/grub.cfg
    echo '### Unmounting...'
    umount $image_mnt
    echo '### Creating EFI system partition tree...'
    mkdir -p $image_dir/$image_name/esp/EFI/
    rsync -aHAX $mkosi_rootfs/boot/efi/EFI/ $image_dir/$image_name/esp/EFI/
    echo '### Compressing...'
    rm -f $image_dir/$image_name.zip
    echo "rm -f $image_dir/$image_name.zip"
    cd $image_dir/$image_name/ && zip -r ../$image_name.zip *
    echo '### Done'
}

mkosi_create_rootfs
make_image
