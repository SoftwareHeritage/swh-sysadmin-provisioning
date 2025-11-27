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

# Build a list of project (cluster_alias, name) pairs
locals {
  cluster_project_list = tolist(flatten([
    for cluster_alias, projects in var.project_permissions : [
      for name in keys(projects) :
      {
        cluster_alias = cluster_alias
        name  = name
      }
    ]
  ]))
}

output "cluster_project_list" {
  value = local.cluster_project_list
  sensitive = true
}

# Fetch projects by name + cluster using the indexed map (no composite key)
data "rancher2_project" "by_project_id" {
  for_each = { for idx, project in local.cluster_project_list:
    "${project.cluster_alias}---${project.name}" => project
  }

  name       = each.value.name
  cluster_id = lookup(local.cluster_id_by_alias, each.value.cluster_alias)
}

locals {
  # nested map { cluster_alias => { project_name => project_id } }
  project_id_by_cluster_alias_and_name = {
    # iterate over the set of distinct cluster aliases present in the list
    for cluster_alias in keys(local.cluster_id_by_alias) :
    cluster_alias => {
      # for each pair (index, pair) in the list, add project_name => project_id
      for idx, project in local.cluster_project_list :
      project.name => data.rancher2_project.by_project_id["${project.cluster_alias}---${project.name}"].id
      # keep only the projects belonging to the current cluster alias
      if project.cluster_alias == cluster_alias
    }
  }
}
