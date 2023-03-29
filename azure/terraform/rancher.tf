resource "azurerm_resource_group" "rancher_rg" {
  name     = "euwest-rancher"
  location = "westeurope"

  tags = {
    environment = "rancher"
  }
}

# kubernetes cluster for compute and storage
module "rancher_aks_cluster" {
  source         = "./modules/kubernetes"
  cluster_name   = "euwest-rancher"
  resource_group = azurerm_resource_group.rancher_rg.name

  minimal_pool_count     = 2
  maximal_pool_count     = 3
  node_type              = "Standard_B2ms"
  public_ip_provisioning = false

  depends_on = [
    azurerm_resource_group.rancher_rg
  ]
}

output "rancher_aks_summary" {
  value = module.rancher_aks_cluster.summary
}
