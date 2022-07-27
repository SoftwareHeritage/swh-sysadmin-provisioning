# - Create a rancher cluster
# - Create 3 compute nodes
resource "rancher2_cluster" "deployment_internship" {
  name        = "deployment-internship"
  description = "staging cluster for deployment test"

  rke_config {
    kubernetes_version = "v1.21.12-rancher1-1"
    network {
      plugin = "canal"
    }
  }
}

output "deployment_internship_cluster_summary" {
  sensitive = true
  value     = rancher2_cluster.deployment_internship.kube_config
}

output "deployment_internship_cluster_command" {
  sensitive = true
  value     = rancher2_cluster.deployment_internship.cluster_registration_token[0].node_command
}

module "rancher_node_internship0" {
  hostname = "rancher-node-intership0"

  source      = "../modules/node"
  template    = var.templates["stable-zfs"]
  config      = local.config
  description = "Rancher node for the internship"
  hypervisor  = "uffizi"
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory      = "8192"
  balloon     = "4096"

  networks = [{
    id      = 0
    ip      = "192.168.130.140"
    gateway = local.config["gateway_ip"]
    macaddr = ""
    bridge  = "vmbr443"
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
    "${rancher2_cluster.deployment_internship.cluster_registration_token[0].node_command} --etcd --controlplane --worker"
  ]
}

output "rancher_node_internship0_summary" {
  value = module.rancher_node_internship0.summary
}

module "rancher_node_internship1" {
  hostname = "rancher-node-intership1"

  source      = "../modules/node"
  template    = var.templates["stable-zfs"]
  config      = local.config
  description = "Rancher node for the internship"
  hypervisor  = "uffizi"
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory      = "8192"
  balloon     = "4096"

  networks = [{
    id      = 0
    ip      = "192.168.130.141"
    gateway = local.config["gateway_ip"]
    macaddr = ""
    bridge  = "vmbr443"
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
    "${rancher2_cluster.deployment_internship.cluster_registration_token[0].node_command} --etcd --controlplane --worker"
  ]
}

output "rancher_node_internship1_summary" {
  value = module.rancher_node_internship1.summary
}

module "rancher_node_internship2" {
  hostname = "rancher-node-intership2"

  source      = "../modules/node"
  template    = var.templates["stable-zfs"]
  config      = local.config
  description = "Rancher node for the internship"
  hypervisor  = "uffizi"
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory      = "8192"
  balloon     = "4096"

  networks = [{
    id      = 0
    ip      = "192.168.130.142"
    gateway = local.config["gateway_ip"]
    macaddr = ""
    bridge  = "vmbr443"
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
    "${rancher2_cluster.deployment_internship.cluster_registration_token[0].node_command} --etcd --controlplane --worker"
  ]
}

output "rancher_node_internship2_summary" {
  value = module.rancher_node_internship2.summary
}
