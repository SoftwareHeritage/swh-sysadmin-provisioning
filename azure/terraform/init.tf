# Keyword use:
# - provider: Define the provider(s)
# - data: Retrieve data information to be used within the file
# - resource: Define resource and create/update

terraform {
  required_version = ">= 0.13"
  backend "azurerm" {
    resource_group_name  = "euwest-admin"
    storage_account_name = "swhterraform"
    container_name       = "tfstate"
    key                  = "prod.azure.terraform.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.106.1"
    }
  }
}

# Configure the Microsoft Azure Provider
# Empty if using the `az login` tool
provider "azurerm" {
  features {}
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
  type    = string
  default = "/tmp/firstboot.sh"
}

variable "ssh_key_data_ardumont" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDZarzgHrzUYspvrgSI6fszrALo92BDys7QOkJgUfZa9t9m4g7dUANNtwBiqIbqijAQPmB1zKgG6QTZC5rJkRy6KqXCW/+Qeedw/FWIbuI7jOD5WxnglbEQgvPkkB8kf1xIF7icRfWcQmK2je/3sFd9yS4/+jftNMPPXkBCxYm74onMenyllA1akA8FLyujLu6MNA1D8iLLXvz6pBDTT4GZ5/bm3vSE6Go8Xbuyu4SCtYZSHaHC2lXZ6Hhi6dbli4d3OwkUWz+YhFGaEra5Fx45Iig4UCL6kXPkvL/oSc9KGerpT//Xj9qz1K7p/IrBS8+eA4X69bHYYV0UZKDADZSn ardumont@yavin4"
}

variable "ssh_key_data_douardda" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCoON7De2Bx03owpZfzbOyucZTmyQdm7F+LP4D4H9EyOFxtyMpjH2S9Ve/JvMoFIWGQQlXSkYzRv63Z0BzPLKD2NsYgomcjOLdw1Baxnv8VOH+Q01g4B3cabcP2LMVjerHt/KRkY3E6dnKLQGE5UiER/taQ7KazAwvu89nUd4BJsV43rJ3X3DtFEfH3lR4ZEIgFyPUkVemQAjBhueFmN3w8debOdr7t9cBpnYvYKzLQN+G/kQVFc+fgs+fFOtOv+Az9kTXChfLs5pKPBm+MuGxz4gS3fPiAjY9cN6vGzr7ZNkCRUSUjJ10Hlm7Gf2EN8f+k6iSR4CPeixDcZ+scbCg4dCORqTsliSQzUORIJED9fbUR6bBjF4rRwm5GvnXx5ZTToWDJu0PSHYOkomqffp30wqvAvs6gLb+bG1daYsOLp+wYru3q09J9zUAA8vNXoWYaERFxgwsmsf57t8+JevUuePJGUC45asHjQh/ON1H5PDXtULmeD1GKkjqyaS7SBNbpOWgQb21l3pwhLet3Mq3TJmxVqzGMDnYvQMUCkiPdZq2pDplzfpDpOKLaDg8q82rR5+/tAfB4P2Z9RCOqnMLRcQk9AluTyO1D472Mkp+v5VA4di0eTWZ0tuzwYJEft0OVo+QOVTslCGsyGiEUoOcHzkrdgsT5uQziyAfgTMSuiw== david.douard@sdfa3.org"
}

variable "ssh_key_data_olasd" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDZ1TCpfzrvxLhEMhxjbxqPDCwY0nazIr1cyIbhGD2bUdAbZqVMdNtr7MeDnlLIKrIPJWuvltauvLNkYU0iLc1jMntdBCBM3hgXjmTyDtc8XvXseeBp5tDqccYNR/cnDUuweNcL5tfeu5kzaAg3DFi5Dsncs5hQK5KQ8CPKWcacPjEk4ir9gdFrtKG1rZmg/wi7YbfxrJYWzb171hdV13gSgyXdsG5UAFsNyxsKSztulcLKxvbmDgYbzytr38FK2udRk7WuqPbtEAW1zV4yrBXBSB/uw8EAMi+wwvLTwyUcEl4u0CTlhREljUx8LhYrsQUCrBcmoPAmlnLCD5Q9XrGH nicolasd@darboux id_rsa.inria.pub"
}

variable "ssh_key_data_vsellier" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDL2n3ayVSz7zyG89lsdPS4EyIf29FSNX6XwFEz03xoLuHTOPoyq4z2gkuIaBuIWIPJCwhrhJJvn0KqEIJ2yIOF565zjTI/121VTjSZrwpLFBO5QQFGQB1fY4wVg8VYeVxZLeqbGQAdSAvVrpAAJdoMF0Hwv+i/dVC1SVLj3QrAMft6l5G9iz9OM3DwmoNkCPf+rxbqiiJB2ojMbzSIUfOiE5svL5+z811JOYz62ZAEmVAY22H96Ez0R5uCMQi3pdHvr16DogsXXlhA6zBg0p8sFKOLpfHDjah9pnpI+twX14//2ydw303M3W/4FcXZ1bD4kSjEBjCky6GkrM9MCW6f vsellier@swh-vs1"
}

variable "user_admin" {
  type    = string
  default = "tmpadmin"
}

variable "boot_diagnostics_uri" {
  default = "https://swhresourcediag966.blob.core.windows.net"
}
