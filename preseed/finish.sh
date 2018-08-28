#!/bin/bash

set -e

PUPPET_MASTER=pergamon.internal.softwareheritage.org
LOCATION=sesi_rocquencourt

apt-get update

apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y dist-upgrade

systemctl disable puppet.service

mkdir -p /etc/facter/facts.d
echo "location=$LOCATION" > /etc/facter/facts.d/location.txt

# first time around, this will:
# - update the node's puppet agent configuration defining the puppet master
# - generate the certificates with the appropriate fqdn
# - unfortunately, for now, this fails though, when not being able to
#   install the apt-transport-https package
puppet agent --server $PUPPET_MASTER --waitforcert 60 --test
