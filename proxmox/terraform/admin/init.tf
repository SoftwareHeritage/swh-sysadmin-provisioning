terraform {
  backend "azurerm" {
    resource_group_name  = "euwest-admin"
    storage_account_name = "swhterraform"
    container_name       = "tfstate"
    key                  = "admin.rocquencourt.terraform.tfstate"
  }
}

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
    bridge                          = "vmbr442"
    # kubernetes cluster's max pods per node
    max_pods_per_node = 110
  }
}
