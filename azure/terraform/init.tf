# Keyword use:
# - provider: Define the provider(s)
# - data: Retrieve data information to be used within the file
# - resource: Define resource and create/update

terraform {
  backend "azurerm" {
    resource_group_name  = "euwest-admin"
    storage_account_name = "swhterraform"
    container_name       = "tfstate"
    key                  = "prod.azure.terraform.tfstate"
  }
}

# Configure the Microsoft Azure Provider
# Empty if using the `az login` tool
provider "azurerm" {
  version = "=1.43.0"
}

# Reuse the network security group as defined currently
data "azurerm_network_security_group" "worker-nsg" {
  name                = "worker-nsg"
  resource_group_name = "swh-resource"
}

# Same for the subnet
data "azurerm_subnet" "default" {
  name                 = "default"
  virtual_network_name = "swh-vnet"
  resource_group_name  = "swh-resource"
}

# same for resource group used by storage servers
data "azurerm_resource_group" "euwest-servers" {
  name = "euwest-servers"
}

variable "firstboot_script" {
  type = string
  default = "/root/firstboot.sh"
}

variable "ssh_key_data_ardumont" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDZarzgHrzUYspvrgSI6fszrALo92BDys7QOkJgUfZa9t9m4g7dUANNtwBiqIbqijAQPmB1zKgG6QTZC5rJkRy6KqXCW/+Qeedw/FWIbuI7jOD5WxnglbEQgvPkkB8kf1xIF7icRfWcQmK2je/3sFd9yS4/+jftNMPPXkBCxYm74onMenyllA1akA8FLyujLu6MNA1D8iLLXvz6pBDTT4GZ5/bm3vSE6Go8Xbuyu4SCtYZSHaHC2lXZ6Hhi6dbli4d3OwkUWz+YhFGaEra5Fx45Iig4UCL6kXPkvL/oSc9KGerpT//Xj9qz1K7p/IrBS8+eA4X69bHYYV0UZKDADZSn ardumont@yavin4"
}

variable "ssh_key_data_olasd" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDZ1TCpfzrvxLhEMhxjbxqPDCwY0nazIr1cyIbhGD2bUdAbZqVMdNtr7MeDnlLIKrIPJWuvltauvLNkYU0iLc1jMntdBCBM3hgXjmTyDtc8XvXseeBp5tDqccYNR/cnDUuweNcL5tfeu5kzaAg3DFi5Dsncs5hQK5KQ8CPKWcacPjEk4ir9gdFrtKG1rZmg/wi7YbfxrJYWzb171hdV13gSgyXdsG5UAFsNyxsKSztulcLKxvbmDgYbzytr38FK2udRk7WuqPbtEAW1zV4yrBXBSB/uw8EAMi+wwvLTwyUcEl4u0CTlhREljUx8LhYrsQUCrBcmoPAmlnLCD5Q9XrGH nicolasd@darboux id_rsa.inria.pub"
}

variable "user_admin" {
  type    = string
  default = "tmpadmin"
}

variable "boot_diagnostics_uri" {
  default = "https://swhresourcediag966.blob.core.windows.net"
}
