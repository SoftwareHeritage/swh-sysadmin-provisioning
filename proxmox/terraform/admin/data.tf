# Collect information from locals.project_permissions which is the data
# structure driving the overall permission setup in the rancher clusters
locals {
  # Step 0: nested lists { cluster -> project -> role -> [usernames] }
  nested_userlists_by_cluster = [
    for cluster_name in keys(local.project_permissions) : [
      for project_name in keys(local.project_permissions[cluster_name]) : [
        for role_name_id in keys(local.project_permissions[cluster_name][project_name]) : local.project_permissions[cluster_name][project_name][role_name_id]
      ]
    ]
  ]

  # Step 1: flatten one level -> [ project -> role -> [usernames] ]
  flat_userlists_by_project = flatten(local.nested_userlists_by_cluster)

  # Step 2: flatten second level -> [ role -> [usernames] ]
  flat_userlists_by_role = flatten(local.flat_userlists_by_project)

  # Step 3: flatten third level -> [ username strings ]
  flat_usernames = flatten(local.flat_userlists_by_role)

  # Step 4: remove duplicates
  distinct_usernames = distinct(local.flat_usernames)

  # Final: set of usernames
  usernames_from_project_permissions = toset(local.distinct_usernames)

  # keep the rest of the derived locals here (use usernames_from_project_permissions defined above)
  cluster_admin_usernames = toset(local.cluster_admins)
  all_usernames          = toset(concat([
    for u in local.usernames_from_project_permissions : u
  ], [
    for u in local.cluster_admin_usernames : u
  ]))

  # set of unique cluster names referenced by project permissions
  cluster_names = toset(keys(local.project_permissions))

  # intermediate: map cluster -> list of project names (keys)
  project_names_by_cluster = {
    for c in local.cluster_names : c => keys(local.project_permissions[c])
  }

  # set of unique project pairs encoded as "cluster||project"
  project_pair_keys = toset(flatten([
    for cluster_name in local.cluster_names : [
      for project_name in lookup(local.project_names_by_cluster, cluster_name, []) : "${cluster_name}||${project_name}"
    ]
  ]))
}

# Fetch existing users by username
data "rancher2_user" "by_name" {
  for_each = local.all_usernames
  username = each.value
}

# Fetch existing clusters by clustername
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

  # Compute ro and rw usernames directly from project_permissions (use lookup to avoid missing keys)
  ro_usernames = toset(distinct(flatten([
    for cluster_name in local.cluster_names : flatten([
      for project_name in lookup(local.project_names_by_cluster, cluster_name, []) : lookup(local.project_permissions[cluster_name][project_name], "read-only", [])
    ])
  ])))

  rw_usernames = toset(distinct(flatten([
    for cluster_name in local.cluster_names : flatten([
      for project_name in lookup(local.project_names_by_cluster, cluster_name, []) : lookup(local.project_permissions[cluster_name][project_name], "project-owner", [])
    ])
  ])))

  # Build maps of {username => user_id} for each role we care about (filter
  # empty ids)
  developers_user_ids = {
    for u in local.ro_usernames :
    u => lookup(local.user_id_map, u, "") if lookup(local.user_id_map, u, "") != ""
  }
  super_developers_user_ids = {
    for u in local.rw_usernames :
    u => lookup(local.user_id_map, u, "") if lookup(local.user_id_map, u, "") != ""
  }
  ops_user_ids = {
    for u in local.cluster_admin_usernames :
    u => lookup(local.user_id_map, u, "") if lookup(local.user_id_map, u, "") != ""
  }

  # Build set of tuples { cluster_id, cluster_name, project_id, project_role_template_id, user_id }
  project_permission_tuples = toset(flatten([
    for cluster_name in local.cluster_names : [
      for project_name in lookup(local.project_names_by_cluster, cluster_name, []) : [
        for role_name_id in keys(local.project_permissions[cluster_name][project_name]) : [
          for username in local.project_permissions[cluster_name][project_name][role_name_id] : {
            cluster_id = lookup(local.cluster_id_map, cluster_name, "")
            cluster_name = cluster_name
            project_id = lookup(lookup(local.projects_map, cluster_name, {}), project_name, "")
            project_role_template_id = role_name_id
            user_id = lookup(local.user_id_map, username, "")
          }
        ]
      ]
    ]
  ]))
}

output "project_permission_tuples" {
  value       = local.project_permission_tuples
  description = "Set of {cluster_id, cluster_name, project_id, role_name_id, user_id} derived from local.project_permissions"
}

# Outputs pour chaque étape et maps
output "nested_userlists_by_cluster" {
  value       = local.nested_userlists_by_cluster
  description = "Step 0 - nested lists by cluster -> project -> role -> [usernames]"
}

output "flat_userlists_by_project" {
  value       = local.flat_userlists_by_project
  description = "Step 1 - flattened one level: lists by project -> role -> [usernames]"
}

output "flat_userlists_by_role" {
  value       = local.flat_userlists_by_role
  description = "Step 2 - flattened second level: lists by role -> [usernames]"
}

output "flat_usernames" {
  value       = local.flat_usernames
  description = "Step 3 - flattened third level: list of username strings (may contain duplicates)"
}

output "distinct_usernames" {
  value       = local.distinct_usernames
  description = "Step 4 - distinct usernames list"
}

output "usernames_from_project_permissions" {
  value       = local.usernames_from_project_permissions
  description = "Final: set of usernames derived from project_permissions"
}

output "all_usernames" {
  value       = local.all_usernames
  description = "Union of usernames_from_project_permissions and cluster_admin_usernames"
}

output "user_id_map" {
  value       = local.user_id_map
  description = "Map username -> rancher user id (from data.rancher2_user.by_name)"
}

output "cluster_id_map" {
  value       = local.cluster_id_map
  description = "Map cluster_name -> rancher cluster id"
}

output "projects_by_pair" {
  value       = local.projects_by_pair
  description = "Map 'cluster||project' -> project id"
}

output "projects_map" {
  value       = local.projects_map
  description = "Nested map { cluster_name => { project_name => project_id } }"
}

output "ro_usernames" {
  value       = local.ro_usernames
  description = "Usernames with read-only (ro) role in project_permissions"
}

output "rw_usernames" {
  value       = local.rw_usernames
  description = "Usernames with read-write (rw) role in project_permissions"
}

output "developers_user_ids" {
  value       = local.developers_user_ids
  description = "Map username -> user_id for ro role (filtered)"
}

output "super_developers_user_ids" {
  value       = local.super_developers_user_ids
  description = "Map username -> user_id for rw role (filtered)"
}

output "ops_user_ids" {
  value       = local.ops_user_ids
  description = "Map username -> user_id for cluster admins (filtered)"
}
