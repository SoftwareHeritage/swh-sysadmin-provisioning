terraform {
  backend "azurerm" {
    resource_group_name  = "euwest-admin"
    storage_account_name = "swhterraform"
    container_name       = "tfstate"
    key                  = "staging.rocquencourt.terraform.tfstate"
  }
}

# Default configuration passed along module calls
# (There is no other way to avoid duplication)
locals {
  config = {
    dns                             = var.dns
    domain                          = var.domain
    puppet_environment              = var.puppet_environment
    facter_deployment               = "staging"
    facter_subnet                   = "sesi_rocquencourt_staging"
    puppet_master                   = var.puppet_master
    gateway_ip                      = var.gateway_ip
    user_admin                      = var.user_admin
    user_admin_ssh_public_key       = var.user_admin_ssh_public_key
    user_admin_ssh_private_key_path = var.user_admin_ssh_private_key_path
    bridge                          = "vmbr443"
    # kubernetes cluster's max pods per node
    max_pods_per_node               = 120
  }
}
