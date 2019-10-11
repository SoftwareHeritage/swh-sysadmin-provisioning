# Keyword use:
# - provider: Define the provider(s)
# - data: Retrieve data information to be used within the file
# - resource: Define resource and create/update

# Configure the Microsoft Azure Provider
# Empty if using the `az login` tool
provider "azurerm" {
  version = "~> 1.27"
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

variable "ssh_key_data" {
  type = "string"
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDZarzgHrzUYspvrgSI6fszrALo92BDys7QOkJgUfZa9t9m4g7dUANNtwBiqIbqijAQPmB1zKgG6QTZC5rJkRy6KqXCW/+Qeedw/FWIbuI7jOD5WxnglbEQgvPkkB8kf1xIF7icRfWcQmK2je/3sFd9yS4/+jftNMPPXkBCxYm74onMenyllA1akA8FLyujLu6MNA1D8iLLXvz6pBDTT4GZ5/bm3vSE6Go8Xbuyu4SCtYZSHaHC2lXZ6Hhi6dbli4d3OwkUWz+YhFGaEra5Fx45Iig4UCL6kXPkvL/oSc9KGerpT//Xj9qz1K7p/IrBS8+eA4X69bHYYV0UZKDADZSn ardumont@yavin4"
}

variable "user_admin" {
    type = "string"
    default = "root"
}
