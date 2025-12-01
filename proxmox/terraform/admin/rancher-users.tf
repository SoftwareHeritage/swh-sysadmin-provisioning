locals {
  lead_developers = var.lead_dev_user_names
  developers = var.dev_user_names
  all_users = setunion(local.lead_developers, local.developers)
  project_permissions = {
    "production" = {
      "Default" = {
        "read-only" = local.all_users
        "project-owner" = []
      }
    }
    "admin" = {
      "Default" = {
        "read-only" = []
        "project-owner" = []
      }
    }
    "staging" = {
      "Default" = {
        "read-only" = local.developers
        "project-owner" = local.lead_developers
      }
    }
    "test-staging" = {
      "Default" = {
        "read-only" = []
        "project-owner" = []
      }
    }
  }
}

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
  for_each = tomap(local.cluster_id_by_alias)

  name     = each.key
  cluster_id = each.value
  role_template_id = "cluster-owner"
  user_id  = rancher2_user.argocd.id
}

resource "rancher2_custom_user_token" "argocd-token" {
  for_each = tomap(local.cluster_id_by_alias)

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

locals {
  # Final: set of usernames collected directly from var.project_permissions
  project_permissions_user_names = toset(distinct(flatten([
    for cluster_name, projects in local.project_permissions : [
      for project_name, roles in projects : flatten([
        for role_name, users in roles : users
      ])
    ]
  ])))

  base_usernames = setsubtract(local.project_permissions_user_names, var.admin_user_names)

  # keep the rest of the derived locals here (use usernames_from_project_permissions defined above)
  # union of admin and base usernames as a set
  all_user_names          = setunion(var.admin_user_names, local.base_usernames)

  base_user_ids = {
    for u in local.base_usernames :
    u => lookup(local.user_id_by_name, u, "") if lookup(local.user_id_by_name, u, "") != ""
  }
  admin_user_ids = {
    for u in var.admin_user_names :
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
  # Build set of tuples { cluster_name, project_id, project_role_template_id, user_id }
  project_permission_tuples = toset(flatten([
    for cluster_alias, cluster_config in local.project_permissions : [
      for project_name, project_config in cluster_config : [
        for role_template_id, usernames in project_config : [
          for user_name in usernames : {
            cluster_alias = cluster_alias
            project_name = project_name
            project_id = local.project_id_by_cluster_alias_and_name[cluster_alias][project_name]
            role_template_id = role_template_id
            user_id = local.user_id_by_name[user_name]
            user_name = user_name
          }
        ]
      ]
    ]
  ]))
}

resource "rancher2_project_role_template_binding" "users-role-template-binding" {
  # project_permission_tuples: [{ cluster_alias, project_id, project_name, role_template_id, user_id, user_name }]
  for_each = {
    for index, config in tolist(local.project_permission_tuples):
    lower("${config.cluster_alias}---${config.project_name}---${config.role_template_id}---${config.user_name}") => config
  }

  name             = each.key
  project_id       = each.value.project_id
  role_template_id = each.value.role_template_id
  user_id          = each.value.user_id
}

output "clusters" {
  value = local.cluster_id_by_alias
  sensitive = true
}

output "project_permissions" {
  value       = local.project_permission_tuples
  description = "Set of {cluster_alias, project_id, role_name_id, user_id} derived from var.project_permissions"
  sensitive   = true
}
