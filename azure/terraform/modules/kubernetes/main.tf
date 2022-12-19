resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.cluster_name
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  location            = data.azurerm_resource_group.aks_rg.location
  dns_prefix          = var.cluster_name
  node_resource_group = "${var.cluster_name}-internal"

  kubernetes_version = var.kubernetes_version

  default_node_pool {
    name = "default"
    # node_count          = 1
    vm_size              = var.node_type
    enable_auto_scaling  = true
    max_count            = var.maximal_pool_count
    min_count            = var.minimal_pool_count
    orchestrator_version = var.kubernetes_version

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
    network_plugin    = "kubenet"
    network_policy    = "calico"
    load_balancer_sku = "standard" # needed to assign a private ip address
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [var.log_analytics_workspace_id] : []
    iterator = workspace_id

    content {
      log_analytics_workspace_id = workspace_id.value
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "diagnostic"
  target_resource_id         = azurerm_kubernetes_cluster.aks_cluster.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "log" {
    for_each = ["cluster-autoscaler", "kube-apiserver", "kube-audit", "kube-audit-admin", "kube-controller-manager"]
    iterator = category

    content {
      category = category.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 30
      }
    }
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

resource "azurerm_public_ip" "aks_cluster_public_ip" {
  count               = var.public_ip_provisioning ? 1 : 0
  name                = "${var.cluster_name}_ip"
  resource_group_name = azurerm_kubernetes_cluster.aks_cluster.node_resource_group
  location            = data.azurerm_resource_group.aks_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}
