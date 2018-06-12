#!/bin/bash

set -e

apt-get update

apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y dist-upgrade

augtool << "EOF"
set /files/etc/puppet/puppet.conf/main/server pergamon.internal.softwareheritage.org
save
EOF

systemctl disable puppet.service

mkdir -p /etc/facter/facts.d
echo location=sesi_rocquencourt > /etc/facter/facts.d/location.txt

/usr/bin/puppet agent --enable
/usr/bin/puppet agent --test || true
