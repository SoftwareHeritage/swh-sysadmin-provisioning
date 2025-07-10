resource "azurerm_resource_group" "gitlab_rg" {
  name     = var.name
  location = var.location

  tags = {
    environment = "gitlab"
  }
}

resource "azurerm_log_analytics_workspace" "k8s_workspace" {
  count = var.container_insights ? 1 : 0

  name                = "k8s-workspace-${var.name}"
  location            = azurerm_resource_group.gitlab_rg.location
  resource_group_name = azurerm_resource_group.gitlab_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_log_analytics_solution" "k8s_log_analytics" {
  count = var.container_insights ? 1 : 0

  solution_name         = "ContainerInsights"
  location              = azurerm_resource_group.gitlab_rg.location
  resource_group_name   = azurerm_resource_group.gitlab_rg.name
  workspace_resource_id = azurerm_log_analytics_workspace.k8s_workspace[count.index].id
  workspace_name        = azurerm_log_analytics_workspace.k8s_workspace[count.index].name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

# kubernetes cluster for compute and storage
module "gitlab_aks_cluster" {
  source         = "../kubernetes"
  cluster_name   = var.name
  resource_group = var.name

  minimal_pool_count = var.minimal_pool_count
  maximal_pool_count = var.maximal_pool_count
  node_type          = "Standard_B2ms"

  kubernetes_version = var.kubernetes_version

  log_analytics_workspace_id = var.container_insights ? azurerm_log_analytics_workspace.k8s_workspace[0].id : null

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
    last_access_time_enabled = true
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  tags = {
    environment = "gitlab"
  }
}

resource "azurerm_storage_container" "gitlab_storage_container" {
  count                 = length(var.blob_storage_containers)
  name                  = var.blob_storage_containers[count.index]
  storage_account_name  = azurerm_storage_account.gitlab_storage.name
  container_access_type = "private"
}

