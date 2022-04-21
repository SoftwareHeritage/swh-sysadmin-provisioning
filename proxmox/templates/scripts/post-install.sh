#!/bin/bash -eu

####
# apt configuration
####
source /etc/os-release

cat <<EOF >/etc/apt/sources.list.d/debian.list
deb http://deb.debian.org/debian ${VERSION_CODENAME} main
deb-src http://deb.debian.org/debian ${VERSION_CODENAME} main

deb http://deb.debian.org/debian ${VERSION_CODENAME}-updates main
deb-src http://deb.debian.org/debian ${VERSION_CODENAME}-updates main
EOF

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get upgrade -y
apt-get install -y man wget curl telnet net-tools dnsutils traceroute unbound \
        gpg aptitude
aptitude -y install "?priority(standard)!~i?archive(stable)"

####
# Puppet
####
apt-get install -y puppet gnupg
