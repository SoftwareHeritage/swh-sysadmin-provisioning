module "bardo" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "chaillot"
  onboot      = true
  vmid        = 124
  hostname    = "bardo"
  description = "Hedgedoc instance"

  cpu = {
    cores = 2
  }

  ram = {
    dedicated = 8192
  }

  network = {
    ip          = "192.168.50.10"
    mac_address = "7A:CE:A2:72:FA:E8"
  }

  disks = [{
      interface = "virtio0"
    }]
}

output "bardo_summary" {
  value = module.bardo.summary
}

module "rp1" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "mucem"
  onboot      = true
  vmid        = 115
  hostname    = "rp1"
  description = "reverse-proxy"

  cpu = {
    cores = 2
  }

  network = {
    ip          = "192.168.50.20"
    mac_address = "4E:42:20:E0:B6:65"
  }

  disks = [{
      interface = "virtio0"
    }]
}

output "rp1_summary" {
  value = module.rp1.summary
}

module "dali" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "mucem"
  onboot      = true
  vmid        = 144
  hostname    = "dali"
  description = "admin databases host"

  ram = {
    dedicated = 16384
    floating  = 8192
  }

  network = {
    ip          = "192.168.50.50"
    mac_address = "C2:7C:85:D0:E8:7C"
  }

  disks = [{
      interface = "virtio0"
    },
    {
      interface = "virtio1"
      size      = 350
    }]
}

output "dali_summary" {
  value = module.dali.summary
}

module "grafana0" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "chaillot"
  onboot      = true
  vmid        = 108
  hostname    = "grafana0"
  description = "Grafana server"

  ram = {
    floating = 2048
  }

  network = {
    ip          = "192.168.50.30"
    mac_address = "B2:CB:D9:09:D3:3B"
  }

  disks = [{
      interface = "virtio0"
    }]
}

output "grafana0_summary" {
  value = module.grafana0.summary
}

module "bojimans" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "mucem"
  onboot      = true
  vmid        = 127
  hostname    = "bojimans"
  description = "Inventory server (netbox)"

  cpu = {
    cores   = 1
    sockets = 2
  }

  ram = {
    floating = 2048
  }

  network = {
    ip          = "192.168.50.60"
    mac_address = "EE:ED:A6:A0:78:9F"
    queues      = 1
  }

  disks = [{
      interface = "virtio0"
      size      = 20
    }]
}

output "bojimans_summary" {
  value = module.bojimans.summary
}


module "thanos" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "chaillot"
  onboot      = true
  vmid        = 158
  hostname    = "thanos"
  description = "Thanos query service"

  ram = {
    dedicated = 32768
    floating  = 0
  }

  network = {
    ip          = "192.168.50.90"
    mac_address = "16:3C:72:26:70:34"
  }

  disks = [{
      interface = "virtio0"
      size      = 100
    }]
}

output "thanos_summary" {
  value = module.thanos.summary
}
