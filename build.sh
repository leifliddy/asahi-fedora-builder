#!/bin/bash

set -e

mkosi_rootfs='mkosi.rootfs'
image_dir='images'
image_mnt='mnt_image'
date=$(date +%Y%m%d)
image_name=asahi-base-${date}-1

# this has to match the volume_id in installer_data.json
# "volume_id": "0x2abf9f91"
EFI_UUID=2ABF-9F91
BOOT_UUID=$(uuidgen)
BTRFS_UUID=$(uuidgen)

if [ "$(whoami)" != 'root' ]; then
    echo "You must be root to run this script."
    exit 1
fi

mkdir -p $image_mnt $mkosi_rootfs $image_dir/$image_name

mkosi_create_rootfs() {
    umount_image
    mkosi clean
    rm -rf .mkosi-*
    mkosi
}

mount_image() {
    # get last modified image
    image_path=$(find $image_dir -maxdepth 1 -type d | grep -E /asahi-base-[0-9]{8}-[0-9] | sort | tail -1)

    [[ -z $image_path ]] && echo -n "image not found in $image_dir\nexiting..." && exit

    for img in root.img boot.img esp; do
        [[ ! -e $image_path/$img ]] && echo -e "$image_path/$img not found\nexiting..." && exit
    done

    [[ -z "$(findmnt -n $image_mnt)" ]] && mount -o loop,subvol=root $image_path/root.img $image_mnt
    [[ -z "$(findmnt -n $image_mnt/boot)" ]] && mount -o loop $image_path/boot.img $image_mnt/boot
    [[ -z "$(findmnt -n $image_mnt/boot/efi)" ]] && mount --bind  $image_path/esp/ $image_mnt/boot/efi/
}

umount_image() {
    if [ ! "$(findmnt -n $image_mnt)" ]; then
        return
    fi

    [[ -n "$(findmnt -n $image_mnt/boot/efi)" ]] && umount $image_mnt/boot/efi
    [[ -n "$(findmnt -n $image_mnt/boot)" ]] && umount $image_mnt/boot
    [[ -n "$(findmnt -n $image_mnt)" ]] && umount $image_mnt
}

# ./build.sh mount
#  or
# ./build.sh umount
#  to mount or unmount an image (that was previously created by this script) to/from mnt_image/
if [[ $1 == 'mount' ]]; then
    mount_image
    exit
elif [[ $1 == 'umount' ]] || [[ $1 == 'unmount' ]]; then
    umount_image
    exit
fi

make_image() {
    # if  $image_mnt is mounted, then unmount it
    umount_image
    echo "## Making image $image_name"
    echo '### Cleaning up'
    rm -f $mkosi_rootfs/var/cache/dnf/*
    rm -rf $image_dir/$image_name/*

    ############# create boot.img #############
    echo '### Calculating boot image size'
    size=$(du -B M -s $mkosi_rootfs/boot | cut -dM -f1)
    echo "### Boot Image size: $size MiB"
    size=$(($size + ($size / 8) + 64))
    echo "### Boot Padded size: $size MiB"
    truncate -s ${size}M $image_dir/$image_name/boot.img

    ############# create root.img #############
    echo '### Calculating root image size'
    size=$(du -B M -s --exclude=$mkosi_rootfs/boot $mkosi_rootfs | cut -dM -f1)
    echo "### Root Image size: $size MiB"
    size=$(($size + ($size / 8) + 64))
    echo "### Root Padded size: $size MiB"
    truncate -s ${size}M $image_dir/$image_name/root.img

    ###### create ext4 filesystem on boot.img ######
    echo '### Creating ext4 filesystem on boot.img '
    mkfs.ext4 -U $BOOT_UUID -L fedora_boot -b 4096 $image_dir/$image_name/boot.img

    ###### create btrfs filesystem on root.img ######
    echo '### Creating btrfs filesystem on root.img '
    mkfs.btrfs -U $BTRFS_UUID -L 'fedora_asahi' $image_dir/$image_name/root.img

    echo '### Loop mounting root.img'
    mount -o loop $image_dir/$image_name/root.img $image_mnt
    echo '### Creating btrfs subvolumes'
    btrfs subvolume create $image_mnt/root
    btrfs subvolume create $image_mnt/home
    echo '### Loop mounting boot.img'
    mkdir -p $image_mnt/boot
    mount -o loop $image_dir/$image_name/boot.img $image_mnt/boot
    echo '### Copying files'
    rsync -aHAX --exclude '/tmp/*' --exclude '/boot/*' --exclude '/home/*' $mkosi_rootfs/ $image_mnt/root
    rsync -aHAX $mkosi_rootfs/boot/ $image_mnt/boot
    # this should be empty, but just in case
    rsync -aHAX $mkosi_rootfs/home/ $image_mnt/home
    umount $image_mnt/boot
    umount $image_mnt
    echo '### Loop mounting btrfs root subvolume'
    mount -o loop,subvol=root $image_dir/$image_name/root.img $image_mnt
    echo '### Loop mounting ext4 boot volume'
    mount -o loop $image_dir/$image_name/boot.img $image_mnt/boot
    echo '### Setting pre-defined uuid for efi vfat partition in /etc/fstab'
    sed -i "s/EFI_UUID_PLACEHOLDER/$EFI_UUID/" $image_mnt/etc/fstab
    echo '### Setting uuid for boot partition in /etc/fstab'
    sed -i "s/BOOT_UUID_PLACEHOLDER/$BOOT_UUID/" $image_mnt/etc/fstab
    echo '### Setting uuid for btrfs partition in /etc/fstab'
    sed -i "s/BTRFS_UUID_PLACEHOLDER/$BTRFS_UUID/" $image_mnt/etc/fstab

    # remove resolv.conf symlink -- this causes issues with arch-chroot
    rm -f $image_mnt/etc/resolv.conf

    # need to generate a machine-id so that a BLS entry can be created below
    echo -e '\n### Running systemd-machine-id-setup'
    chroot $image_mnt systemd-machine-id-setup
    chroot $image_mnt echo "KERNEL_INSTALL_MACHINE_ID=$(cat /etc/machine-id)" > /etc/machine-info

    echo -e '\n### Generating EFI bootloader'
    arch-chroot $image_mnt create-efi-bootloader

    echo -e '\n### Generating GRUB config'
    arch-chroot $image_mnt grub2-editenv create
    rm -f $image_mnt/etc/kernel/cmdline
    sed -i "s/BOOT_UUID_PLACEHOLDER/$BOOT_UUID/" $image_mnt/boot/efi/EFI/fedora/grub.cfg
    # /etc/grub.d/30_uefi-firmware creates a uefi grub boot entry that doesn't work on this platform
    chroot $image_mnt chmod -x /etc/grub.d/30_uefi-firmware
    arch-chroot $image_mnt grub2-mkconfig -o /boot/grub2/grub.cfg

    echo '### Creating BLS (/boot/loader/entries/) entry'
    arch-chroot $image_mnt /image.creation/create.bls.entry

    echo -e '\n### Running update-m1n1'
    rm -f $image_mnt/boot/.builder
    mkdir -p $image_mnt/boot/efi/m1n1
    arch-chroot $image_mnt update-m1n1 /boot/efi/m1n1/boot.bin

    echo -e '\n### Copying firmware.cpio'
    if [ -f /boot/efi/vendorfw/firmware.cpio ]; then
      mkdir -p $image_mnt/boot/efi/vendorfw
      cp /boot/efi/vendorfw/firmware.cpio $image_mnt/boot/efi/vendorfw
    fi

    # adding a small delay prevents this error msg from polluting the console
    # device (wlan0): interface index 2 renamed iface from 'wlan0' to 'wlp1s0f0'
    echo -e '\n### Adding delay to NetworkManager.service'
    sed -i '/ExecStart=.*$/iExecStartPre=/usr/bin/sleep 2' $image_mnt/usr/lib/systemd/system/NetworkManager.service
    echo "### Enabling system services"
    arch-chroot $image_mnt systemctl enable NetworkManager sshd systemd-resolved
    echo "### Disabling systemd-firstboot"
    chroot $image_mnt rm -f /usr/lib/systemd/system/sysinit.target.wants/systemd-firstboot.service

    # selinux will be set to enforcing on the first boot via asahi-firstboot.service
    # set to permissive here to ensure the system performs an initial boot
    echo '### Setting selinux to permissive'
    sed -i 's/^SELINUX=.*$/SELINUX=permissive/' $image_mnt/etc/selinux/config

    echo -e '\n### Creating EFI system partition tree'
    mkdir -p $image_dir/$image_name/esp/
    rsync -aHAX $image_mnt/boot/efi/ $image_dir/$image_name/esp/

    ###### post-install cleanup ######
    echo -e '\n### Cleanup'
    rm -rf $image_mnt/boot/efi/*
    rm -rf $image_mnt/boot/lost+found/
    rm -f  $image_mnt/etc/machine-id
    rm -f  $image_mnt/etc/kernel/{entry-token,install.conf}
    rm -rf $image_mnt/image.creation
    rm -f  $image_mnt/etc/dracut.conf.d/initial-boot.conf
    chroot $image_mnt ln -s ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

    echo -e '\n### Unmounting btrfs subvolumes'
    umount $image_mnt/boot
    umount $image_mnt

    echo -e '\n### Compressing'
    rm -f $image_dir/$image_name.zip
    pushd $image_dir/$image_name > /dev/null
    zip -r ../$image_name.zip .
    popd > /dev/null

    echo '### Done'
}

[[ $(command -v getenforce) ]] && setenforce 0
mkosi_create_rootfs
make_image
