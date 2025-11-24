# Collect user names from locals.project_permissions and local.cluster_admins
locals {
  # usernames declared in project_permissions (flattened): use nested lists then double-flatten
  usernames_from_project_permissions = toset(distinct(flatten(flatten([
    for cluster_name in keys(local.project_permissions) : [
      for project_name in keys(local.project_permissions[cluster_name]) : [
        for role_name in keys(local.project_permissions[cluster_name][project_name]) : local.project_permissions[cluster_name][project_name][role_name]
      ]
    ]
  ]))))

  cluster_admin_usernames = toset(local.cluster_admins)
  all_usernames          = toset(concat([
    for u in local.usernames_from_project_permissions : u
  ], [
    for u in local.cluster_admin_usernames : u
  ]))

  # set of unique cluster names referenced by project permissions
  cluster_names = toset(keys(local.project_permissions))

  # set of unique project pairs encoded as "cluster||project" (explicit nested lists + flatten)
  project_pair_keys = toset(flatten([
    for cluster_name in keys(local.project_permissions) : [
      for project_name in keys(local.project_permissions[cluster_name]) : "${cluster_name}||${project_name}"
    ]
  ]))
}

# Fetch existing users by username and build map {name: data.rancher2_user}
data "rancher2_user" "by_name" {
  for_each = local.all_usernames
  username = each.value
}

locals {
  user_id_map = { for uname, d in data.rancher2_user.by_name : uname => d.id }
}

# NOTE: clusters are resolved in variables.tf via var.cluster_names and data.rancher2_cluster.by_name
# build a cluster name -> id map from that
locals {
  cluster_id_map = local.clusters_map
}

# Fetch projects by name + cluster and build a lookup map
data "rancher2_project" "by_pair" {
  for_each = local.project_pair_keys

  name       = split("||", each.value)[1]
  cluster_id = lookup(local.cluster_id_map, split("||", each.value)[0], "")
}

locals {
  # map of "cluster||project" => project_id
  projects_by_pair = { for pair, d in data.rancher2_project.by_pair : pair => d.id }

  # list of distinct clusters present in the projects_by_pair keys
  project_clusters = toset([for pair in keys(local.projects_by_pair) : split("||", pair)[0]])

  # nested map { cluster_name => { project_name => project_id } }
  projects_map = {
    for c in local.project_clusters : c => {
      for pair, id in local.projects_by_pair : split("||", pair)[1] => id if split("||", pair)[0] == c
    }
  }

  # Build list of tuples { cluster_id, project_id, role_name, user_id }
  project_permission_tuples = flatten([
    for cluster_name in keys(local.project_permissions) : [
      for project_name in keys(local.project_permissions[cluster_name]) : [
        for role_name in keys(local.project_permissions[cluster_name][project_name]) : [
          for username in local.project_permissions[cluster_name][project_name][role_name] : {
            cluster_id = lookup(local.cluster_id_map, cluster_name, "")
            project_id = lookup(lookup(local.projects_map, cluster_name, {}), project_name, "")
            role_name  = role_name
            user_id    = lookup(local.user_id_map, username, "")
          }
        ]
      ]
    ]
  ])

  # Compute ro and rw usernames directly from project_permissions (use lookup to avoid missing keys)
  ro_usernames = toset(distinct(flatten([
    for cluster_name in keys(local.project_permissions) : flatten([
      for project_name in keys(local.project_permissions[cluster_name]) : lookup(local.project_permissions[cluster_name][project_name], "ro", [])
    ])
  ])))

  rw_usernames = toset(distinct(flatten([
    for cluster_name in keys(local.project_permissions) : flatten([
      for project_name in keys(local.project_permissions[cluster_name]) : lookup(local.project_permissions[cluster_name][project_name], "rw", [])
    ])
  ])))

  # maps username -> user_id for each role we care about (filter empty ids)
  developers_user_ids = { for u in local.ro_usernames : u => lookup(local.user_id_map, u, "") if lookup(local.user_id_map, u, "") != "" }
  super_developers_user_ids = { for u in local.rw_usernames : u => lookup(local.user_id_map, u, "") if lookup(local.user_id_map, u, "") != "" }
  ops_user_ids = { for u in local.cluster_admin_usernames : u => lookup(local.user_id_map, u, "") if lookup(local.user_id_map, u, "") != "" }
}

output "project_permission_tuples" {
  value       = local.project_permission_tuples
  description = "List of {cluster_id, project_id, role_name, user_id} derived from local.project_permissions"
}