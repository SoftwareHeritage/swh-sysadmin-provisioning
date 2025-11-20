resource "rancher2_user" "argocd" {
  name = "ArgoCD"
  username = "argocd"
  password = "changemeplease"
  enabled = true
  must_change_password = true
}

resource "rancher2_global_role_binding" "argocd-role-binding" {
  name = "argocd-role-binding"
  global_role_id = "user"
  user_id = rancher2_user.argocd.id
}
