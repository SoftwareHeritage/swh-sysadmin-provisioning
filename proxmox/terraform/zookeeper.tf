module "zookeeper1" {
  source = "./modules/node"
  config = {
    dns                       = var.dns
    domain                    = "internal.softwareheritage.org"
    puppet_environment        = "production"
    puppet_master             = var.puppet_master
    gateway_ip                = "192.168.100.1"
    user_admin                = var.user_admin
    user_admin_ssh_public_key = var.user_admin_ssh_public_key
  }

  hostname    = "zookeeper1"
  description = "Zookeeper server"
  hypervisor  = "hypervisor3"
  vmid        = 125
  cores       = "2"
  memory      = "4096"
  network = {
    ip      = "192.168.100.131"
    bridge  = "vmbr0"
  }
  storage = {
    location = "proxmox"
    size     = "32G"
  }
}

module "zookeeper2" {
  source = "./modules/node"
  config = {
    dns                       = var.dns
    domain                    = "internal.softwareheritage.org"
    puppet_environment        = "production"
    puppet_master             = var.puppet_master
    gateway_ip                = "192.168.100.1"
    user_admin                = var.user_admin
    user_admin_ssh_public_key = var.user_admin_ssh_public_key
  }

  hostname    = "zookeeper2"
  description = "Zookeeper server"
  hypervisor  = "branly"
  vmid        = 124
  cores       = "2"
  memory      = "4096"
  network = {
    ip      = "192.168.100.132"
    bridge  = "vmbr0"
  }
  storage = {
    location = "proxmox"
    size     = "32G"
  }
}

module "zookeeper3" {
  source = "./modules/node"
  config = {
    dns                       = var.dns
    domain                    = "internal.softwareheritage.org"
    puppet_environment        = "production"
    puppet_master             = var.puppet_master
    gateway_ip                = "192.168.100.1"
    user_admin                = var.user_admin
    user_admin_ssh_public_key = var.user_admin_ssh_public_key
  }

  hostname    = "zookeeper3"
  description = "Zookeeper server"
  hypervisor  = "beaubourg"
  vmid        = 101
  cores       = "2"
  memory      = "4096"
  network = {
    ip      = "192.168.100.133"
    bridge  = "vmbr0"
  }
  storage = {
    location = "proxmox"
    size     = "32G"
  }
}
