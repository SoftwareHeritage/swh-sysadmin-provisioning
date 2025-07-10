# Define a new resource for the vault
# matching what we name elsewhere "euwest-${resource}"

resource "azurerm_resource_group" "euwest-vault" {
  name     = "euwest-vault"
  location = "westeurope"

  tags = {
    environment = "SWH Vault"
  }
}

resource "azurerm_network_interface_security_group_association" "vangogh-interface-sga" {
  network_interface_id      = azurerm_network_interface.vangogh-interface.id
  network_security_group_id = data.azurerm_network_security_group.worker-nsg.id
}

# Blobstorage as defined in task
resource "azurerm_storage_account" "vault-storage" {
  name                      = "swhvaultstorage"
  resource_group_name       = azurerm_resource_group.euwest-vault.name
  location                  = "westeurope"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  account_kind              = "BlobStorage"
  access_tier               = "Cool"
  enable_https_traffic_only = true
  tags = {
    environment = "SWH Vault"
  }
}

# A container for the blob storage named 'contents' (as other blob storages)
resource "azurerm_storage_container" "contents" {
  name                  = "contents"
  storage_account_name  = azurerm_storage_account.vault-storage.name
  container_access_type = "private"
}

