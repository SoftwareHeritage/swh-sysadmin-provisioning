
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.cluster_name
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  location            = data.azurerm_resource_group.aks_rg.location
  dns_prefix          = var.cluster_name

  default_node_pool {
    name                = "default"
    # node_count          = 1
    vm_size             = var.node_type
    enable_auto_scaling = true
    max_count           = var.maximal_pool_count
    min_count           = var.minimal_pool_count

    # not supported for all vm types
    # os_disk_type        = "Ephemeral"

    # experimental feature, not activable as we don't
    # have a subscription
    # kubelet_config {
    #   container_log_max_size_mb = "1024"
    # }
  }

  identity {
    type = "SystemAssigned"
  }

  private_cluster_enabled = true

  network_profile {
    network_plugin = "kubenet"
    network_policy = "calico"
  }
}

resource "azurerm_private_endpoint" "aks_cluster_endpoint" {
  name                = "${var.cluster_name}-endpoint"
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  location            = data.azurerm_resource_group.aks_rg.location
  subnet_id           = data.azurerm_subnet.internal_subnet.id

  private_service_connection {
    name                           = "${var.cluster_name}-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_kubernetes_cluster.aks_cluster.id
    subresource_names              = ["management"]
  }
}
