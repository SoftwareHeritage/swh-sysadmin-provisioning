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
  cores       = "4"
  memory      = "8192"
  cpu         = "host"
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
  cores       = "2"
  memory      = "8192"
  balloon     = 2048
  networks = [{
    id      = 0
    ip      = "192.168.100.71"
    gateway = local.config["gateway_ip"]
    macaddr = "06:FF:02:95:31:CF"
    bridge  = "vmbr0"
  }]
}

module "search1" {
  source = "../modules/node"
  config = local.config

  hostname    = "search1"
  description = "swh-search node"
  hypervisor  = "branly"
  cores       = "4"
  memory      = "6144"
  balloon     = 1024
  networks = [{
    id      = 0
    ip      = "192.168.100.85"
    gateway = local.config["gateway_ip"]
    macaddr = "3E:46:D3:88:44:F4"
    bridge  = "vmbr0"
  }]
}

module "counters1" {
  source = "../modules/node"
  config = local.config

  hostname    = "counters1"
  description = "swh-counters node"
  hypervisor  = "branly"
  cores       = "4"
  memory      = "2048"
  balloon     = 1024
  networks = [{
    id      = 0
    ip      = "192.168.100.95"
    gateway = local.config["gateway_ip"]
    macaddr = "26:8E:7F:D1:F7:99"
    bridge  = "vmbr0"
  }]
}

module "worker17" {
  source = "../modules/node"
  config = local.config

  hostname    = "worker17"
  domainname  = "softwareheritage.org"
  description = "swh-worker node (temporary)"
  hypervisor  = "uffizi"
  cores       = "5"
  sockets     = "2"
  memory      = "49152"
  balloon     = 1024
  networks = [{
    id      = 0
    ip      = "192.168.100.43"
    gateway = local.config["gateway_ip"]
    macaddr = "36:E0:2D:70:7C:52"
    bridge  = "vmbr0"
  }]
}

module "worker18" {
  source = "../modules/node"
  config = local.config

  hostname    = "worker18"
  domainname  = "softwareheritage.org"
  description = "swh-worker node (temporary)"
  hypervisor  = "uffizi"
  cores       = "5"
  sockets     = "2"
  memory      = "49152"
  balloon     = 1024
  networks = [{
    id      = 0
    ip      = "192.168.100.44"
    gateway = local.config["gateway_ip"]
    macaddr = "C6:29:D9:ED:9C:6B"
    bridge  = "vmbr0"
  }]
}

output "worker18_summary" {
  value = module.worker18.summary
}


module "provenance-client01" {
  source = "../modules/node"
  config = local.config

  hostname    = "provenance-client01"
  description = "Provenance client"
  template    = "debian-bullseye-11.2-2022-01-03"
  hypervisor  = "uffizi"
  cores       = "4"
  sockets     = "4"
  memory      = "131072"
  balloon     = 32768
  networks = [{
    id      = 0
    ip      = "192.168.100.111"
    gateway = local.config["gateway_ip"]
    macaddr = null
    bridge  = "vmbr0"
  }]
}
