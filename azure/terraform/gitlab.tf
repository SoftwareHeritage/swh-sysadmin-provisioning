# create a kubernetes cluster for a given environment
# and deploy a gitlab instance on it
# The cluster is deployed in its own resource group
# suffixed by the environment

#######
# Production instance
#######
module "gitlab-production" {
  source             = "./modules/gitlab"
  name               = "euwest-gitlab-production"
  blob_storage_name  = "swheuwestgitlabprod" #can only consist of lowercase letters and numbers, and must be between 3 and 24 characters long
  kubernetes_version = "1.26.10"
  container_insights = false
  minimal_pool_count = 4
  maximal_pool_count = 5
}

output "gitlab-production_aks_summary" {
  value = module.gitlab-production.aks_summary
}

output "gitlab-production_storage_summary" {
  value     = module.gitlab-production.blob_storage_summary
  sensitive = true
}

#######
# Staging instance
#######
module "gitlab-staging" {
  source             = "./modules/gitlab"
  name               = "euwest-gitlab-staging"
  blob_storage_name  = "swheuwestgitlabstaging"
  kubernetes_version = "1.26.10"
  container_insights = false
}

output "gitlab-staging_aks_summary" {
  value = module.gitlab-staging.aks_summary
}

output "gitlab-staging_storage_summary" {
  value     = module.gitlab-staging.blob_storage_summary
  sensitive = true
}
