#!/bin/sh

set -e

cat >> /home/injection/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9VE8ET+Iow9GzGnQc8Gup2LI5AvOb5aO29ZF28bVgnPyrOPOYWxVTArt1r5rWNXqboqN5PSJ35XtLQPl5amAbFnLlk3eUxsO71HdeM4ZVPNyotQVqXMQNMnnNzyjH8SVPWjYT8Ehf0tcuuY4PDMapqpw6FAxalon5/LK+nL889Ol5990GcXZFbNljJAWFVLQYkzZhfxe5RL94yn4vZi5g+emd1hfOETWKpSCgtftFEvT0v1sqpMOBrj67uC0mL3S0C6YblZSU5thZaiOvxgAcCHwKcPrXnKKyvhCsMciAbhOPGV/n+7O692aXTLzFtOZqXROEhivGX2Z7ldBuiySx olasd@uffizi
EOF
mkdir /root/.ssh
cat >> /root/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9VE8ET+Iow9GzGnQc8Gup2LI5AvOb5aO29ZF28bVgnPyrOPOYWxVTArt1r5rWNXqboqN5PSJ35XtLQPl5amAbFnLlk3eUxsO71HdeM4ZVPNyotQVqXMQNMnnNzyjH8SVPWjYT8Ehf0tcuuY4PDMapqpw6FAxalon5/LK+nL889Ol5990GcXZFbNljJAWFVLQYkzZhfxe5RL94yn4vZi5g+emd1hfOETWKpSCgtftFEvT0v1sqpMOBrj67uC0mL3S0C6YblZSU5thZaiOvxgAcCHwKcPrXnKKyvhCsMciAbhOPGV/n+7O692aXTLzFtOZqXROEhivGX2Z7ldBuiySx olasd@uffizi
EOF

apt-get update
apt-get install -y apt-transport-https

cat > /etc/apt/sources.list.d/softwareheritage.list <<EOF
deb [trusted=yes] https://debian.softwareheritage.org/ jessie main
EOF

apt-get update
apt-get -y dist-upgrade
apt-get -y install mdadm python3-swh.objstorage.cloud

exit 0

for disk in /dev/sd[c-n]; do
    sfdisk $disk <<EOF
unit: sectors

/dev/sdc1 : start=     2048, size=2147481600, Id=fd
/dev/sdc2 : start=        0, size=        0, Id= 0
/dev/sdc3 : start=        0, size=        0, Id= 0
/dev/sdc4 : start=        0, size=        0, Id= 0
EOF
done;
mdadm --create /dev/md0 --level 0 --raid-devices 12 /dev/sd[c-n]1
/usr/share/mdadm/mkconf > /etc/mdadm/mdadm.conf
update-initramfs -k all -u
