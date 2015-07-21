OB#!/bin/bash

set -e

if ifconfig | grep -q eth1; then
    cat >> /etc/network/interfaces << EOF

auto eth1
iface eth1 inet dhcp
EOF
fi

# Create full disk partition for swap
echo -e "o\nn\np\n1\n\n\nt\n82\nw" | fdisk /dev/vdb

mkswap /dev/vdb1
uuid=`blkid /dev/vdb1 -o value -s UUID`
echo "UUID=$uuid none swap sw 0 0" >> /etc/fstab

apt-get install -y augeas-tools puppet

augtool << "EOF"
set /files/etc/puppet/puppet.conf/main/pluginsync true
set /files/etc/puppet/puppet.conf/main/server pergamon.softwareheritage.org
save
EOF

systemctl disable puppet.service

/usr/bin/puppet agent --enable
/usr/bin/puppet agent --test || test $? -eq 2
