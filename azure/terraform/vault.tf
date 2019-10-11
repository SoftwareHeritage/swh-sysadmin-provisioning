# Define a new resource for the vault
# matching what we name elsewhere "euwest-${resource}"

resource "azurerm_resource_group" "euwest-vault" {
  name     = "euwest-vault"
  location = "westeurope"

  tags = {
    environment = "SWH Vault"
  }
}

resource "azurerm_network_interface" "vangogh-interface" {
  name                      = "vangogh-interface"
  location                  = "westeurope"
  resource_group_name       = "euwest-vault"
  network_security_group_id = data.azurerm_network_security_group.worker-nsg.id

  ip_configuration {
    name                          = "vaultNicConfiguration"
    subnet_id                     = data.azurerm_subnet.default.id
    public_ip_address_id          = ""
    private_ip_address_allocation = "Dynamic"
  }
}

# Blobstorage as defined in task
resource "azurerm_storage_account" "vault-storage" {
  name                     = "swhvaultstorage"
  resource_group_name      = azurerm_resource_group.euwest-vault.name
  location                 = "westeurope"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "BlobStorage"
  access_tier              = "Cool"
  tags = {
    environment = "SWH Vault"
  }
}

# A container for the blob storage named 'contents' (as other blob storages)
resource "azurerm_storage_container" "contents" {
  name                  = "contents"
  resource_group_name   = azurerm_resource_group.euwest-vault.name
  storage_account_name  = azurerm_storage_account.vault-storage.name
  container_access_type = "private"
}

resource "azurerm_virtual_machine" "vault-server" {
  name                  = "vangogh"
  location              = "westeurope"
  resource_group_name   = "euwest-vault"
  network_interface_ids = [azurerm_network_interface.vangogh-interface.id]
  vm_size               = "Standard_B2ms"

  storage_os_disk {
    name              = "vangogh-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "credativ"
    offer     = "Debian"
    sku       = "9"
    version   = "latest"
  }

  # (Va)ngogh <-> (Va)ult
  os_profile {
    computer_name  = "vangogh"
    admin_username = "ardumont"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.user_admin}/.ssh/authorized_keys"
      key_data = var.ssh_key_data_ardumont
    }
  }

  tags = {
    environment = "SWH Vault"
  }
}

