#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import argparse

from passlib.hash import sha512_crypt
import xkcdpass.xkcd_password as xp

VIRT_INSTALL_CMD = "cp {preseed_file} preseed.cfg && sudo virt-install --name {hostname} --ram {ram} --vcpus {vcpus} --os-type linux --os-variant generic {networks} --graphics vnc --console pty,target_type=serial --location 'http://httpredir.debian.org/debian/dists/jessie/main/installer-amd64/' --extra-args 'console=ttyS0,115200n8 serial auto' {disks} --initrd-inject=preseed.cfg"

NETWORK_CFG = "--network network={network},model=virtio,mac={mac}"
DISK_CFG = "--disk path=/dev/vg-louvre/{hostname}-{disk},bus=virtio"

PASS_INSTALL_CMD = "echo {password} | pass insert --force --multiline infra/{hostname}/root"

STATIC_NETWORK_CFG_TEMPLATE = """
d-i netcfg/disable_autoconfig boolean true
d-i netcfg/get_ipaddress string {public_ip}
d-i netcfg/get_netmask string {public_netmask}
d-i netcfg/get_gateway string {public_gateway}
d-i netcfg/get_nameservers string {public_dns}
d-i netcfg/confirm_static boolean true"""

def generate_password():
    wordfile = xp.locate_wordfile()
    wordlist = xp.generate_wordlist(wordfile=wordfile)

    return xp.generate_xkcdpassword(wordlist, numwords=4, delimiter='-')

if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("-n", "--hostname", help="Name of the new host", required=True)
    parser.add_argument("--public-mac", help="MAC of the public interface")
    parser.add_argument("--public-ip", help="IP of the public interface")
    parser.add_argument("--public-netmask", help="Netmask of the public interface")
    parser.add_argument("--public-gateway", help="Gateway of the public interface")
    parser.add_argument("--public-dns", help="DNS server of the public interface")
    parser.add_argument("--private-mac", help="MAC of the private interface", required=True)
    parser.add_argument("--finish-url", help="Finish URL", required=True)
    parser.add_argument("--preseed-template", help="Preseeding file template", required=True)
    parser.add_argument("--ram", help="RAM amount", type=int, default=2048)
    parser.add_argument("--vcpus", help="Number of virtual CPUs", type=int, default=1)
    parser.add_argument("--disk", help="Add disk", action="append", default=["root", "swap"])

    args = parser.parse_args()

    preseed_template_vars = {}
    preseed_template_vars["hostname"] = args.hostname
    preseed_template_vars["finish_url"] = args.finish_url
    preseed_file = "preseed_{hostname}.cfg".format(hostname=args.hostname)

    # Network configuration without public ip is automatic, static with public ip
    if not args.public_ip:
        preseed_template_vars["network_configuration"] = ""
    else:
        preseed_template_vars["network_configuration"] = STATIC_NETWORK_CFG_TEMPLATE.format(**args.__dict__)

    # Password Generation and hashing
    password = generate_password()
    preseed_template_vars["crypted_password"] = sha512_crypt.encrypt(password)

    # Generate the output preseed file
    preseed_template = open(args.preseed_template).read()
    output = preseed_template % preseed_template_vars
    preseed_output = open(preseed_file, "w")
    preseed_output.write(output)
    preseed_output.close()

    # Generate the command for virt-install
    virt_template_vars = {}
    virt_template_vars["hostname"] = args.hostname
    virt_template_vars["ram"] = args.ram
    virt_template_vars["vcpus"] = args.vcpus
    virt_template_vars['preseed_file'] = preseed_file

    # disk configuration: one disk added per partition
    disk_configs = []
    for disk in args.disk:
        disk_configs.append(DISK_CFG.format(disk=disk, hostname=args.hostname))
    virt_template_vars["disks"] = " ".join(disk_configs)

    # network configuration: one network card per networks, public then private
    networks = []
    if args.public_ip:
        networks.append(('public', args.public_mac))
    networks.append(('default', args.private_mac))
    virt_template_vars["networks"] = " ".join(NETWORK_CFG.format(network=network, mac=mac) for network, mac in networks)

    virt_command = VIRT_INSTALL_CMD.format(**virt_template_vars)
    print(virt_command)

    # generate the password command
    pass_command = PASS_INSTALL_CMD.format(password=password, hostname=args.hostname)
    print(pass_command)
