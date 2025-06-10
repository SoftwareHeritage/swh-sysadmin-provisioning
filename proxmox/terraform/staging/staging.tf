module "scheduler0" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "branly"
  onboot      = true
  vmid        = 116
  hostname    = "scheduler0"
  description = "Scheduler api services"

  # to match the real vm configuration in proxmox to remove
  kvm_args    = "-device virtio-rng-pci"

  ram = {
    dedicated = 8192
  }

  network = {
    ip          = "192.168.130.50"
    mac_address = "92:02:7E:D0:B9:36"
  }

  disks = [{
    path_in_datastore = "vm-116-disk-1"
  }]
}

output "scheduler0_summary" {
  value = module.scheduler0.summary
}

module "rp0" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "branly"
  onboot      = true
  vmid        = 129
  hostname    = "rp0"
  description = "Node to host the reverse proxy"

  cpu = {
    cores = 2
  }

  ram = {
    dedicated = 2048
    floating  = 1024
  }

  network = {
    ip          = "192.168.130.20"
    mac_address = "4A:80:47:5D:DF:73"
  }
}

output "rp0_summary" {
  value = module.rp0.summary
}

module "search-esnode0" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "chaillot"
  onboot      = true
  vmid        = 130
  hostname    = "search-esnode0"
  description = "Node to host the elasticsearch instance"

  ram = {
    dedicated = 32768
    floating  = 9216
  }

  network = {
    ip          = "192.168.130.80"
    mac_address = "96:74:49:BD:B5:08"
  }

  disks = [
    {
      interface = "virtio0"
      size      = 32
    },
    {
      interface = "virtio1"
      size      = 200
    }
  ]
}

output "search-esnode0_summary" {
  value = module.search-esnode0.summary
}

module "counters0" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "branly"
  onboot      = true
  vmid        = 138
  hostname    = "counters0"
  description = "Counters server"

  ram = {
    dedicated = 6096
    floating  = 2048
  }

  network = {
    ip          = "192.168.130.95"
    mac_address = "E2:6E:12:C7:3E:A4"
  }
}

output "counters0_summary" {
  value = module.counters0.summary
}

module "runner0" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "branly"
  onboot      = true
  tags        = ["gitlab-runner"]

  vmid        = 148
  hostname    = "runner0"
  description = "Gitlab runner to process add-forge-now requests"

  cdrom = {
    interface = "ide2"
  }

  network = {
    ip          = "192.168.130.221"
    mac_address = "1A:4B:96:85:01:64"
  }

  disks = [{
      datastore_id      = "proxmox"
      interface         = "virtio0"
      size              = 20
      path_in_datastore = "base-10012-disk-0/vm-148-disk-0"
    },
    {
      datastore_id      = "proxmox"
      interface         = "virtio1"
      size              = 30
      path_in_datastore = "vm-148-disk-1"
    }]
}

output "runner0_summary" {
  value = module.runner0.summary
}

module "runner1" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "chaillot"
  onboot      = true
  tags        = ["gitlab-runner"]

  hostname    = "runner1"
  description = "Gitlab runner for code-commons wp1 ci"

  template = "bookworm-zfs"

  network = {
    ip          = "192.168.130.220"
    mac_address = "BC:24:11:F1:44:37"
  }

  disks = [{
      datastore_id      = "proxmox"
      interface         = "virtio0"
      size              = 20
    },
    {
      datastore_id      = "proxmox"
      interface         = "virtio1"
      size              = 30
    }]
}

output "runner1_summary" {
  value = module.runner1.summary
}

module "maven-exporter0" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "chaillot"
  onboot      = true
  vmid        = 122
  hostname    = "maven-exporter0"
  description = "Maven index exporter to run containers and expose export.fld files"

  network = {
    ip          = "192.168.130.70"
    mac_address = "36:86:F6:F9:2A:5D"
  }

  disks = [{
      datastore_id      = "proxmox"
      interface         = "virtio0"
      size              = 20
      path_in_datastore = "base-10005-disk-0/vm-122-disk-0"
    },
    {
      datastore_id      = "proxmox"
      interface         = "virtio1"
      size              = 50
      path_in_datastore = "vm-122-disk-1"
    }]
}

output "maven-exporter0_summary" {
  value = module.maven-exporter0.summary
}
