resource "azurerm_resource_group" "gitlab_rg" {
  name     = var.name
  location = var.location

  tags = {
    environment = "gitlab"
  }
}

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
