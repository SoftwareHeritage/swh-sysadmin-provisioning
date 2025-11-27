# Fetch existing clusters by cluster name
data "rancher2_cluster" "by_alias" {
  for_each = var.cluster_names_by_alias
  name     = each.value
}

locals {
  # map of clusters { name => id}
  cluster_id_by_alias = { for k, d in data.rancher2_cluster.by_alias : k => d.id }
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

# Build a list of (cluster, project) pairs instead of a composite key string
locals {
  cluster_project_list = tolist(flatten([
    for cluster_alias, projects in var.project_permissions : [
      for project_name in keys(projects) :
      {
        cluster_alias = cluster_alias
        project_name  = project_name
      }
    ]
  ]))
}

# # convert to a map with numeric string keys so we can use for_each (keys must be strings)
# # keep only pairs whose cluster is known (to avoid empty cluster_id)
# project_pairs_map = {
#   for idx, pair in local.project_pairs_list : tostring(idx) => pair
#   if contains(keys(local.cluster_id_by_name), lookup(pair, "cluster", ""))
# }

output "cluster_project_list" {
  value = local.cluster_project_list
}

# Fetch projects by name + cluster using the indexed map (no composite key)
data "rancher2_project" "by_project_id" {
  for_each = {
    for idx, d in local.cluster_project_list:
    idx => d
  }

  name       = each.value.project_name
  cluster_id = lookup(local.cluster_id_by_alias, each.value.cluster_alias)
}

locals {
  # nested map { cluster_alias => { project_name => project_id } }
  project_id_by_cluster_alias_and_name = {
    # iterate over the set of distinct cluster aliases present in the list
    for cluster in toset([for p in local.cluster_project_list : p.cluster_alias]) :
    cluster => {
      # for each pair (index, pair) in the list, add project_name => project_id
      for idx, p in local.cluster_project_list :
      p.project_name => data.rancher2_project.by_project_id[tostring(idx)].id
      # keep only the projects belonging to the current cluster alias
      if p.cluster_alias == cluster
    }
  }

  # list of distinct clusters present in the projects_by_cluster keys
  project_clusters = toset(keys(local.project_id_by_cluster_alias_and_name))
}
