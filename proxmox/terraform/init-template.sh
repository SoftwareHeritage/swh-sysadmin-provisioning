#!/usr/bin/env bash

set -x
set -e

VERSION=${1-"9"}
NAME="template-debian-${VERSION}"
IMG="debian-$VERSION/debian-$VERSION-openstack-amd64.qcow2"

VM_ID="${VERSION}000"
VM_DISK="vm-$VM_ID-disk-0"

# create vm
qm create $VM_ID --memory 4096 --net0 virtio,bridge=vmbr0 --name "$NAME"
# import disk to orsay-ssd-2018 (lots of space there)
qm importdisk $VM_ID $IMG orsay-ssd-2018 --format qcow2
# finally attach the new disk to the VM as virtio drive
qm set $VM_ID --scsihw virtio-scsi-pci --virtio0 "orsay-ssd-2018:$VM_DISK"
# resize the disk to add 30G (image size is 2G) ~> this increases the clone time so no
# qm resize 9000 virtio0 +30G
# configure a cdrom drive which is used to pass the cloud-init data
# to the vm
qm set $VM_ID --ide2 orsay-ssd-2018:cloudinit
# boot from disk only
qm set $VM_ID --boot c --bootdisk virtio0
# add serial console (for cloud-init, this is needed or else that won't work)
qm set $VM_ID --serial0 socket
# sets the number of sockets/cores
qm set $VM_ID --sockets 2 --cores 1

# cloud init temporary setup
qm set $VM_ID --ciuser root
qm set $VM_ID --ipconfig0 "ip=192.168.100.125/24,gw=192.168.100.1"
qm set $VM_ID --nameserver "192.168.100.29"

SSH_KEY_PUB=$HOME/.ssh/proxmox-ssh-key.pub
[ -f $SSH_KEY_PUB ] &&  qm set $VM_ID --sshkeys $SSH_KEY_PUB
