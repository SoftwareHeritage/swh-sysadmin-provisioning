# This declares terraform manifests to provision vms and register containers within
# those to a rancher (clusters management service) instance.

# Each software has the following responsibilities:
# - proxmox: provision vms (with docker dependency)
# - rancher: installs kube cluster within containers (running on vms)

# Requires (RANCHER_ACCESS_KEY and RANCHER_SECRET_KEY) in your shell environment
# $ cat ~/.config/terraform/swh/setup.sh
# ...
# key_entry=operations/rancher/azure/elastic-loader-lister-keys
# export RANCHER_ACCESS_KEY=$(swhpass ls $key_entry | head -1 | cut -d: -f1)
# export RANCHER_SECRET_KEY=$(swhpass ls $key_entry | head -1 | cut -d: -f2)

# Plan:
# - create cluster with terraform
# - Create nodes as usual through terraform
# - Retrieve the registration command (out of the cluster creation step) to provide new
#   node

resource "rancher2_cluster" "cluster-graphql3" {
  name = "cluster-graphql3"
  description = "3rd (tryout) graphql staging cluster"
  rke_config {
    kubernetes_version = "v1.21.12-rancher1-1"
    network {
      plugin = "canal"
    }
  }
}

output "rancher2_cluster_graphql3_summary" {
  sensitive = true
  value = rancher2_cluster.cluster-graphql3.kube_config
}

output "rancher2_cluster_graphql3_command" {
  sensitive = true
  value = rancher2_cluster.cluster-graphql3.cluster_registration_token[0].node_command
}

module "graphql-worker3" {
  source      = "../modules/node"
  vmid        = 165
  template    = var.templates["stable-zfs"]
  config      = local.config
  hostname    = "graphql-worker3"
  description = "graphql worker running in rancher cluster"
  hypervisor  = "uffizi"
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory      = "16384"
  balloon     = "8192"

  networks = [{
    id      = 0
    ip      = "192.168.130.153"
    gateway = local.config["gateway_ip"]
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
    "systemctl restart docker",  # workaround
    "${rancher2_cluster.cluster-graphql3.cluster_registration_token[0].node_command} --etcd --controlplane --worker"
  ]
}

output "graphql-worker3_summary" {
  value = module.graphql-worker3.summary
}

# module "graphql-worker2" {
#   source      = "../modules/node"
#   vmid        = 164
#   template    = var.templates["stable-zfs"]
#   config      = local.config
#   hostname    = "graphql-worker2"
#   description = "graphql worker running in rancher cluster"
#   hypervisor  = "uffizi"
#   sockets     = "1"
#   cores       = "4"
#   onboot      = true
#   memory      = "8192"
#   balloon     = "4096"

#   networks = [{
#     id      = 0
#     ip      = "192.168.130.152"
#     gateway = local.config["gateway_ip"]
#     bridge  = "vmbr443"
#   }]

#   storages = [{
#     storage = "proxmox"
#     size    = "20G"
#     }, {
#     storage = "proxmox"
#     size    = "50G"
#     }
#   ]

#   post_provision_steps = [
#     "systemctl restart docker",  # workaround
#     "${rancher2_cluster.cluster-graphql3.cluster_registration_token[0].node_command} --controlplane"
#   ]
# }

# output "graphql-worker2_summary" {
#   value = module.graphql-worker2.summary
# }
