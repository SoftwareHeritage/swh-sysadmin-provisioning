# create a kubernetes cluster for a given environment
# and deploy a gitlab instance on it
# The cluster is deployed in its own resource group
# suffixed by the environment

#######
# Production instance
#######
module "gitlab-production" {
  source               = "./modules/gitlab"
  name                 = "euwest-gitlab-production"
  blob_storage_name    = "swheuwestgitlabprod"  #can only consist of lowercase letters and numbers, and must be between 3 and 24 characters long
  backups_storage_name = "swhgitlabprodbackups" #can only consist of lowercase letters and numbers, and must be between 3 and 24 characters long
  kubernetes_version   = "1.32.4"
  container_insights   = false
  minimal_pool_count   = 2
  maximal_pool_count   = 4
  pool_node_type       = "Standard_F4as_v7"
  pool_name            = "newer"

}

output "gitlab-production_aks_summary" {
  value = module.gitlab-production.aks_summary
}

output "gitlab-production_storage_summary" {
  value     = module.gitlab-production.blob_storage_summary
  sensitive = true
}

output "gitlab-production_backups_secret_yaml" {
  value     = module.gitlab-production.backups_storage_secret_yaml
  sensitive = true
}

#######
# Staging instance
#######
module "gitlab-staging" {
  source               = "./modules/gitlab"
  name                 = "euwest-gitlab-staging"
  blob_storage_name    = "swheuwestgitlabstaging"
  backups_storage_name = "swhgitlabstgbackups" #can only consist of lowercase letters and numbers, and must be between 3 and 24 characters long
  kubernetes_version   = "1.32.4"
  container_insights   = false
  maximal_pool_count   = 5
}

output "gitlab-staging_aks_summary" {
  value = module.gitlab-staging.aks_summary
}

output "gitlab-staging_storage_summary" {
  value     = module.gitlab-staging.blob_storage_summary
  sensitive = true
}

output "gitlab-staging_backups_secret_yaml" {
  value     = module.gitlab-staging.backups_storage_secret_yaml
  sensitive = true
}
