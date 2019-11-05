In the following documentation, we will explain the necessary steps
needed to initialize a template vm.

Expectations:

-   hypervisor: orsay (could be beaubourg, hypervisor3)
-   \`/usr/bin/qm\` available from the hypervisor

Prepare vm template
===================

Connect to hypervisor orsay (\`ssh orsay\`)

And then as root, retrieve openstack images:

```
mkdir debian-10
wget -O debian-10/debian-10-openstack-amd64.qcow2 \
  https://cdimage.debian.org/cdimage/openstack/current/debian-10.0.1-20190708-openstack-amd64.qcow2
wget -O debian-10/debian-10-openstack-amd64.qcow2.index \
   https://cdimage.debian.org/cdimage/openstack/current/debian-10.0.1-20190708-openstack-amd64.qcow2.index
mkdir debian-9
wget -O debian-9/debian-9-openstack-amd64.qcow2 \
  https://cloud.debian.org/images/cloud/OpenStack/current-9/debian-9-openstack-amd64.qcow2
wget -O debian-9/debian-9-openstack-amd64.qcow2.index \
  https://cloud.debian.org/images/cloud/OpenStack/current-9/debian-9-openstack-amd64.qcow2.index
```

Note:

-   Not presented here but you should check the hashes of what you
    retrieved from the internet

Create vm
---------

```
chmod +x init-template.sh
./init-template.sh 10
```

This created a basic debian-9 vm (based on the cloud-stack one [1]). We still
need to connect to it to adapt it prior to make it a template (cf. below).

[1] https://cdimage.debian.org/cdimage/openstack/

Check image is working
----------------------

The rationale is to:

-   boot the vm
-   check some basic information (kernel, distribution, connection,
    release, etc...).
-   adapt slightly the vms (dns resolver, ip, upgrade, etc...)

### Start vm

```
qm start 10000
```

### Connect


#### ssh

```
ssh root@192.168.100.199
```

Note:
Public/Private Keys are stored in the credential store (`pass ls
operations/terraform-proxmox/ssh-key`).

#### proxmox console webui

Providing you set it a "cipassword" and reboot the vm first:

-   accessible from <https://orsay.internal.softwareheritage.org:8006/>
-   View \`datacenter\`
-   unfold the hypervisor \`orsay\` menu
-   select the vm \`10000\`
-   click the \`console\` menu.
-   log in as root/test password


### Checks

-   kernel linux version
-   debian release

### Adaptations

Update grub's timeout to 0 for a faster boot (as root):
```
sed -i s'/GRUB_TIMEOUT = 5/GRUB_TIMEOUT = 0/' /etc/default/grub
update-grub
```

Then, add some expected defaults:
```
sed -i 's/nameserver 127.0.0.1/nameserver 192.168.100.29/' /etc/resolv.conf
apt update
apt upgrade -y
apt install -y puppet
systemctl stop puppet; systemctl disable puppet.service
mkdir -p /etc/facter/facts.d
echo location=sesi_rocquencourt_staging > /etc/facter/facts.d/location.txt
```
-   etc...

### Remove cloud-init setup from vm

```
# stop vm
qm stop 10000
# remove cloud-init setup
qm set 10000 --delete ciuser,cipassword,ipconfig0,nameserver,sshkeys
```

Template the image
------------------

When the vm is ready, we can use it as a base template for future
clones:

```
qm template 10000
```

Clone image
===========

This is a tryout referenced here to demonstrate the shortcoming. That\'s
not necesary to do this as this will be taken care of by proxmox.

Sadly full clone only works:

```
qm clone 10000 666 --name debian-10-tryout --full true
```

As in: Fully clone from template \"10000\", the new vm with id \"666\"
dubbed \"buster-tryout\".

Note (partial clone does not work):

```
root@orsay:/home/ardumont/proxmox# qm clone 10000 666 --name buster-tryout
Linked clone feature is not supported for drive 'virtio0'
```

Note:

-   tested with all drives: ide, sata, scsi, virtio
-   only thing that worked was without a disk (but then no more os...)

source
======

<https://orsay.internal.softwareheritage.org:8006/pve-docs/chapter-qm.html#qm_cloud_init>
