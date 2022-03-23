data "azurerm_resource_group" "aks_rg" {
  name                 = var.resource_group
}

data "azurerm_subnet" "internal_subnet" {
  name                 = "default"
  virtual_network_name = var.internal_vnet
  resource_group_name  = var.internal_vnet_rg
}
