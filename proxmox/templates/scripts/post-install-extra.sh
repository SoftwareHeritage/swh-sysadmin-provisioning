#!/bin/bash -eu

####
# apt configuration
####
source /etc/os-release

if [ ${VERSION_CODENAME} = "bookworm" ]; then
    sed -i "s/${VERSION_CODENAME} main/${VERSION_CODENAME} main contrib/" /etc/apt/sources.list.d/debian.list
    sed -i "s/${VERSION_CODENAME}-updates main/${VERSION_CODENAME}-updates main contrib/" /etc/apt/sources.list.d/debian.list
else
    cat <<EOF >/etc/apt/sources.list.d/backports.list
deb http://deb.debian.org/debian/ ${VERSION_CODENAME}-backports main contrib
EOF
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y zfs-dkms
