# Keyword use:
# - provider: Define the provider(s)
# - data: Retrieve data information to be used within the file
# - resource: Define resource and create/update

provider "proxmox" {
    pm_tls_insecure = true
    pm_api_url      = "https://orsay.internal.softwareheritage.org:8006/api2/json"
    # in a shell (see README): source ./setup.sh
}

# `pass search terraform-proxmox` in credential store
variable "ssh_key_data" {
  type    = "string"
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDVKCfpeIMg7GS3Pk03ZAcBWAeDZ+AvWk2k/pPY0z8MJ3YAbqZkRtSK7yaDgJV6Gro7nn/TxdJLo2jEzzWvlC8d8AEzhZPy5Z/qfVVjqBTBM4H5+e+TItAHFfaY5+0WvIahxcfsfaq70MWfpJhszAah3ThJ4mqzYaw+dkr42+a7Gx3Ygpb/m2dpnFnxvXdcuAJYStmHKU5AWGWWM+Fm50/fdMqUfNd8MbKhkJt5ihXQmZWMOt7ls4N8i5NZWnS9YSWow8X/ENOEqCRN9TyRkc+pPS0w9DNi0BCsWvSRJOkyvQ6caEnKWlNoywCmM1AlIQD3k4RUgRWe0vqg/UKPpH3Z root@terraform"
}

variable "user_admin" {
  type    = "string"
  default = "root"
}

variable "domain" {
  type    = "string"
  default = "internal.staging.swh.network"
}

variable "puppet_environment" {
  type    = "string"
  default = "new_staging"
}

variable "puppet_master" {
  type    = "string"
  default = "pergamon.internal.softwareheritage.org"
}

variable "dns" {
  type    = "string"
  default = "192.168.100.29"
}

variable "gateway_ip" {
  type    = "string"
  default = "192.168.128.1"
}

resource "proxmox_vm_qemu" "gateway" {
    name              = "gateway"
    desc              = "staging gateway node"
    # hypervisor onto which make the vm
    target_node       = "orsay"
    # See init-template.md to see the template vm bootstrap
    clone             = "template-debian-9"
    # linux kernel 2.6
    qemu_os           = "l26"
    # generic setup
    sockets           = 1
    cores             = 1
    memory            = 1024
    # boot machine when hypervirsor starts
    onboot            = true
    #### cloud-init setup
    # to actually set some information per os_type (values: ubuntu, centos,
    # cloud-init). Keep this as cloud-init
    os_type           = "cloud-init"
    # ciuser - User name to change ssh keys and password for instead of the
    # image’s configured default user.
    ciuser            = "${var.user_admin}"
    ssh_user          = "${var.user_admin}"
    # searchdomain - Sets DNS search domains for a container.
    searchdomain      = "${var.domain}"
    # nameserver - Sets DNS server IP address for a container.
    nameserver        = "${var.dns}"
    # sshkeys - public ssh keys, one per line
    sshkeys           = "${var.ssh_key_data}"
    # FIXME: When T1872 lands, this will need to be updated
    # ipconfig0 - [gw =] [,ip=<IPv4Format/CIDR>]
    # ip to communicate for now with the prod network through louvre
    ipconfig0         = "ip=192.168.100.125/24,gw=192.168.100.1"
    # vms from the staging network will use this vm as gateway
    ipconfig1         = "ip=${var.gateway_ip}/24"
    disk {
        id           = 0
        type         = "virtio"
        storage      = "orsay-ssd-2018"
        storage_type = "ssd"
        size         = "20G"
    }
    network {
        id      = 0
        model   = "virtio"
        bridge  = "vmbr0"
        macaddr = "6E:ED:EF:EB:3C:AA"
    }
    network {
        id      = 1
        model   = "virtio"
        bridge  = "vmbr0"
        macaddr = "FE:95:CC:A5:EB:43"
    }
    # Delegate to puppet at the end of the provisioning the software setup
    provisioner "remote-exec" {
        inline = [
            "sysctl -w net.ipv4.ip_forward=1",
            # make it persistent
            "sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf",
            # add route to louvre (the persistence part is done through puppet)
            "iptables -t nat -A POSTROUTING -s 192.168.128.0/24 -o eth0 -j MASQUERADE",
            "sed -i 's/127.0.1.1/${var.gateway_ip}/g' /etc/hosts",
            "puppet agent --server ${var.puppet_master} --environment=${var.puppet_environment} --waitforcert 60 --test || echo 'Node provisionned!'",
        ]
    }
}
