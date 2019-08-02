resource "proxmox_vm_qemu" "node" {
    name              = "${var.hostname}"
    desc              = "${var.description}"
    # hypervisor onto which make the vm
    target_node       = "${var.hypervisor}"
    # See init-template.md to see the template vm bootstrap
    clone             = "${var.template}"
    # linux kernel 2.6
    qemu_os           = "l26"
    # generic setup
    sockets           = "${var.sockets}"
    cores             = "${var.cores}"
    memory            = "${var.memory}"
    # boot machine when hypervirsor starts
    onboot            = true
    #### cloud-init setup
    os_type           = "cloud-init"
    # ciuser - User name to change to use when connecting
    ciuser            = "${var.config["user_admin"]}"
    ssh_user          = "${var.config["user_admin"]}"
    # sshkeys - public ssh key to use when connecting
    sshkeys           = "${var.config["user_admin_ssh_public_key"]}"
    # searchdomain - Sets DNS search domains for a container.
    searchdomain      = "${var.config["domain"]}"
    # nameserver - Sets DNS server IP address for a container.
    nameserver        = "${var.config["dns"]}"
    # ipconfig0 - [gw =] [,ip=<IPv4Format/CIDR>]
    ipconfig0         = "ip=${var.network["ip"]}/24,gw=${var.config["gateway_ip"]}"
    ####
    disk {
        id           = 0
        type         = "virtio"
        storage      = "${var.storage["location"]}"
        storage_type = "ssd"
        size         = "${var.storage["size"]}"
    }
    network {
        id      = 0
        model   = "virtio"
        bridge  = "vmbr0"
        macaddr = "${lookup(var.network, "macaddr", "")}"
    }

    #### provisioning: (creation time only) connect through ssh
    # Let puppet do its install
    provisioner "remote-exec" {
        inline = [
            "sed -i 's/127.0.1.1/${var.network["ip"]}/g' /etc/hosts",
            "puppet agent --server ${var.config["puppet_master"]} --environment=${var.config["puppet_environment"]} --waitforcert 60 --test || echo 'Node provisionned!'",
        ]
    }
}
