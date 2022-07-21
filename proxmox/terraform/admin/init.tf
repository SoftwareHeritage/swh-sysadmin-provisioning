terraform {
  backend "azurerm" {
    resource_group_name  = "euwest-admin"
    storage_account_name = "swhterraform"
    container_name       = "tfstate"
    key                  = "admin.rocquencourt.terraform.tfstate"
  }
}
