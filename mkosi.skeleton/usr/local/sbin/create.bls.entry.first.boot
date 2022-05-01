 #!/bin/bash

# this script only needs to be run as part of systemd-firstboot
# this is due to the /etc/machine-id value being changed

rm -f /boot/loader/entries/*.conf

installed_kernels=$(rpm -q kernel | sed 's/kernel-//')

for kernel_version in $installed_kernels
do
    kernel-install add $kernel_version /lib/modules/$kernel_version/vmlinuz
done
