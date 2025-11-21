resource "rancher2_user" "argocd" {
  name = "ArgoCD"
  username = "argocd"
  password = var.argocd_user_password
  enabled = true
}

resource "rancher2_global_role_binding" "argocd-role-binding" {
  name = "argocd-role-binding"
  global_role_id = "user"
  user_id = rancher2_user.argocd.id
}

resource "rancher2_cluster_role_template_binding" "argocd-role-template-binding" {
  for_each = tomap(var.clusters_map)
  name = each.key
  cluster_id = each.value
  role_template_id = "cluster-owner"
  user_id = rancher2_user.argocd.id
}

resource "rancher2_custom_user_token" "argocd-token" {
  for_each = tomap(var.clusters_map)

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
  value = { for k, t in rancher2_custom_user_token.argocd-token : k => t.token }
  sensitive = true
}
