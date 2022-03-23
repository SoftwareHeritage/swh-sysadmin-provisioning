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
  source = "./modules/gitlab"
  name   = "euwest-gitlab-staging"
}

output "gitlab-staging_summary" {
  value = module.gitlab-staging.summary
}
