# Collect information from locals.project_permissions which is the data
# structure driving the overall permission setup in the rancher clusters
locals {
  # Final: set of usernames collected directly from local.project_permissions
  project_permissions_usernames = toset(distinct(flatten([
    for cluster_name, projects in local.project_permissions : [
      for project_name, roles in projects : flatten([
        for role_name, users in roles : users
      ])
    ]
  ])))

  base_usernames = setsubtract(local.project_permissions_usernames, local.admin_usernames)

  # keep the rest of the derived locals here (use usernames_from_project_permissions defined above)
  # union of admin and base usernames as a set
  all_usernames          = setunion(local.admin_usernames, local.base_usernames)

  # set of unique cluster names referenced by project permissions
  cluster_names = toset(keys(local.project_permissions))

  # set of unique project pairs encoded as "cluster||project"
  project_pair_keys = toset(flatten([
    for cluster_name, projects in local.project_permissions : [
      for project_name in keys(projects) : "${cluster_name}||${project_name}"
    ]
  ]))
}

# Fetch existing users by username
data "rancher2_user" "by_name" {
  for_each = local.all_usernames
  username = each.value
}

# Fetch existing clusters by cluster name
data "rancher2_cluster" "by_name" {
  for_each = var.cluster_names
  name     = each.value
}

# Fetch projects by name + cluster
data "rancher2_project" "by_pair" {
  for_each = local.project_pair_keys

  name       = split("||", each.value)[1]
  cluster_id = lookup(local.cluster_id_map, split("||", each.value)[0], "")
}

locals {
  # map of {user name => user id}
  user_id_map = { for uname, d in data.rancher2_user.by_name : uname => d.id }

  # map of {cluster name => cluster id} map
  cluster_id_map = { for k, d in data.rancher2_cluster.by_name : k => d.id }

  # map of { "cluster||project" => project_id }
  projects_by_pair = { for pair, d in data.rancher2_project.by_pair : pair => d.id }

  # list of distinct clusters present in the projects_by_pair keys
  project_clusters = toset([for pair in keys(local.projects_by_pair) : split("||", pair)[0]])

  # nested map { cluster_name => { project_name => project_id } }
  projects_map = {
    for c in local.project_clusters : c => {
      for pair, id in local.projects_by_pair : split("||", pair)[1] => id if split("||", pair)[0] == c
    }
  }

  # Build maps of {username => user_id} for each role we care about (filter
  # empty ids)
  admin_user_ids = {
    for u in local.admin_usernames :
    u => lookup(local.user_id_map, u, "") if lookup(local.user_id_map, u, "") != ""
  }

  base_user_ids = {
    for u in local.base_usernames :
    u => lookup(local.user_id_map, u, "") if lookup(local.user_id_map, u, "") != ""
  }

  # Build set of tuples { cluster_id, cluster_name, project_id, project_role_template_id, user_id }
  project_permission_tuples = toset(flatten([
    for cluster_name in local.cluster_names : [
      for project_name in keys(local.project_permissions[cluster_name]) : [
        for role_name_id in keys(local.project_permissions[cluster_name][project_name]) : [
          for user_name in local.project_permissions[cluster_name][project_name][role_name_id] : {
            cluster_id = lookup(local.cluster_id_map, cluster_name, "")
            cluster_name = cluster_name
            project_id = lookup(lookup(local.projects_map, cluster_name, {}), project_name, "")
            project_name = project_name
            role_template_id = role_name_id
            user_id = lookup(local.user_id_map, user_name, "")
            user_name = user_name
          }
        ]
      ]
    ]
  ]))
}

output "clusters" {
  value = local.cluster_id_map
}

output "project_permissions" {
  value       = local.project_permission_tuples
  description = "Set of {cluster_id, cluster_name, project_id, role_name_id, user_id} derived from local.project_permissions"
}