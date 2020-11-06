locals {
  config = {
    dns                             = var.dns
    domain                          = "internal.softwareheritage.org"
    puppet_environment              = "production"
    puppet_master                   = var.puppet_master
    gateway_ip                      = "192.168.100.1"
    user_admin                      = var.user_admin
    user_admin_ssh_public_key       = var.user_admin_ssh_public_key
    user_admin_ssh_private_key_path = var.user_admin_ssh_private_key_path
  }
}
