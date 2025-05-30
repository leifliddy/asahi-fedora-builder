#!/bin/bash

set -e

mkosi_output='mkosi.output'
mkosi_rootfs="$mkosi_output/image"
mkosi_cache='mkosi.cache'
mnt_image="$(pwd)/mnt_image"
image_dir='images'
date=$(date +%Y%m%d)
image_name=asahi-fedora-${date}-1
mkosi_max_supported_version=22

# this has to match the volume_id in installer_data.json
# "volume_id": "0x2abf9f91"
EFI_UUID=2ABF-9F91
BOOT_UUID=$(uuidgen)
BTRFS_UUID=$(uuidgen)

if [ "$(whoami)" != 'root' ]; then
    echo "You must be root to run this script"
    exit
elif [[ -n $SUDO_USER ]] && [[ $SUDO_USER != 'root' ]]; then
    echo "You must run this script as root and not with sudo"
    exit
fi

[ ! -d $mnt_image ] && mkdir $mnt_image
[ ! -d $mkosi_output ] && mkdir $mkosi_output
[ ! -d $mkosi_cache ] && mkdir $mkosi_cache
[ ! -d $image_dir/$image_name ] && mkdir -p $image_dir/$image_name

check_mkosi() {
    mkosi_cmd=$(command -v mkosi || true)
    [[ -z $mkosi_cmd ]] && echo 'mkosi is not installed...exiting' && exit
    mkosi_version=$(mkosi --version | awk '{print $2}' | sed 's/\..*$//')

    if [[ $mkosi_version -gt $mkosi_max_supported_version ]]; then
        echo "mkosi path:    $mkosi_cmd"
        echo "mkosi version: $mkosi_version"
        echo -e "\nOnly mkosi version $mkosi_max_supported_version and below are supported"
        echo "please install a compatible version to continue"
        exit
    fi
}

mkosi_create_rootfs() {
    umount_image
    mkosi clean
    mkosi
}

mount_image() {
    # get last modified image
    image_path=$(find $image_dir -maxdepth 1 -type d | grep -E /asahi-fedora-[0-9]{8}-[0-9] | sort | tail -1)

    [[ -z $image_path ]] && echo -n "image not found in $image_dir\nexiting..." && exit

    for img in root.img boot.img esp; do
        [[ ! -e $image_path/$img ]] && echo -e "$image_path/$img not found\nexiting..." && exit
    done

    [[ -z "$(findmnt -n $mnt_image)" ]] && mount -o loop,subvol=root $image_path/root.img $mnt_image
    [[ -z "$(findmnt -n $mnt_image/boot)" ]] && mount -o loop $image_path/boot.img $mnt_image/boot
    [[ -z "$(findmnt -n $mnt_image/boot/efi)" ]] && mount --bind  $image_path/esp/ $mnt_image/boot/efi/
    # we need this since we're using set -e
    return 0
}

umount_image() {
    if [ ! "$(findmnt -n $mnt_image)" ]; then
        return
    fi

    [[ -n "$(findmnt -n $mnt_image/boot/efi)" ]] && umount $mnt_image/boot/efi
    [[ -n "$(findmnt -n $mnt_image/boot)" ]] && umount $mnt_image/boot
    [[ -n "$(findmnt -n $mnt_image)" ]] && umount $mnt_image
}

# ./build.sh mount
# ./build.sh umount
# ./build chroot
#  to mount, unmount, or chroot into an image (that was previously created by this script)
if [[ $1 == 'mount' ]]; then
    echo "### Mounting to $mnt_image"
    mount_image
    exit
elif [[ $1 == 'umount' ]] || [[ $1 == 'unmount' ]]; then
    echo "### Umounting from $mnt_image"
    umount_image    # if  $mnt_image is mounted, then unmount it
    exit
elif [[ $1 == 'remount' ]]; then
    echo "### Remounting $mnt_image"
    umount_image
    mount_image
    exit
elif [[ $1 == 'chroot' ]]; then
    mount_image
    echo "### Chrooting into $mnt_image"
    arch-chroot $mnt_image
    exit
elif [[ -n $1 ]]; then
    echo "$1 isn't a recogized option"
    exit
fi

make_image() {
    # if  $mnt_image is mounted, then unmount it
    umount_image
    echo "## Making image $image_name"
    echo '### Cleaning up'
    rm -f $mkosi_rootfs/var/cache/dnf/*
    rm -rf $image_dir/$image_name/*
    [[ -f mkosi.rootfs.vmlinuz ]] && rm -f mkosi.rootfs.vmlinuz

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
    mount -o loop $image_dir/$image_name/root.img $mnt_image
    echo '### Creating btrfs subvolumes'
    btrfs subvolume create $mnt_image/root
    btrfs subvolume create $mnt_image/home

    echo '### Loop mounting boot.img'
    mkdir -p $mnt_image/boot
    mount -o loop $image_dir/$image_name/boot.img $mnt_image/boot

    echo '### Copying files'
    rsync -aHAX --exclude '/tmp/*' --exclude '/boot/*' --exclude '/home/*' --exclude '/efi' $mkosi_rootfs/ $mnt_image/root
    echo "rsync -aHAX $mkosi_rootfs/boot/ $mnt_usb/boot"
    rsync -aHAX $mkosi_rootfs/boot/ $mnt_image/boot
    # this should be empty, but just in case
    rsync -aHAX $mkosi_rootfs/home/ $mnt_image/home
    umount $mnt_image/boot
    umount $mnt_image
    echo '### Loop mounting btrfs root subvolume'
    mount -o loop,subvol=root $image_dir/$image_name/root.img $mnt_image
    echo '### Loop mounting ext4 boot volume'
    mount -o loop $image_dir/$image_name/boot.img $mnt_image/boot

    echo '### Setting pre-defined uuid for efi vfat partition in /etc/fstab'
    sed -i "s/EFI_UUID_PLACEHOLDER/$EFI_UUID/" $mnt_image/etc/fstab
    echo '### Setting uuid for boot partition in /etc/fstab'
    sed -i "s/BOOT_UUID_PLACEHOLDER/$BOOT_UUID/" $mnt_image/etc/fstab
    echo '### Setting uuid for btrfs partition in /etc/fstab'
    sed -i "s/BTRFS_UUID_PLACEHOLDER/$BTRFS_UUID/" $mnt_image/etc/fstab

    # remove resolv.conf symlink -- this causes issues with arch-chroot
    rm -f $mnt_image/etc/resolv.conf

    echo -e '\n### Generating GRUB config'
    arch-chroot $mnt_image grub2-editenv create

    sed -i "s/BOOT_UUID_PLACEHOLDER/$BOOT_UUID/" $mnt_image/boot/efi/EFI/fedora/grub.cfg
    # /etc/grub.d/30_uefi-firmware creates a uefi grub boot entry that doesn't work on this platform
    chroot $mnt_image chmod -x /etc/grub.d/30_uefi-firmware
    arch-chroot $mnt_image grub2-mkconfig -o /boot/grub2/grub.cfg

    echo '### Creating BLS (/boot/loader/entries/) entry'
    arch-chroot $mnt_image /image.creation/create.bls.entry

    echo -e '\n### Running update-m1n1'
    rm -f $mnt_image/boot/.builder
    mkdir -p $mnt_image/boot/efi/m1n1
    arch-chroot $mnt_image update-m1n1 /boot/efi/m1n1/boot.bin

    echo "### Enabling system services"
    arch-chroot $mnt_image systemctl enable asahi-setup-swap-firstboot NetworkManager sshd systemd-resolved
    echo "### Disabling systemd-firstboot"
    chroot $mnt_image rm -f /usr/lib/systemd/system/sysinit.target.wants/systemd-firstboot.service

    # selinux will be set to enforcing on the first boot via asahi-firstboot.service
    # set to permissive here to ensure the system performs an initial boot
    echo '### Setting selinux to permissive'
    sed -i 's/^SELINUX=.*$/SELINUX=permissive/' $mnt_image/etc/selinux/config

    echo "### SElinux labeling filesystem"
    policy=$(ls -tr  $mnt_image/etc/selinux/targeted/policy/ | tail -1)

    arch-chroot $mnt_image setfiles -F -p -c /etc/selinux/targeted/policy/$policy -e /proc -e /sys -e /dev /etc/selinux/targeted/contexts/files/file_contexts /
    arch-chroot $mnt_image setfiles -F -p -c /etc/selinux/targeted/policy/$policy -e /proc -e /sys -e /dev /etc/selinux/targeted/contexts/files/file_contexts /boot

    echo -e '\n### Creating EFI system partition tree'
    mkdir -p $image_dir/$image_name/esp/
    rsync -aHAX $mnt_image/boot/efi/ $image_dir/$image_name/esp/

    # change formatting of the line that /usr/libexec/fedora-asahi-remix-scripts/setup-swap.sh adds to /etc/fstab -- to match our formatting
    chroot $mnt_image sed -i 's/\/var\/swap\/swapfile swap swap sw 0 0/\/var\/swap\/swapfile                         swap       swap   sw                           0 0/' /usr/libexec/fedora-asahi-remix-scripts/setup-swap.sh

    ###### post-install cleanup ######
    echo -e '\n### Cleanup'
    rm -rf $mnt_image/boot/efi/*
    rm -rf $mnt_image/boot/lost+found
    rm -f  $mnt_image/init
    rm -f  $mnt_image/etc/machine-id
    rm -f  $mnt_image/etc/kernel/{entry-token,install.conf}
    rm -rf $mnt_image/image.creation
    rm -f  $mnt_image/etc/dracut.conf.d/initial-boot.conf
    rm -f  $mnt_image/etc/yum.repos.d/mkosi*.repo
    rm -f  $mnt_image/var/lib/systemd/random-seed
    sed -i '/GRUB_DISABLE_OS_PROBER=true/d' $mnt_image/etc/default/grub
    chroot $mnt_image ln -s ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    # not sure how/why a $mnt_image/root/asahi-fedora-builder directory is being created
    # remove it like this to account for it being named something different
    find $mnt_image/root/ -maxdepth 1 -mindepth 1 -type d | grep -Ev '/\..*$' | xargs rm -rf

    echo -e '\n### Unmounting btrfs subvolumes'
    umount $mnt_image/boot
    umount $mnt_image

    echo -e '\n### Compressing'
    rm -f $image_dir/$image_name.zip
    pushd $image_dir/$image_name > /dev/null
    zip -r ../$image_name.zip .
    popd > /dev/null

    echo '### Done'
}

check_mkosi

if [[ $(command -v getenforce) ]] && [[ "$(getenforce)" = "Enforcing" ]]; then
    setenforce 0
    trap 'setenforce 1; exit;' EXIT SIGHUP SIGINT SIGTERM SIGQUIT SIGABRT
fi

mkosi_create_rootfs

make_image
