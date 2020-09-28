module "kelvingrove" {
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

  hostname    = "kelvingrove"
  description = "Keycloak server"
  hypervisor  = "hypervisor3"
  vmid        = 123
  cores       = "4"
  memory      = "8192"
  numa        = true
  balloon     = 0
  network = {
    ip      = "192.168.100.106"
    macaddr = "72:55:5E:58:01:0B"
    bridge  = "vmbr0"
  }
  storage = {
    location = "proxmox"
    size     = "32G"
  }
}
