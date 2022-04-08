output "aks_summary" {
  value = module.gitlab_aks_cluster.summary
}

output "blob_storage_summary" {
  value = <<EOF

name: ${azurerm_storage_account.gitlab_storage.name}
principal_connection_string: ${azurerm_storage_account.gitlab_storage.primary_connection_string}
principal_access_key: ${azurerm_storage_account.gitlab_storage.primary_access_key}
principal_secret: ${azurerm_storage_account.gitlab_storage.primary_connection_string}

EOF
}
