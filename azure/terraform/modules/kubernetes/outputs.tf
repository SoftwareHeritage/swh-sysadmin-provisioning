output "summary" {
  value = <<EOF

name: ${azurerm_kubernetes_cluster.aks_cluster.name}
internal_ip: ${azurerm_private_endpoint.aks_cluster_endpoint.private_service_connection.0.private_ip_address}
public_ip: ${var.public_ip_provisioning ? azurerm_public_ip.aks_cluster_public_ip[0].ip_address : "Disabled"}

Execute the following command to add the credentials in your .kube/config:
az aks get-credentials --resource-group ${data.azurerm_resource_group.aks_rg.name} --name ${azurerm_kubernetes_cluster.aks_cluster.name} 

and add this line in your /etc/hosts file:
${azurerm_private_endpoint.aks_cluster_endpoint.private_service_connection.0.private_ip_address} ${azurerm_kubernetes_cluster.aks_cluster.private_fqdn}

EOF

}
