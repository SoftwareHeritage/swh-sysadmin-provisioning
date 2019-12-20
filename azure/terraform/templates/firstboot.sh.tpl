#!/bin/bash

set -ex

cd /

PUPPET_MASTER=pergamon.internal.softwareheritage.org

# Variables provided by terraform
HOSTNAME=${hostname}
FQDN=${fqdn}
IP=${ip_address}
FACTER_LOCATION=${facter_location}


# Handle base system configuration

apt-get -y install lsb-release
debian_suite=$(lsb_release -cs)

# Enable backports
cat > /etc/apt/sources.list.d/backports.list <<EOF
deb http://deb.debian.org/debian $${debian_suite}-backports main
EOF

# Update packages
apt-get update
apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade

# Properly set hostname and FQDN
echo $HOSTNAME > /etc/hostname
hostnamectl set-hostname $HOSTNAME
echo "$IP $FQDN $HOSTNAME" >> /etc/hosts


# Handle disk configuration

%{ for disk in disks }
# Make one large partition on ${disk.base_disk}
echo ';' | sudo sfdisk --label gpt ${disk.base_disk}

%{ if lookup(disk, "filesystem", "") != "" }
mkfs.${disk.filesystem} ${disk.base_disk}1

mkdir -p ${disk.mountpoint}

uuid=$(blkid -o value -s UUID ${disk.base_disk}1)
echo "UUID=\"$uuid\" ${disk.mountpoint} ${disk.filesystem} ${disk.mount_options} 0 0" >> /etc/fstab
%{ endif }
%{ endfor }

%{ if length(raids) != 0 }

apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --no-install-recommends install mdadm

%{ for raid in raids }

mdadm --create ${raid.path} \
      --level=${raid.level} \
      --raid-devices ${length(raid.members)} \
      %{ if raid.chunk != "" }--chunk=${raid.chunk}%{ endif } \
      %{~ for member in raid.members } ${member} %{ endfor ~}

%{ if lookup(raid, "filesystem", "") != "" }
mkfs.${raid.filesystem} ${raid.path}

mkdir -p ${raid.mountpoint}

uuid=$(blkid -o value -s UUID ${raid.path})
echo "UUID=\"$uuid\" ${raid.mountpoint} ${raid.filesystem} ${raid.mount_options} 0 0" >> /etc/fstab
%{ endif }
%{ endfor }

/usr/share/mdadm/mkconf > /etc/mdadm/mdadm.conf
update-initramfs -k all -u
%{ endif }

mount -a

# install puppet dependencies
apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --no-install-recommends install puppet gnupg

# do not need the service live as we need to install some more setup first
service puppet stop
systemctl disable puppet.service

# Install the location fact as that is needed by our puppet manifests
mkdir -p /etc/facter/facts.d
echo location=$FACTER_LOCATION > /etc/facter/facts.d/location.txt

# first time around, this will:
# - update the node's puppet agent configuration defining the puppet master
# - generate the certificates with the appropriate fqdn
puppet_exit=0

puppet agent --server $PUPPET_MASTER --waitforcert 60 --test --vardir /var/lib/puppet --detailed-exitcodes || puppet_exit=$?

if [ $puppet_exit -ne 2 ]; then
    exit $puppet_exit
fi

# reboot
