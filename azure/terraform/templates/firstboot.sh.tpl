#!/bin/bash

set -ex

cd /

PUPPET_MASTER=pergamon.internal.softwareheritage.org

# Variables provided by terraform
HOSTNAME=${hostname}
FQDN=${fqdn}
IP=${ip_address}
FACTER_LOCATION=${facter_location}

%{ for disk in disks }
# Make one large partition on ${disk.base_disk}
echo ';' | sudo sfdisk --label gpt ${disk.base_disk}

mkfs.${disk.filesystem} ${disk.base_disk}1

mkdir -p ${disk.mountpoint}

uuid=$(blkid -o value -s UUID ${disk.base_disk}1)
echo "UUID=\"$uuid\" ${disk.mountpoint} ${disk.filesystem} ${disk.mount_options} 0 0" >> /etc/fstab
%{ endfor }

mount -a

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

# install puppet dependencies
apt-get -y install -t $${debian_suite}-backports facter
apt-get -y install puppet

# do not need the service live as we need to install some more setup first
service puppet stop
systemctl disable puppet.service

# Install the location fact as that is needed by our puppet manifests
mkdir -p /etc/facter/facts.d
echo location=$FACTER_LOCATION > /etc/facter/facts.d/location.txt

# first time around, this will:
# - update the node's puppet agent configuration defining the puppet master
# - generate the certificates with the appropriate fqdn
# - unfortunately, for now, this fails though, when not being able to
#   install the apt-transport-https package
puppet agent --server $PUPPET_MASTER --waitforcert 60 --test

#reboot
