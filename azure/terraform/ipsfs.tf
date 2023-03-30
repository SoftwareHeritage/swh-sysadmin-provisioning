# Define a new resource for the IPFS POC

resource "azurerm_resource_group" "euwest_ipfs" {
  name     = "euwest-ipfs"
  location = "westeurope"

  tags = {
    environment = "IPFS POC"
  }
}

resource "azurerm_public_ip" "ipfs_public_ip" {
  name                = "ipfs-public-ip"
  resource_group_name = azurerm_resource_group.euwest_ipfs.name
  location            = "westeurope"
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

resource "azurerm_virtual_network" "ipfs_virtual_network" {
  name                = "ipfs-internal-network"
  location            = "westeurope"
  resource_group_name = azurerm_resource_group.euwest_ipfs.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "ipfs"
  }
}

resource "azurerm_subnet" "ipfs_internal_subnet" {
  name                 = "ipfs-internal-subnet"
  resource_group_name = azurerm_resource_group.euwest_ipfs.name
  virtual_network_name = azurerm_virtual_network.ipfs_virtual_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "ipfs_security_group" {
  name                = "ipfs-ssh-group"
  location            = "westeurope"
  resource_group_name = azurerm_resource_group.euwest_ipfs.name

  security_rule {
    name                       = "inbound-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "ipfs"
  }
}

resource "azurerm_network_interface_security_group_association" "ipfs-interface-sg" {
  network_interface_id      = azurerm_network_interface.ipfs_interface.id
  network_security_group_id = azurerm_network_security_group.ipfs_security_group.id
}

resource "azurerm_network_interface" "ipfs_interface" {
  name                = "ipfs-interface"
  location            = "westeurope"
  resource_group_name = azurerm_resource_group.euwest_ipfs.name

  ip_configuration {
    name                          = "ipfsNicConfiguration"
    subnet_id                     = azurerm_subnet.ipfs_internal_subnet.id
    public_ip_address_id          = azurerm_public_ip.ipfs_public_ip.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "ipfs-server" {
  name                  = "ipfs-server"
  location              = "westeurope"
  resource_group_name = azurerm_resource_group.euwest_ipfs.name
  network_interface_ids = [ azurerm_network_interface.ipfs_interface.id ]
  vm_size               = "Standard_B1ms"

  boot_diagnostics {
    enabled     = true
    storage_uri = var.boot_diagnostics_uri
  }

  storage_os_disk {
    name              = "ipfs-server-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "debian"
    offer     = "debian-11"
    sku       = "11"
    version   = "latest"
  }

  os_profile {
    computer_name  = "ipfs"
    admin_username = "tmpadmin"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/tmpadmin/.ssh/authorized_keys"
      key_data = var.ssh_key_data_vsellier
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir /root/.ssh",
      "echo ${var.ssh_key_data_ardumont} | sudo tee -a /root/.ssh/authorized_keys",
      "echo ${var.ssh_key_data_olasd} | sudo tee -a /root/.ssh/authorized_keys",
      "echo ${var.ssh_key_data_vsellier} | sudo tee -a /root/.ssh/authorized_keys",
    ]

    connection {
      type = "ssh"
      user = "tmpamdin"
      host = azurerm_public_ip.ipfs_public_ip.ip_address
    }
  }

  tags = {
    environment = "ipfs"
  }
}
