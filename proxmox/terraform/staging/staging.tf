# Keyword use:
# - provider: Define the provider(s)
# - data: Retrieve data information to be used within the file
# - resource: Define resource and create/update

# Default configuration passed along module calls
# (There is no other way to avoid duplication)
locals {
  config = {
    dns                       = var.dns
    domain                    = var.domain
    puppet_environment        = var.puppet_environment
    puppet_master             = var.puppet_master
    gateway_ip                = var.gateway_ip
    user_admin                = var.user_admin
    user_admin_ssh_public_key = var.user_admin_ssh_public_key
  }
}

module "storage0" {
  source = "../modules/node"
  config = local.config
  hypervisor = "orsay"

  vmid        = 114
  hostname    = "storage0"
  description = "swh storage services"
  cores       = "4"
  memory      = "8192"
  balloon     = 1024
  networks = [{
    id      = 0
    ip      = "192.168.130.40"
    gateway = local.config["gateway_ip"]
    macaddr = "CA:73:7F:ED:F9:01"
    bridge  = "vmbr443"
  }]
  storages = [{
    id           = 0
    storage      = "orsay-ssd-2018"
    size         = "32G"
    storage_type = "ssd"
  }, {
    id           = 1
    storage      = "orsay-ssd-2018"
    size         = "812G"
    storage_type = "ssd"
  }]
}

module "db0" {
  source = "../modules/node"
  config = local.config
  hypervisor = "orsay"

  vmid        = 115
  hostname    = "db0"
  description = "Node to host storage/indexer/scheduler dbs"
  cores       = "4"
  memory      = "16384"
  balloon     = 1024
  networks = [{
    id      = 0
    ip      = "192.168.130.10"
    gateway = local.config["gateway_ip"]
    macaddr = "3A:65:31:7C:24:17"
    bridge  = "vmbr443"
  }]
  storages = [{
    id           = 0
    storage      = "orsay-ssd-2018"
    size         = "400G"
    storage_type = "ssd"
  }]

}

output "db0_summary" {
  value = module.db0.summary
}

module "scheduler0" {
  source = "../modules/node"
  config = local.config

  vmid        = 116
  hostname    = "scheduler0"
  description = "Scheduler api services"
  hypervisor  = "beaubourg"
  cores       = "4"
  memory      = "8192"
  balloon     = 1024
  networks = [{
    id      = 0
    ip      = "192.168.130.50"
    gateway = local.config["gateway_ip"]
    macaddr = "92:02:7E:D0:B9:36"
    bridge  = "vmbr443"
  }]
}

output "scheduler0_summary" {
  value = module.scheduler0.summary
}

module "worker0" {
  source = "../modules/node"
  config = local.config

  vmid        = 117
  hostname    = "worker0"
  description = "Loader/lister service node"
  hypervisor  = "beaubourg"
  cores       = "4"
  memory      = "12288"
  balloon     = 1024
  networks = [{
    id      = 0
    ip      = "192.168.130.100"
    gateway = local.config["gateway_ip"]
    macaddr = "72:D9:03:46:B1:47"
    bridge  = "vmbr443"
  }]
}

output "worker0_summary" {
  value = module.worker0.summary
}

module "worker1" {
  source = "../modules/node"
  config = local.config

  vmid        = 118
  hostname    = "worker1"
  description = "Loader/lister service node"
  hypervisor  = "beaubourg"
  cores       = "4"
  memory      = "12288"
  balloon     = 1024
  networks = [{
    id      = 0
    ip      = "192.168.130.101"
    gateway = local.config["gateway_ip"]
    macaddr = "D6:A9:6F:02:E3:66"
    bridge  = "vmbr443"
  }]
}

output "worker1_summary" {
  value = module.worker1.summary
}

module "worker2" {
  source = "../modules/node"
  config = local.config

  vmid        = 112
  hostname    = "worker2"
  description = "Loader/lister service node"
  hypervisor = "branly"
  cores       = "4"
  memory      = "12288"
  balloon     = 1024
  networks = [{
    id      = 0
    ip      = "192.168.130.102"
    gateway = local.config["gateway_ip"]
    macaddr = "AA:57:27:51:75:18"
    bridge  = "vmbr443"
  }]
}

output "worker2_summary" {
  value = module.worker2.summary
}

module "webapp" {
  source = "../modules/node"
  config = local.config

  vmid        = 119
  hostname    = "webapp"
  description = "Archive/Webapp service node"
  hypervisor  = "branly"
  cores       = "4"
  memory      = "16384"
  balloon     = 1024
  networks = [{
    id      = 0
    ip      = "192.168.130.30"
    gateway = local.config["gateway_ip"]
    macaddr = "1A:00:39:95:D4:5F"
    bridge  = "vmbr443"
  }]
}

output "webapp_summary" {
  value = module.webapp.summary
}

module "deposit" {
  source = "../modules/node"
  config = local.config

  vmid        = 120
  hostname    = "deposit"
  description = "Deposit service node"
  hypervisor  = "beaubourg"
  cores       = "4"
  memory      = "8192"
  balloon     = 1024
  networks = [{
    id      = 0
    ip      = "192.168.130.31"
    gateway = local.config["gateway_ip"]
    macaddr = "9E:81:DD:58:15:3B"
    bridge  = "vmbr443"
  }]
}

output "deposit_summary" {
  value = module.deposit.summary
}

module "vault" {
  source = "../modules/node"
  config = local.config

  vmid        = 121
  hostname    = "vault"
  description = "Vault services node"
  hypervisor  = "beaubourg"
  cores       = "4"
  memory      = "8192"
  balloon     = 1024
  networks = [{
    id      = 0
    ip      = "192.168.130.60"
    gateway = local.config["gateway_ip"]
    macaddr = "16:15:1C:79:CB:DB"
    bridge  = "vmbr443"
  }]
}

output "vault_summary" {
  value = module.vault.summary
}

module "journal0" {
  source = "../modules/node"
  config = local.config

  vmid        = 122
  hostname    = "journal0"
  description = "Journal services node"
  hypervisor  = "beaubourg"
  cores       = "4"
  memory      = "12288"
  balloon     = 1024
  networks = [{
    id      = 0
    ip      = "192.168.130.70"
    gateway = local.config["gateway_ip"]
    macaddr = "1E:98:C2:66:BF:33"
    bridge  = "vmbr443"
  }]
}

output "journal0_summary" {
  value = module.journal0.summary
}
