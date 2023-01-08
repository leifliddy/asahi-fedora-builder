#!/bin/bash

set -e

mkosi_rootfs='mkosi.rootfs'
image_dir='images'
image_mnt='mnt_image'
date=$(date +%Y%m%d)
image_name=asahi-base-${date}

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
    mkosi clean
    rm -rf .mkosi-*
    wget https://leifliddy.com/asahi-linux/asahi-linux.repo -O mkosi.skeleton/etc/yum.repos.d/asahi-linux.repo
    mkosi
}


make_image() {
    # if  $image_mnt is mounted, then unmount it
    [[ -n "$(findmnt -n $image_mnt/boot)" ]] && umount $image_mnt/boot
    [[ -n "$(findmnt -n $image_mnt)" ]] && umount $image_mnt
    echo "## Making image $image_name"
    echo '### Cleaning up...'
    rm -f $mkosi_rootfs/var/cache/dnf/*
    rm -rf $image_dir/$image_name/*

    ############# create boot.img #############
    echo '### Calculating boot image size...'
    size=$(du -B M -s $mkosi_rootfs/boot | cut -dM -f1)
    echo "### Boot Image size: $size MiB"
    size=$(($size + ($size / 8) + 64))
    echo "### Boot Padded size: $size MiB"
    truncate -s ${size}M $image_dir/$image_name/boot.img

    ############# create root.img #############
    echo '### Calculating root image size...'
    size=$(du -B M -s --exclude=$mkosi_rootfs/boot $mkosi_rootfs | cut -dM -f1)
    echo "### Root Image size: $size MiB"
    size=$(($size + ($size / 8) + 64))
    echo "### Root Padded size: $size MiB"
    truncate -s ${size}M $image_dir/$image_name/root.img

    ###### create ext4 filesystem on boot.img ######
    echo '### Creating ext4 filesystem on boot.img ...'
    mkfs.ext4 -U $BOOT_UUID -L fedora_boot -b 4096 images/$image_name/boot.img

    ###### create btrfs filesystem on root.img ######
    echo '### Creating btrfs filesystem on root.img ...'
    mkfs.btrfs -U $BTRFS_UUID -L 'fedora_asahi' $image_dir/$image_name/root.img

    echo '### Loop mounting root.img...'
    mount -o loop $image_dir/$image_name/root.img $image_mnt
    echo '### Creating btrfs subvolumes'
    btrfs subvolume create $image_mnt/root
    btrfs subvolume create $image_mnt/home
    echo '### Loop mounting boot.img...'
    mkdir -p $image_mnt/boot
    mount -o loop $image_dir/$image_name/boot.img $image_mnt/boot
    echo '### Copying files...'
    rsync -aHAX --exclude '/tmp/*' --exclude '/boot/*' --exclude '/home/*' $mkosi_rootfs/ $image_mnt/root
    rsync -aHAX $mkosi_rootfs/boot/ $image_mnt/boot
    # this should be empty, but just in case...
    rsync -aHAX $mkosi_rootfs/home/ $image_mnt/home
    umount $image_mnt/boot
    umount $image_mnt
    echo '### Loop mounting btrfs root subvolume...'
    mount -o loop,subvol=root $image_dir/$image_name/root.img $image_mnt
    echo '### Loop mounting ext4 boot volume...'
    mount -o loop $image_dir/$image_name/boot.img $image_mnt/boot
    echo '### Setting pre-defined uuid for efi vfat partition in /etc/fstab...'
    sed -i "s/EFI_UUID_PLACEHOLDER/$EFI_UUID/" $image_mnt/etc/fstab
    echo '### Setting random uuid for boot partition in /etc/fstab...'
    sed -i "s/BOOT_UUID_PLACEHOLDER/$BOOT_UUID/" $image_mnt/etc/fstab
    echo '### Setting random uuid for btrfs partition in /etc/fstab...'
    sed -i "s/BTRFS_UUID_PLACEHOLDER/$BTRFS_UUID/" $image_mnt/etc/fstab
    echo '### Running systemd-machine-id-setup...'
    # need to generate a machine-id so that a BLS entry can be created below
    chroot $image_mnt systemd-machine-id-setup
    chroot $image_mnt echo "KERNEL_INSTALL_MACHINE_ID=$(cat /etc/machine-id)" > /etc/machine-info
    # run update-m1n1 to ensure the /boot/dtb/apple/*.dtb files are used
    echo '### Running update-m1n1...'
    rm -f $image_mnt/boot/.builder
    mkdir -p $image_mnt/boot/efi/m1n1
    arch-chroot $image_mnt /usr/sbin/update-m1n1 /boot/efi/m1n1/boot.bin
    echo '### Copying firmware.cpio...'
    if [ -f /boot/efi/vendorfw/firmware.cpio ]; then
      mkdir -p $image_mnt/boot/efi/vendorfw
      cp /boot/efi/vendorfw/firmware.cpio $image_mnt/boot/efi/vendorfw
    fi
    echo "### Creating BLS (/boot/loader/entries/) entry..."
    chroot $image_mnt /image.creation/create.bls.entry
    echo '### Updating GRUB...'
    arch-chroot $image_mnt /usr/sbin/update-grub
    echo '### Remove rhgb and quiet from /etc/kernel/cmdline'
    sed -i 's/rhgb quiet//' $image_mnt/etc/kernel/cmdline
    # adding a small delay prevents this error msg from polluting the console
    # device (wlan0): interface index 2 renamed iface from 'wlan0' to 'wlp1s0f0'
    echo "### Adding delay to NetworkManager.service..."
    sed -i '/ExecStart=.*$/iExecStartPre=/usr/bin/sleep 2' $image_mnt/usr/lib/systemd/system/NetworkManager.service
    echo "### Enabling system services..."
    chroot $image_mnt systemctl enable NetworkManager.service sshd.service
    echo "### Disabling systemd-firstboot..."
    chroot $image_mnt rm -f /usr/lib/systemd/system/sysinit.target.wants/systemd-firstboot.service
    echo "### Setting selinux to permissive"
    sed -i 's/^SELINUX=.*$/SELINUX=permissive/' $image_mnt/etc/selinux/config
    echo '### Creating EFI system partition tree...'
    mkdir -p $image_dir/$image_name/esp/
    rsync -aHAX $image_mnt/boot/efi/ $image_dir/$image_name/esp/
    rm -rf $image_mnt/boot/efi/*
    rm -f $image_mnt/etc/machine-id
    rm -f $image_mnt/etc/kernel/{cmdline,entry-token,install.conf}
    rm -rf $image_mnt/image.creation
    rm -f  $image_mnt/etc/dracut.conf.d/initial-boot.conf
    echo '### Unmounting btrfs subvolumes...'
    umount $image_mnt/boot
    umount $image_mnt
    echo '### Compressing...'
    rm -f $image_dir/$image_name.zip
    pushd $image_dir/$image_name > /dev/null
    zip -r ../$image_name.zip .
    popd > /dev/null
    echo '### Done'
}

mkosi_create_rootfs
make_image
