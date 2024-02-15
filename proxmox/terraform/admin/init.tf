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
    # kubernetes cluster's max pods per node
    max_pods_per_node               = 110
  }
}
