#!/bin/bash -eu

####
# apt configuration
####
cat <<EOF >/etc/apt/sources.list.d/debian.list
deb http://deb.debian.org/debian buster main
deb-src http://deb.debian.org/debian buster main

deb http://deb.debian.org/debian-security/ buster/updates main
deb-src http://deb.debian.org/debian-security/ buster/updates main

deb http://deb.debian.org/debian buster-updates main
deb-src http://deb.debian.org/debian buster-updates main
EOF

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y man wget curl telnet net-tools dnsutils traceroute unbound gpg aptitude
aptitude -y install "?priority(standard)!~i?archive(stable)"

####
# Puppet
####
apt-get install -y puppet gnupg
