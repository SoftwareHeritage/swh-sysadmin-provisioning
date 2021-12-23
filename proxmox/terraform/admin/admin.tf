locals {
  config = {
    dns                             = var.dns
    domain                          = "internal.admin.swh.network"
    puppet_environment              = "production"
    facter_deployment               = "admin"
    facter_subnet                   = "sesi_rocquencourt_admin"
    puppet_master                   = var.puppet_master
    gateway_ip                      = "192.168.50.1"
    user_admin                      = var.user_admin
    user_admin_ssh_public_key       = var.user_admin_ssh_public_key
    user_admin_ssh_private_key_path = var.user_admin_ssh_private_key_path
    vlan                            = "vmbr442"
  }
}

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
    bridge  = local.config["vlan"]
  }]
}


module "rp1" {
  source = "../modules/node"
  config = local.config

  hostname    = "rp1"
  description = "reverse-proxy"
  hypervisor  = "branly"
  vmid        = 115
  cores       = "2"
  memory      = "4096"
  balloon     = 1024
  full_clone  = true
  networks = [{
    id      = 0
    ip      = "192.168.50.20"
    gateway = local.config["gateway_ip"]
    macaddr = "4E:42:20:E0:B6:65"
    bridge  = local.config["vlan"]
   }]
}


module "dali" {
  source = "../modules/node"
  config = local.config

  template    = "debian-bullseye-11.2-2022-01-03"
  hostname    = "dali"
  description = "admin databases host"
  hypervisor  = "branly"
  vmid        = 144
  cores       = "4"
  memory      = "16384"
  balloon     = 8192
  networks = [{
    id      = 0
    ip      = "192.168.50.50"
    gateway = local.config["gateway_ip"]
    macaddr = "C2:7C:85:D0:E8:7C"
    bridge  = local.config["vlan"]
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
      size    = "200G"
    }
  ]
}

output "dali_summary" {
  value = module.dali.summary
}


module "grafana0" {
  source = "../modules/node"
  config = local.config

  template    = "debian-bullseye-11.2-2022-01-03"
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
    bridge  = local.config["vlan"]
  }]
}

output "grafana0_summary" {
  value = module.grafana0.summary
}
