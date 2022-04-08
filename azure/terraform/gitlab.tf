# create a kubernetes cluster for a given environment
# and deploy a gitlab instance on it
# The cluster is deployed in its own resource group
# suffixed by the environment

# module "gitlab-production" {
#     source = "./modules/gitlab"
#     name   = "euwest-gitlab-production"
# }

# output "gitlab-production_summary" {
#   value = module.gitlab-production.summary
# }

module "gitlab-staging" {
  source            = "./modules/gitlab"
  name              = "euwest-gitlab-staging"
  blob_storage_name = "swheuwestgitlabstaging"
}

output "gitlab-staging_aks_summary" {
  value = module.gitlab-staging.aks_summary
}

output "gitlab-staging_storage_summary" {
  value     = module.gitlab-staging.blob_storage_summary
  sensitive = true
}
