resource "azurerm_resource_group" "gitlab_rg" {
  name     = var.name
  location = var.location

  tags = {
    environment = "gitlab"
  }
}

# kubernetes cluster for compute and storage
module "gitlab_aks_cluster" {
  source         = "../kubernetes"
  cluster_name   = var.name
  resource_group = var.name

  minimal_pool_count = 1
  maximal_pool_count = 5
  node_type          = "Standard_B2ms"

  depends_on = [
    azurerm_resource_group.gitlab_rg
  ]
}

# Storage account for the assets
# git lfs / backups / artifacts / pages 
# terraform states / registry / ...
resource "azurerm_storage_account" "gitlab_storage" {
  name                     = var.blob_storage_name
  resource_group_name      = var.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  tags = {
    environment = "gitlab"
  }
}

resource "azurerm_storage_container" "gitlab_storage_container" {
  name                  = "gitlab-content"
  storage_account_name  = azurerm_storage_account.gitlab_storage.name
  container_access_type = "private"
}

