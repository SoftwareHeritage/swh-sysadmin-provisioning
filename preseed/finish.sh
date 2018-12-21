#!/bin/bash

set -e

PUPPET_MASTER=pergamon
PUPPET_MASTER_FQDN="$PUPPET_MASTER.internal.softwareheritage.org"
LOCATION=sesi_rocquencourt

cat > /etc/apt/sources.list.d/backports.list <<EOF
deb https://deb.debian.org/debian stretch-backports main
EOF

apt-get update

apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install -t stretch-backports facter
apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y dist-upgrade

systemctl disable puppet.service

mkdir -p /etc/facter/facts.d
echo "location=$LOCATION" > /etc/facter/facts.d/location.txt

echo "192.168.100.29 $PUPPET_MASTER_FQDN $PUPPET_MASTER" >> /etc/hosts

# first time around, this will:
# - update the node's puppet agent configuration defining the puppet master
# - generate the certificates with the appropriate fqdn
# - unfortunately, for now, this fails though, when not being able to
#   install the apt-transport-https package
puppet agent --server $PUPPET_MASTER_FQDN --waitforcert 60 --test
