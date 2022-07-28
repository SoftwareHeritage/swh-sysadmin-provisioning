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

resource "rancher2_cluster" "cluster-graphql" {
  name = "cluster-graphql"
  description = "graphql staging cluster"
  rke_config {
    network {
      plugin = "canal"
    }
  }
}

output "rancher2_cluster_graphql_summary" {
  sensitive = true
  value = rancher2_cluster.cluster-graphql.kube_config
}

output "rancher2_cluster_graphql_command" {
  sensitive = true
  value = rancher2_cluster.cluster-graphql.cluster_registration_token[0].node_command
}

module "graphql-worker0" {
  source      = "../modules/node"
  vmid        = 162
  template    = var.templates["stable-zfs"]
  config      = local.config
  hostname    = "graphql-worker0"
  description = "elastic worker running in rancher cluster"
  hypervisor  = "uffizi"
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory      = "8192"
  balloon     = "4096"

  networks = [{
    id      = 0
    ip      = "192.168.130.150"
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
    "${rancher2_cluster.cluster-graphql.cluster_registration_token[0].node_command} --etcd --controlplane --worker"
  ]
}

output "graphql-worker0_summary" {
  value = module.graphql-worker0.summary
}

module "graphql-worker1" {
  source      = "../modules/node"
  vmid        = 163
  template    = var.templates["stable-zfs"]
  config      = local.config
  hostname    = "graphql-worker1"
  description = "graphql worker running in rancher cluster"
  hypervisor  = "uffizi"
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory      = "8192"
  balloon     = "4096"

  networks = [{
    id      = 0
    ip      = "192.168.130.151"
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
    "${rancher2_cluster.cluster-graphql.cluster_registration_token[0].node_command} --etcd --controlplane --worker"
  ]
}

output "graphql-worker1_summary" {
  value = module.graphql-worker1.summary
}
