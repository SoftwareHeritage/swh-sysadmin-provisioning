#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import argparse
from collections import defaultdict

from passlib.hash import sha512_crypt
import xkcdpass.xkcd_password as xp

QM_CREATE_CMD = (
    "qm create {vmid} "
    "-bootdisk virtio0 "
    "-cores {cores} "
    "-hotplug disk,network,usb,cpu "
    "-ide2 none,media=cdrom "
    "-memory {ram} "
    "-name {hostname} "
    "{networks} "
    "-numa 0 "
    "-ostype l26 "
    "-scsihw virtio-scsi-pci "
    "-sockets {sockets} "
    "-startup {startup} "
    "{disks} "
    "-args '-kernel /tmp/linux -initrd /tmp/initrd_{vmid}.gz'"
)

CPIO_CMDS = "cd /tmp; cp preseed_{hostname}.cfg preseed.cfg; (cat initrd.gz; echo preseed.cfg | cpio -Hnewc --quiet -o | gzip -c) > initrd_{vmid}.gz"

NETWORK_CFG = "-net{netindex} virtio={mac},bridge={bridge}"

DISK_CFG = "-{type}{typeindex} {volume}:vm-{vmid}-disk-{volumeindex},size={size}"
DISK_CREATE_CMD = 'pvesm alloc {volume} {vmid} vm-{vmid}-disk-{volumeindex} {size} --format raw'

PASS_INSTALL_CMD = "echo {password} | pass insert --force --multiline infra/{hostname}/root"

STATIC_PUBLIC_NETWORK_CFG_TEMPLATE = """
d-i netcfg/disable_autoconfig boolean true
d-i netcfg/get_ipaddress string {public_ip}
d-i netcfg/get_netmask string {public_netmask}
d-i netcfg/get_gateway string {public_gateway}
d-i netcfg/get_nameservers string {public_dns}
d-i netcfg/confirm_static boolean true"""

STATIC_PRIVATE_NETWORK_CFG_TEMPLATE = """
d-i netcfg/disable_autoconfig boolean true
d-i netcfg/get_ipaddress string {private_ip}
d-i netcfg/get_netmask string {private_netmask}
d-i netcfg/get_gateway string {private_gateway}
d-i netcfg/get_nameservers string {private_dns}
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
    parser.add_argument("--private-ip", help="IP of the private interface", required=True)
    parser.add_argument("--preseed-template", help="Preseeding file template", required=True)
    parser.add_argument("--ram", help="RAM amount", type=int, default=2048)
    parser.add_argument("--cores", help="Number of virtual CPU cores", type=int, default=1)
    parser.add_argument("--sockets", help="Number of virtual CPU sockets", type=int, default=1)
    parser.add_argument("--disk-specs", help="Disk specifications (<storage unit>:size)", action="append", required=True)
    parser.add_argument("--vmid", help="Virtual machine ID", type=int, required=True)
    parser.add_argument("--startup", help="Startup settings", default="order=4")

    args = parser.parse_args()

    if args.public_ip:
        network_tpl = STATIC_PUBLIC_NETWORK_CFG_TEMPLATE
        domain = 'softwareheritage.org'
    else:
        network_tpl = STATIC_PRIVATE_NETWORK_CFG_TEMPLATE
        domain = 'internal.softwareheritage.org'

    preseed_template_vars = {}
    preseed_template_vars["hostname"] = args.hostname
    preseed_template_vars["domain"] = domain
    preseed_file = "preseed_{hostname}.cfg".format(hostname=args.hostname)

    network_vars = args.__dict__
    network_vars.update({
        'private_netmask': '255.255.255.0',
        'private_gateway': '192.168.100.1',
        'private_dns': '192.168.100.29',
    })

    preseed_template_vars["netconfig"] = network_tpl.format(**network_vars)

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
    virt_template_vars['hostname'] = args.hostname
    virt_template_vars['ram'] = args.ram
    virt_template_vars['cores'] = args.cores
    virt_template_vars['sockets'] = args.sockets
    virt_template_vars['preseed_file'] = preseed_file
    virt_template_vars['vmid'] = args.vmid
    virt_template_vars['startup'] = args.startup

    # disk configuration: one disk added per partition
    disk_configs = []
    disk_commands = []
    type = 'scsi'
    typeindex = 0
    volumeindexes = defaultdict(lambda: 1)

    for i, disk_spec in enumerate(args.disk_specs):
        volume, size = disk_spec.split(':')
        tpl_vars = {
            'type': type,
            'typeindex': typeindex,
            'volume': volume,
            'vmid': args.vmid,
            'volumeindex': volumeindexes[volume],
            'size': size,
        }
        disk_configs.append(DISK_CFG.format(**tpl_vars))
        disk_commands.append(DISK_CREATE_CMD.format(**tpl_vars))
        typeindex += 1
        volumeindexes[volume] += 1

        # Maximum 14 scsi volumes
        if i > 13:
            type = 'virtio'
            typeindex = 0

    virt_template_vars["disks"] = " ".join(disk_configs)

    # network configuration: one network card per networks, public then private
    # public on vmbr1
    # private on vmbr0
    networks = []
    if args.public_ip:
        networks.append(('vmbr1', args.public_mac))
    networks.append(('vmbr0', args.private_mac))
    virt_template_vars["networks"] = " ".join(
        NETWORK_CFG.format(bridge=bridge, mac=mac, netindex=index)
        for index, (bridge, mac) in enumerate(networks)
    )

    print("# >>>>> Local")
    pass_command = PASS_INSTALL_CMD.format(password=password, hostname=args.hostname)
    print(pass_command)
    scp_command = "scp preseed_{hostname}.cfg {hypervisor}.internal.softwareheritage.org:/tmp"

    for hypervisor in ["louvre", "beaubourg"]:
        print(scp_command.format(hostname=args.hostname, hypervisor=hypervisor))

    print()
    print("# >>>>> Remote on hypervisor")
    cpio_command = CPIO_CMDS.format(**virt_template_vars)
    print(cpio_command)

    qm_create_command = QM_CREATE_CMD.format(**virt_template_vars)
    print(qm_create_command)

    for command in disk_commands:
        print(command)

    qm_start_command = """\
qm start {vmid}
while qm status {vmid} | grep -q running; do sleep 10; done
qm set {vmid} -delete args
qm start {vmid}""".format(**virt_template_vars)
    print(qm_start_command)
