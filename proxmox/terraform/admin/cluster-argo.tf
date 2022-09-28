resource "rancher2_cluster" "cluster-argo" {
  name        = "cluster-argo"
  description = "cluster for argo tools (cd, worfklows)"

  rke_config {
    kubernetes_version = "v1.22.11-rancher1-1"
    network {
      plugin = "canal"
    }
    ingress {
      provider = "none"
    }
 }
}

output "cluster-argo-config-summary" {
  sensitive = true
  value     = rancher2_cluster.cluster-argo.kube_config
}

output "cluster-argo-register-command" {
  sensitive = true
  value     = rancher2_cluster.cluster-argo.cluster_registration_token[0].node_command
}

module "argo-worker01" {
  hostname = "argo-worker01"
  vmid     = 166

  source      = "../modules/node"
  template    = var.templates["stable-zfs"]
  config      = local.config
  description = "Argo node with etcd, controlplane and worker roles"
  hypervisor  = "uffizi"
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory      = "16384"
  balloon     = "8192"

  networks = [{
    id      = 0
    ip      = "192.168.50.40"
    gateway = local.config["gateway_ip"]
    bridge  = local.config["vlan"]
  }]

  storages = [{
    storage = "proxmox"
    size    = "20G"
    }, {
    storage = "proxmox"
    size    = "50G"
    }
  ]

  post_provision_steps = [
    "systemctl restart docker", # workaround
    "${rancher2_cluster.cluster-argo.cluster_registration_token[0].node_command} --etcd --controlplane --worker"
  ]
}

module "argo-worker02" {
  hostname = "argo-worker02"
  vmid     = 167

  source      = "../modules/node"
  template    = var.templates["stable-zfs"]
  config      = local.config
  description = "Argo worker"
  hypervisor  = "pompidou"
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory      = "8192"
  balloon     = "4096"

  networks = [{
    id      = 0
    ip      = "192.168.50.41"
    gateway = local.config["gateway_ip"]
    bridge  = local.config["vlan"]
  }]

  storages = [{
    storage = "proxmox"
    size    = "20G"
    }, {
    storage = "proxmox"
    size    = "50G"
    }
  ]

  post_provision_steps = [
    "systemctl restart docker", # workaround
    "${rancher2_cluster.cluster-argo.cluster_registration_token[0].node_command} --worker"
  ]
}
