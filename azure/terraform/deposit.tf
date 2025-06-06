# Define a new resource for the deposit
# matching what we name elsewhere "euwest-${resource}"

resource "azurerm_resource_group" "euwest-deposit" {
  name     = "euwest-deposit"
  location = "westeurope"

  tags = {
    environment = "SWH Deposit"
  }
}

resource "azurerm_storage_account" "deposit-storage-staging" {
  name                      = "swhdepositstoragestaging"
  resource_group_name       = azurerm_resource_group.euwest-deposit.name
  location                  = "westeurope"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  account_kind              = "BlobStorage"
  access_tier               = "Cool"
  enable_https_traffic_only = true
  tags = {
    environment = "SWH Deposit"
  }
}

resource "azurerm_storage_container" "deposit-contents" {
# A container for the blob storage named 'deposit-contents' (like other blob
# storages)
  name                  = "deposit-contents"
  storage_account_name  = azurerm_storage_account.deposit-storage-staging.name
  container_access_type = "blob"
}

resource "azurerm_storage_account" "deposit-storage-staging-next-version" {
  name                      = "swhdepositstoragestgnxvs"
  resource_group_name       = azurerm_resource_group.euwest-deposit.name
  location                  = "westeurope"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  account_kind              = "BlobStorage"
  access_tier               = "Cool"
  enable_https_traffic_only = true
  tags = {
    environment = "SWH Deposit"
  }
}

# A container for the blob storage named 'deposit-contents' (like other blob
# storages)
resource "azurerm_storage_container" "deposit-contents-staging-next-version" {
  name                  = "deposit-contents"
  storage_account_name  = azurerm_storage_account.deposit-storage-staging-next-version.name
  container_access_type = "blob"
}

resource "azurerm_storage_account" "deposit-storage" {
  name                      = "swhdepositstorage"
  resource_group_name       = azurerm_resource_group.euwest-deposit.name
  location                  = "westeurope"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  account_kind              = "BlobStorage"
  access_tier               = "Cool"
  enable_https_traffic_only = true
  tags = {
    environment = "SWH Deposit"
  }
}

# A container for the blob storage named 'deposit-contents' (as other blob
# storages)
resource "azurerm_storage_container" "deposit-tarballs" {
  name                  = "deposit-tarballs"
  storage_account_name  = azurerm_storage_account.deposit-storage.name
  container_access_type = "blob"
}
