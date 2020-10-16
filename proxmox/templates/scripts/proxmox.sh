#!/bin/bash -eu


apt-get install -y cloud-init qemu qemu-guest-agent

# Update grub for a faster boot
sed -i s'/GRUB_TIMEOUT = 5/GRUB_TIMEOUT = 0/' /etc/default/grub
update-grub

reboot
