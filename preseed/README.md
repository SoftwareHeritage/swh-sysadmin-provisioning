SWH internal infrastructure preseeding configuration
---------------------------------------------------------

# Preseed

Technology used to automate the debian installation per vm creation.

# Generate preseed from template

## Sample 1

Generate a preseed for a vm for public facing interface (e.g front server):

``` shell
./generate_preseed.py \
    --hostname worker03 \
    --private-mac 52:54:00:1a:85:9e \
    --public-mac 52:54:00:be:26:34 \
    --public-ip 128.93.193.23 \
    --public-netmask 255.255.255.0 \
    --public-gateway 128.93.193.254 \
    --public-dns 193.51.196.130
```

## Sample 2

Generate a preseed for a vm for internal use (e.g workers):

``` shell
./generate_preseed.py \
    --hostname icinga0 \
    --vmid 112 \
    --private-mac 8E:7D:DA:B5:42:83 \
    --ram 4096 \
    --private-ip 192.168.100.21 \
    --disk-specs proxmox-rbd:40G
```

Note:
- You must be consistent with whatever you used on the proxmox ui [1]
- The following information are provided in the proxmox ui after vm creation:
  - vmid
  - private-mac

[1] https://louvre.internal.softwareheritage.org:8006

# Run

Pre-requisite, on the hypervisor:

``` shell
$ 7z x -o/tmp/debian-netinstall/ /var/lib/vz/template/iso/debian-$version-netinstall.iso
$ cp -v /tmp/debian-install.amd/initrd.gz /tmp/initrd.gz
$ cp -v /tmp/debian-install.amd/vmlinuz /tmp/linux
```

Generate the preseed, the output of the generation will explain what to do:

``` shell
$ ./generate_preseed.py -n icinga0 --private-ip 192.168.100.21 --vmid 112 --private-mac 8E:7D:DA:B5:42:83 --ram 4096 --disk-specs beaubourg-local:40G

# >>>>> Local
scp preseed_icinga0.cfg louvre.internal.softwareheritage.org:/tmp
scp preseed_icinga0.cfg beaubourg.internal.softwareheritage.org:/tmp

# >>>>> Remote on hypervisor
cd /tmp; cp preseed_icinga0.cfg preseed.cfg; (cat initrd.gz; echo preseed.cfg | cpio -Hnewc --quiet -o | gzip -c) > initrd_112.gz

qm create 112 -bootdisk scsi0 -cores 1 -hotplug disk,network,usb,cpu -ide2 none,media=cdrom -memory 4096 -name icinga0 -net0 virtio=8E:7D:DA:B5:42:83,bridge=vmbr0 -numa 0 -ostype l26 -scsihw virtio-scsi-pci -sockets 1 -startup order=4 -scsi0 beaubourg-local:vm-112-disk-1,size=40G -args '-kernel /tmp/linux -initrd /tmp/initrd_112.gz'
pvesm alloc beaubourg-local 112 vm-112-disk-1 40G --format raw
qm start 112
while qm status 112 | grep -q running; do sleep 10; done
qm set 112 -delete args
qm start 112

```

# Pre-requisite

Install the `./preseed/finish.sh` script in the
debian.internal.softwareheritage.org apache server:
http://debian.internal.softwareheritage.org/installer/finish.sh
