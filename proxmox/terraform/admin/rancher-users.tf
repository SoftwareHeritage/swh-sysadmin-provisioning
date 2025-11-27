resource "rancher2_user" "argocd" {
  name     = "ArgoCD"
  username = "argocd"
  password = var.argocd_user_password
  enabled  = true
}

resource "rancher2_global_role_binding" "argocd-role-binding" {
  name            = "argocd-role-binding"
  global_role_id  = "user"
  user_id         = rancher2_user.argocd.id
}

resource "rancher2_cluster_role_template_binding" "argocd-role-template-binding" {
  for_each = tomap(local.cluster_id_by_name)

  name     = each.key
  cluster_id = each.value
  role_template_id = "cluster-owner"
  user_id  = rancher2_user.argocd.id
}

resource "rancher2_custom_user_token" "argocd-token" {
  for_each = tomap(local.cluster_id_by_name)

  username = rancher2_user.argocd.username
  password = rancher2_user.argocd.password
  cluster_id = each.value
  description = "argocd token for cluster ${each.key}"
  ttl = 0

  lifecycle {
    ignore_changes = [ttl]
  }
  depends_on = [
    rancher2_cluster_role_template_binding.argocd-role-template-binding
  ]
}

output "argocd-token-value" {
  value     = { for k, t in rancher2_custom_user_token.argocd-token : k => t.token }
  sensitive = true
}

# Collect information from locals.project_permissions which is the data
# structure driving the overall permission setup in the rancher clusters
locals {

  # TODO do we really need to build the key like this? (cluster_name||project_name)
  # set of unique project pairs encoded as "cluster||project"
  project_pair_keys = toset(flatten([
    for cluster_name, projects in local.project_permissions : [
      for project_name in keys(projects) : "${cluster_name}||${project_name}"
    ]
  ]))

  # nested map { cluster_name => { project_name => project_id } }
  project_id_by_cluster_name_and_project_name = {
    for c in local.project_clusters : c => {
      for pair, id in local.projects_by_pair_key : split("||", pair)[1] => id if split("||", pair)[0] == c
    }
  }

}

locals {
  # Final: set of usernames collected directly from local.project_permissions
  project_permissions_user_names = toset(distinct(flatten([
    for cluster_name, projects in local.project_permissions : [
      for project_name, roles in projects : flatten([
        for role_name, users in roles : users
      ])
    ]
  ])))

  base_usernames = setsubtract(local.project_permissions_user_names, local.admin_user_names)

  # keep the rest of the derived locals here (use usernames_from_project_permissions defined above)
  # union of admin and base usernames as a set
  all_user_names          = setunion(local.admin_user_names, local.base_usernames)

  base_user_ids = {
    for u in local.base_usernames :
    u => lookup(local.user_id_by_name, u, "") if lookup(local.user_id_by_name, u, "") != ""
  }
  admin_user_ids = {
    for u in local.admin_user_names :
    u => lookup(local.user_id_by_name, u, "") if lookup(local.user_id_by_name, u, "") != ""
  }
}

resource "rancher2_global_role_binding" "user-base-role-binding" {
  for_each       = local.base_user_ids

  name            = "user-base-${each.key}-role-binding"
  global_role_id  = "user-base"
  user_id         = each.value
}

resource "rancher2_global_role_binding" "admin-role-binding" {
  for_each       = local.admin_user_ids

  name            = "admin-${each.key}-role-binding"
  global_role_id  = "admin"
  user_id         = each.value
}

locals {
  # Build set of tuples { cluster_id, cluster_name, project_id, project_role_template_id, user_id }
  project_permission_tuples = toset(flatten([
    for cluster_name in keys(local.project_permissions) : [
      for project_name in keys(local.project_permissions[cluster_name]) : [
        for role_template_id in keys(local.project_permissions[cluster_name][project_name]) : [
          for user_name in local.project_permissions[cluster_name][project_name][role_template_id] : {
            cluster_id = lookup(local.cluster_id_by_name, cluster_name, cluster_name)
            cluster_name = cluster_name
            project_id = lookup(lookup(local.project_id_by_cluster_name_and_project_name, cluster_name, {}), project_name, "")
            project_name = project_name
            role_template_id = role_template_id
            user_id = lookup(local.user_id_by_name, user_name, user_name)
            user_name = user_name
          }
        ]
      ]
    ]
  ]))
}

resource "rancher2_project_role_template_binding" "users-role-template-binding" {
  # project_permission_tuples: [{ cluster_id, cluster_name, project_id, project_name, role_template_id, user_id, user_name }]
  for_each = {
    for index, config in tolist(local.project_permission_tuples):
    lower("${config.cluster_name}---${config.project_name}---${config.role_template_id}---${config.user_name}") => config
  }

  name             = each.key
  project_id       = each.value.project_id
  role_template_id = each.value.role_template_id
  user_id          = each.value.user_id
}

output "clusters" {
  value = local.cluster_id_by_name
}

output "project_permissions" {
  value       = local.project_permission_tuples
  description = "Set of {cluster_id, cluster_name, project_id, role_name_id, user_id} derived from local.project_permissions"
}