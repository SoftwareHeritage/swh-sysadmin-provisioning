#!/bin/bash

set -e

cat >/etc/apt/sources.list.d/backports.list <<EOF
# This file is managed by Puppet. DO NOT EDIT.
# backports
deb http://deb.debian.org/debian/ jessie-backports main
EOF

cat >/etc/apt/preferences.d/puppet.pref <<EOF
# This file is managed by Puppet. DO NOT EDIT.
Explanation: Pin puppet dependencies to backports
Package: facter hiera puppet puppet-common puppetmaster puppetmaster-common puppetmaster-passenger ruby-deep-merge
Pin: release n=jessie-backports
Pin-Priority: 990
EOF

apt-get update

apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y dist-upgrade

augtool << "EOF"
set /files/etc/puppet/puppet.conf/main/pluginsync true
set /files/etc/puppet/puppet.conf/main/server pergamon.internal.softwareheritage.org
save
EOF

systemctl disable puppet.service

mkdir -p /etc/facter/facts.d
echo location=sesi_rocquencourt > /etc/facter/facts.d/location.txt

/usr/bin/puppet agent --enable
/usr/bin/puppet agent --test || true
