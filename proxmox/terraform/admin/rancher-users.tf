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
  for_each = tomap(local.cluster_id_map)

  name     = each.key
  cluster_id = each.value
  role_template_id = "cluster-owner"
  user_id  = rancher2_user.argocd.id
}

resource "rancher2_custom_user_token" "argocd-token" {
  for_each = tomap(local.cluster_id_map)

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
