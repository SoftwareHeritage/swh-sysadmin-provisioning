resource "proxmox_virtual_environment_vm" "node" {
  provider      = bpg-proxmox
  name          = var.hostname
  description   = var.description
  node_name     = var.hypervisor
  vm_id         = var.vmid
  tags          = concat([var.config.facter_deployment], var.tags)
  on_boot       = var.onboot
  kvm_arguments = var.kvm_args != "" ? var.kvm_args : ""
  started       = var.started

  clone {
    node_name = var.template_node
    vm_id     = lookup(var.templates, "${var.template}")
  }

  cpu {
    sockets   = lookup(var.cpu, "sockets", 1)
    cores     = lookup(var.cpu, "cores", 4)
    type      = lookup(var.cpu, "type", "kvm64")
    numa      = lookup(var.cpu, "numa", false)
  }

  memory {
    dedicated = lookup(var.ram, "dedicated", 4096)
    floating  = lookup(var.ram, "floating", 1024)
  }

  agent {
    enabled = false
  }

  cdrom {
    file_id   = lookup(var.cdrom, "file_id", "none")
    interface = lookup(var.cdrom, "interface", "ide2")
  }

  operating_system {
    # linux kernel 2.6
    type = "l26"
  }

  dynamic disk {
    for_each = var.disks

    content {
      datastore_id      = lookup(disk.value, "datastore_id", "proxmox")
      interface         = lookup(disk.value, "interface", "virtio0")
      size              = lookup(disk.value, "size", 32)
      path_in_datastore = lookup(disk.value, "path_in_datastore", "")
      discard           = lookup(disk.value, "discard", "ignore")
      file_format       = lookup(disk.value, "file_format", "raw")
    }
  }

  network_device {
    mac_address  = var.network["mac_address"] != null ? var.network["mac_address"] : ""
    bridge       = var.network["bridge"] != null ? var.network["bridge"] : var.config["bridge"]
    model        = "virtio"
    disconnected = false
    enabled      = true
    queues       = var.network["queues"] != null ? var.network["queues"] : 0
  }

  initialization {

    # Cloud-init pool storage (see Cloudinit Drive in VM Hardware section).
    datastore_id = lookup(var.cloudinit-drive, "datastore_id", "proxmox")
    interface    = lookup(var.cloudinit-drive, "interface", "ide0")
    ip_config {
      ipv4 {
        address = format("%s/%s", var.network["ip"], (var.network["netmask"] != null ? var.network["netmask"] : "24"))
        gateway = var.network["gateway"] != null ? var.network["gateway"] : var.config["gateway_ip"]
      }
    }

    dns {
      domain  = var.domainname != "" ? var.domainname : var.config["domain"]
      servers = [var.config["dns"],]
    }

    user_account {
      keys     = [
        var.config["user_admin_ssh_public_key"],
      ]
      username = var.config["user_admin"]
    }
  }

  #### provisioning: (creation time only) connect through ssh

  # Prepare puppet facts, /etc/hosts and finally register node to puppet master
  provisioner "remote-exec" {
    inline = concat(
      var.pre_provision_steps,
      [
        # clean the systemd logs dating from the vm creation
        "journalctl --vacuum-time=1d",
        # delete unclean cdrom references in sources.list
        "sed -i.back '/.*/d' /etc/apt/sources.list",
        # install facts...
        "mkdir -p /etc/facter/facts.d",
        "echo deployment=${var.config["facter_deployment"]} > /etc/facter/facts.d/deployment.txt",
        "echo subnet=${var.config["facter_subnet"]} > /etc/facter/facts.d/subnet.txt",
        "echo cloudinit_enabled=true > /etc/facter/facts.d/cloud-init.txt",
        "sed -i 's/127.0.1.1/${var.network["ip"]}/g' /etc/hosts",
        # Wait for cloud-init to finish its work to avoid
        # concurrency on apt
        "cloud-init status -w",
        # so puppet agent installs the node's role
        "puppet agent --server ${var.config["puppet_master"]} --environment=${var.config["puppet_environment"]} --vardir=/var/lib/puppet --waitforcert 60 --test && echo 'Node provisioned!'",
      ],
      var.post_provision_steps,
    )

    connection {
      type        = "ssh"
      user        = "root"
      host        = var.network["ip"]
      private_key = file(var.config["user_admin_ssh_private_key_path"])
    }
  }

  lifecycle {
    ignore_changes = [
      clone,
      node_name
    ]
  }
}
