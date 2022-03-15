 #!/bin/bash

# this script only needs to run during the image creation process

rm -f /boot/loader/entries/*.conf
[[ -f /etc/os-release ]] && . /etc/os-release

kernel_vmlinuz=$(ls /boot/ | grep '^vmlinuz')
kernel_version=$(echo $kernel_vmlinuz | sed 's/^vmlinuz-//')
title="${NAME} (${kernel_version}) ${VERSION}"

grubby --add-kernel=/boot/$kernel_vmlinuz --title "$title"
