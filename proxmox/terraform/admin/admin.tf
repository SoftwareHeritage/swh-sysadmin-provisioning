module "bardo" {
  source = "../modules/node"
  config = local.config

  hostname    = "bardo"
  description = "Hedgedoc instance"
  hypervisor  = "branly"
  vmid        = 124
  cores       = "2"
  memory      = "8192"
  balloon     = 1024
  full_clone  = true
  networks = [{
    id      = 0
    ip      = "192.168.50.10"
    gateway = local.config["gateway_ip"]
    macaddr = "7A:CE:A2:72:FA:E8"
    bridge  = local.config["bridge"]
  }]
}


module "rp1" {
  source = "../modules/node"
  config = local.config

  hostname    = "rp1"
  description = "reverse-proxy"
  hypervisor  = "branly"
  vmid        = 115
  cores       = 2
  memory      = 4096
  balloon     = 1024
  full_clone  = true
  networks = [{
    id      = 0
    ip      = "192.168.50.20"
    gateway = local.config["gateway_ip"]
    macaddr = "4E:42:20:E0:B6:65"
    bridge  = local.config["bridge"]
   }]
}


module "dali" {
  source = "../modules/node"
  config = local.config

  template    = var.templates["bullseye"]
  hostname    = "dali"
  description = "admin databases host"
  hypervisor  = "branly"
  vmid        = 144
  cores       = 4
  memory      = 16384
  balloon     = 8192
  networks = [{
    id      = 0
    ip      = "192.168.50.50"
    gateway = local.config["gateway_ip"]
    macaddr = "C2:7C:85:D0:E8:7C"
    bridge  = local.config["bridge"]
   }]
  storages = [
    {
      id      = 0
      storage = "proxmox"
      size    = "32G"
    },
    {
      id      = 1
      storage = "proxmox"
      size    = "350G"
    }
  ]
}

output "dali_summary" {
  value = module.dali.summary
}

module "grafana0" {
  source = "../modules/node"
  config = local.config

  template    = var.templates["bullseye"]
  hostname    = "grafana0"
  description = "Grafana server"
  hypervisor  = "branly"
  vmid        = 108
  cores       = 4
  memory      = 4096
  balloon     = 2048
  networks = [{
    id      = 0
    ip      = "192.168.50.30"
    gateway = local.config["gateway_ip"]
    macaddr = "B2:CB:D9:09:D3:3B"
    bridge  = local.config["bridge"]
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
      interface         = "virtio0"
      size              = 20
    }]
}

output "bojimans_summary" {
  value = module.bojimans.summary
}

module "money" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "chaillot"
  onboot      = true
  vmid        = 140
  hostname    = "money"
  description = "Azure billing reporting server"

  cpu = {
    cores   = 1
    sockets = 2
    type    = "host"
  }

  ram = {
    dedicated = 2048
    floating  = 1024
  }

  network = {
    ip          = "192.168.50.65"
    mac_address = "BE:45:F5:C3:BD:A3"
  }

  disks = [{
      interface         = "virtio0"
      size              = 20
    }]
}

output "money_summary" {
  value = module.money.summary
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
      interface         = "virtio0"
      size              = 50
    }]
}

output "thanos_summary" {
  value = module.thanos.summary
}

