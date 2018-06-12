#!/bin/bash

set -ex

PUPPET_MASTER=pergamon.internal.softwareheritage.org
APT='apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"'

cd /

# Update the nodes to the latest packages
apt-get update; $APT dist-upgrade

# default to private instance
PRIVATE=${1-"private"}

if [ $PRIVATE != 'private' -a $PRIVATE != 'public' ]; then
    echo "First argument must be either 'public' or 'private', nothing else."
    exit 1
fi

# We need to override the default hostname provided by azure when the
# node is provisioned
ORIG_HOSTNAME="$(hostname)"
if [ $PRIVATE = "private" ]; then
    # private ip have a fqdn with the azure location
    # FIXME: Do we need to use a different hostname pattern when in azure?
    HOSTNAME=${ORIG_HOSTNAME/-*/}.euwest.azure
    FQDN=${HOSTNAME}.internal.softwareheritage.org
else
    # public ones do not need to leak that information
    HOSTNAME=${ORIG_HOSTNAME/-*/}
    FQDN=${HOSTNAME}.softwareheritage.org
fi

echo $HOSTNAME > /etc/hostname
hostnamectl set-hostname $HOSTNAME

# we need this to circumvent some puppet issues down the line.  The
# fqdn policy puppet uses does not render the right name (at least for
# public node). Puppet is trying to solve the fqdn through the
# /etc/resolv.conf if not provided in /etc/hosts
IP=$(ip a | grep 192 | awk '{print $2}' | awk -F/ '{print $1}')
cat >> /etc/hosts << EOF
$IP $FQDN $HOSTNAME

192.168.100.100 db
192.168.100.101 uffizi
192.168.100.31 moma
EOF

# install puppet dependencies
$APT install puppet

# do not need the service live as we need to install some more setup first
service puppet stop
systemctl disable puppet.service

# Install the location fact as that is needed by our puppet manifests
mkdir -p /etc/facter/facts.d
echo location=azure_euwest > /etc/facter/facts.d/location.txt

# first time around, this will:
# - update the node's puppet agent configuration defining the puppet master
# - generate the certificates with the appropriate fqdn
# - unfortunately, for now, this fails though, when not being able to
#   install the apt-transport-https package
puppet agent --server $PUPPET_MASTER --waitforcert 60 --test
# so we install it
$APT install apt-transport-https
# now everything should be fine
puppet agent --server $PUPPET_MASTER --test || true

#reboot
