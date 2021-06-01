resource "proxmox_vm_qemu" "node" {
  name = var.hostname
  desc = var.description
  vmid = var.vmid

  balloon = var.balloon
  full_clone = false
  # hypervisor onto which make the vm
  target_node = var.hypervisor

  # See init-template.md to see the template vm bootstrap
  clone = var.template

  boot = "c"

  # linux kernel 2.6
  qemu_os = "l26"

  # generic setup
  sockets = var.sockets
  cores   = var.cores
  numa    = var.numa
  memory  = var.memory

  # boot machine when hypervirsor starts
  onboot = true

  #### cloud-init setup
  os_type = "cloud-init"

  # ciuser - User name to change to use when connecting
  ciuser   = var.config["user_admin"]
  cicustom = var.cicustom
  ssh_user = var.config["user_admin"]

  # sshkeys - public ssh key to use when connecting
  sshkeys = var.config["user_admin_ssh_public_key"]

  # searchdomain - Sets DNS search domains for a container.
  searchdomain = var.domainname != "" ? var.domainname : var.config["domain"]

  # nameserver - Sets DNS server IP address for a container.
  nameserver = var.config["dns"]

  # ipconfig0 - [gw =] [,ip=<IPv4Format/CIDR>]
  ipconfig0 = "ip=${var.networks[0]["ip"]}/24,gw=${var.networks[0]["gateway"]}"

  # Mostly, var.networks holds only one network declaration except for gateways
  # Try to lookup such value, if it fails (or is undefined), then ipconfig1
  # will be empty, thus no secondary ip config
  ipconfig1 = try(lookup(var.networks[1], "ip"), "") != "" ? "ip=${var.networks[1]["ip"]}/24" : ""

  ####
  dynamic disk {
    for_each = var.storages

    content {
      id           = disk.value["id"]
      storage      = disk.value["storage"]
      size         = disk.value["size"]
      type         = "virtio"
      # storage_type: https://pve.proxmox.com/wiki/Storage
      storage_type = lookup(disk.value, "storage_type", "cephfs")
    }
  }

  dynamic network {
    for_each = var.networks

    content {
      id      = lookup(network.value, "id", 0)
      macaddr = lookup(network.value, "macaddr", "")
      bridge  = lookup(network.value, "bridge", "vmbr443")
      model   = "virtio"
    }
  }

  #### provisioning: (creation time only) connect through ssh

  # Let puppet do its install
  provisioner "remote-exec" {
    inline = concat(
      var.pre_provision_steps,
      [
        # First install facts...
        "mkdir -p /etc/facter/facts.d",
        "echo deployment=${var.config["facter_deployment"]} > /etc/facter/facts.d/deployment.txt",
        "echo subnet=${var.config["facter_subnet"]} > /etc/facter/facts.d/subnet.txt",
        "sed -i 's/127.0.1.1/${lookup(var.networks[0], "ip")}/g' /etc/hosts",
        # so puppet agent installs the node's role
        "puppet agent --server ${var.config["puppet_master"]} --environment=${var.config["puppet_environment"]} --waitforcert 60 --test || echo 'Node provisionned!'",
      ])

    connection {
      type        = "ssh"
      user        = "root"
      host        = lookup(var.networks[0], "ip")
      private_key = file(var.config["user_admin_ssh_private_key_path"])
    }
  }

  lifecycle {
    ignore_changes = [
      bootdisk,
      scsihw,
      target_node,
      clone
    ]
  }
}
