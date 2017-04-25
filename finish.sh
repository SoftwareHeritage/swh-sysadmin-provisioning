#!/bin/bash

set -e

apt-get install -y augeas-tools puppet

augtool << "EOF"
set /files/etc/puppet/puppet.conf/main/pluginsync true
set /files/etc/puppet/puppet.conf/main/server pergamon.internal.softwareheritage.org
save
EOF

systemctl disable puppet.service

/usr/bin/puppet agent --enable
/usr/bin/puppet agent --test || test $? -eq 2
