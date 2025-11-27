# Fetch existing clusters by cluster name
data "rancher2_cluster" "by_name" {
  for_each = var.cluster_names
  name     = each.value
}

locals {
  # map of clusters { name => id}
  cluster_id_by_name = { for k, d in data.rancher2_cluster.by_name : k => d.id }
}

# Fetch existing users by username
data "rancher2_user" "by_name" {
  for_each = local.all_user_names
  username = each.value
}

locals {
  # map of {user name => user id}
  user_id_by_name = { for uname, d in data.rancher2_user.by_name : uname => d.id }
}

# TODO do we really need to build the key like this? (cluster_name||project_name)
# Fetch projects by name + cluster
data "rancher2_project" "by_pair" {
  for_each = local.project_pair_keys

  name       = split("||", each.value)[1]
  cluster_id = lookup(local.cluster_id_by_name, split("||", each.value)[0], "")
}

locals {
  # map of { "cluster||project" => project_id }
  projects_by_pair_key = { for pair, d in data.rancher2_project.by_pair : pair => d.id }

  # list of distinct clusters present in the projects_by_pair keys
  project_clusters = toset([for pair in keys(local.projects_by_pair_key) : split("||", pair)[0]])
}