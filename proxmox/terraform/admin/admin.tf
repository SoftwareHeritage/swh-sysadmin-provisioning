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
  source = "../modules/node"
  config = local.config

  template    = var.templates["bullseye"]
  hostname    = "bojimans"
  description = "Inventory server (netbox)"
  hypervisor  = "branly"
  cpu         = "kvm64"
  vmid        = 127
  sockets     = 2
  cores       = 1
  memory      = 4096
  balloon     = 2048
  networks = [{
    id      = 0
    ip      = "192.168.50.60"
    gateway = "192.168.50.1"
    macaddr = "EE:ED:A6:A0:78:9F"
    bridge  = local.config["bridge"]
  }]
  storages = [{
    id      = 0
    storage = "proxmox"
    size    = "20G"
  }]
}

output "bojimans_summary" {
  value = module.bojimans.summary
}

module "money" {
  source = "../modules/node"
  config = local.config

  template    = var.templates["bullseye"]
  hostname    = "money"
  description = "Azure billing reporting server"
  hypervisor  = "branly"
  # chromium (used by selenium to download the azure data) needs sse3 instructions not available
  # by default n kvm64
  cpu         = "host"
  vmid        = 140
  sockets     = 2
  cores       = 1
  memory      = 2048
  balloon     = 1024
  networks = [{
    id      = 0
    ip      = "192.168.50.65"
    gateway = "192.168.50.1"
    macaddr = ""
    bridge  = local.config["bridge"]
  }]
  storages = [{
    id      = 0
    storage = "proxmox"
    size    = "20G"
  }]
}

output "money_summary" {
  value = module.money.summary
}

module "thanos" {
  source      = "../modules/node"
  config      = local.config
  onboot      = true
  template    = var.templates["bullseye"]

  hostname    = "thanos"
  description = "Thanos query service"
  hypervisor  = "branly"
  sockets     = "1"
  cores       = "4"
  memory  = "8192"
  balloon = "4096"

  networks = [{
    id      = 0
    ip      = "192.168.50.90"
    gateway = local.config["gateway_ip"]
    macaddr = "16:3C:72:26:70:34"
    bridge  = local.config["bridge"]
  }]

  storages = [{
    id      = 0
    storage = "proxmox"
    size    = "32G"
  }]
}

output "thanos_summary" {
  value = module.thanos.summary
}
