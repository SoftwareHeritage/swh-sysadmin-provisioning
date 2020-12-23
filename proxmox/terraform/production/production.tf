locals {
  config = {
    dns                             = var.dns
    domain                          = "internal.softwareheritage.org"
    puppet_environment              = "production"
    facter_deployment               = "production"
    facter_subnet                   = "sesi_rocquencourt"
    puppet_master                   = var.puppet_master
    gateway_ip                      = "192.168.100.1"
    user_admin                      = var.user_admin
    user_admin_ssh_public_key       = var.user_admin_ssh_public_key
    user_admin_ssh_private_key_path = var.user_admin_ssh_private_key_path
  }
}

module "kelvingrove" {
  source = "../modules/node"
  config = local.config

  hostname    = "kelvingrove"
  description = "Keycloak server"
  hypervisor  = "hypervisor3"
  vmid        = 123
  cores       = "4"
  memory      = "8192"
  numa        = true
  balloon     = 0
  networks = [{
    id      = 0
    ip      = "192.168.100.106"
    gateway = local.config["gateway_ip"]
    macaddr = "72:55:5E:58:01:0B"
    bridge  = "vmbr0"
  }]
}

module "webapp1" {
  source = "../modules/node"
  config = local.config

  hostname    = "webapp1"
  description = "Webapp for swh-search tests"
  hypervisor  = "branly"
  vmid        = 125
  cores       = "2"
  memory      = "8192"
  balloon     = 1024
  networks = [{
    id      = 0
    ip      = "192.168.100.71"
    gateway = local.config["gateway_ip"]
    macaddr = "06:FF:02:95:31:CF"
    bridge  = "vmbr0"
  }]
}

module "search-esnode1" {
  source = "../modules/node"
  config = local.config

  hostname    = "search-esnode1"
  description = "Elasticsearch node for swh-search"
  hypervisor  = "branly"
  vmid        = 133
  cores       = "4"
  memory      = "16384"
  balloon     = 9216
  networks = [{
    id      = 0
    ip      = "192.168.100.81"
    gateway = local.config["gateway_ip"]
    macaddr = "42:31:70:6A:D7:F9"
    bridge  = "vmbr0"
  }]
  storages = [{
    id           = 0
    storage      = "proxmox"
    size         = "32G"
    storage_type = "cephfs"
  }, {
    id           = 1
    storage      = "proxmox"
    size         = "200G"
    storage_type = "cephfs"
  }]
}

module "search-esnode2" {
  source = "../modules/node"
  config = local.config

  hostname    = "search-esnode2"
  description = "Elasticsearch node for swh-search"
  hypervisor  = "branly"
  vmid        = 134
  cores       = "4"
  memory      = "16384"
  balloon     = 9216
  networks = [{
    id      = 0
    ip      = "192.168.100.82"
    gateway = local.config["gateway_ip"]
    macaddr = "AA:86:8C:84:59:B5"
    bridge  = "vmbr0"
  }]
  storages = [{
    id           = 0
    storage      = "proxmox"
    size         = "32G"
    storage_type = "cephfs"
  }, {
    id           = 1
    storage      = "proxmox"
    size         = "200G"
    storage_type = "cephfs"
  }]
}

module "search-esnode3" {
  source = "../modules/node"
  config = local.config

  hostname    = "search-esnode3"
  description = "Elasticsearch node for swh-search"
  hypervisor  = "beaubourg"
  vmid        = 135
  cores       = "4"
  memory      = "16384"
  balloon     = 9216
  networks = [{
    id      = 0
    ip      = "192.168.100.83"
    gateway = local.config["gateway_ip"]
    macaddr = "36:E4:58:9B:EA:E4"
    bridge  = "vmbr0"
  }]
  storages = [{
    id           = 0
    storage      = "proxmox"
    size         = "32G"
    storage_type = "cephfs"
  }, {
    id           = 1
    storage      = "proxmox"
    size         = "200G"
    storage_type = "cephfs"
  }]
}

module "search1" {
  source = "../modules/node"
  config = local.config

  hostname    = "search1"
  description = "swh-search node"
  hypervisor  = "branly"
  vmid        = 136
  cores       = "4"
  memory      = "3072"
  balloon     = 1024
  networks = [{
    id      = 0
    ip      = "192.168.100.85"
    gateway = local.config["gateway_ip"]
    macaddr = "3E:46:D3:88:44:F4"
    bridge  = "vmbr0"
  }]
}
