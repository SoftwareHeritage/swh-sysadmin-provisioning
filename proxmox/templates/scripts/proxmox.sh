#!/bin/bash -eu

source /etc/os-release

export DEBIAN_FRONTEND=noninteractive

if [ ${VERSION_CODENAME} = "bookworm" ]; then
    apt-get install -y cloud-init qemu-guest-agent
else
    apt-get install -y cloud-init qemu qemu-guest-agent
fi

# Update grub for a faster boot
sed -i s'/GRUB_TIMEOUT = 5/GRUB_TIMEOUT = 0/' /etc/default/grub
update-grub

reboot
