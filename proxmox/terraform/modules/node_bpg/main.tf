resource "proxmox_virtual_environment_vm" "node" {
  provider      = bpg-proxmox
  name          = var.hostname
  description   = var.description
  node_name     = var.hypervisor
  vm_id         = var.vmid
  tags          = var.tags
  on_boot       = var.onboot
  kvm_arguments = var.kvm_args != "" ? var.kvm_args : ""

  clone {
    vm_id = var.template
  }

  cpu {
    sockets   = lookup(var.cpu, "sockets", 1)
    cores     = lookup(var.cpu, "cores", 4)
    type      = lookup(var.cpu, "type", "kvm64")
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
    mac_address  = lookup(var.network, "mac_address", "")
    bridge       = lookup(var.network, "bridge", "vmbr443")
    model        = "virtio"
    disconnected = false
    enabled      = true
  }

  initialization {

    # Cloud-init pool storage (see Cloudinit Drive in VM Hardware section).
    datastore_id = lookup(var.cloudinit-drive, "datastore_id", "proxmox")
    interface    = lookup(var.cloudinit-drive, "interface", "ide0")
    ip_config {
      ipv4 {
        address = format("%s/%s", var.network["ip"], lookup(var.network, "netmask", "24"))
        gateway = var.network["gateway"]
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

  lifecycle {
    ignore_changes = [
      clone
    ]
  }
}
