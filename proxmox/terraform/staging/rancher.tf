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
provider "rancher2" {
  api_url    = "https://rancher.euwest.azure.internal.softwareheritage.org/v3"
  # for now
  insecure = true
}

# Plan:
# - create cluster with terraform
# - Create nodes as usual through terraform
# - Retrieve the registration command (out of the cluster creation step) to provide new
#   node

resource "rancher2_cluster" "staging-workers" {
  name = "staging-workers"
  description = "staging workers cluster"
  rke_config {
    network {
      plugin = "canal"
    }
  }
}

output "rancher2_cluster_summary" {
  sensitive = true
  value = rancher2_cluster.staging-workers.kube_config
}

output "rancher2_cluster_command" {
  sensitive = true
  value = rancher2_cluster.staging-workers.cluster_registration_token[0].node_command
}

module "elastic-worker0" {
  source      = "../modules/node"
  template    = "debian-bullseye-11.3-zfs-2022-04-21"
  vmid        = 146
  config      = local.config
  hostname    = "elastic-worker0"
  description = "elastic worker running in rancher cluster"
  hypervisor  = "uffizi"
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory  = "4096"
  balloon = "1024"

  networks = [{
    id      = 0
    ip      = "192.168.130.130"
    gateway = local.config["gateway_ip"]
    macaddr = "72:CF:A9:AC:B8:EE"
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
    "${rancher2_cluster.staging-workers.cluster_registration_token[0].node_command} --etcd --controlplane --worker"
  ]
}

output "elastic-worker0_summary" {
  value = module.elastic-worker0.summary
}

module "elastic-worker1" {
  source      = "../modules/node"
  template    = "debian-bullseye-11.3-zfs-2022-04-21"
  config      = local.config
  hostname    = "elastic-worker1"
  description = "elastic worker running in rancher cluster"
  hypervisor  = "uffizi"
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory  = "4096"
  balloon = "1024"

  networks = [{
    id      = 0
    ip      = "192.168.130.131"
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
    "${rancher2_cluster.staging-workers.cluster_registration_token[0].node_command} --etcd --controlplane --worker"
  ]
}

output "elastic-worker1_summary" {
  value = module.elastic-worker1.summary
}

module "elastic-worker2" {
  source      = "../modules/node"
  template    = "debian-bullseye-11.3-zfs-2022-04-21"
  config      = local.config
  hostname    = "elastic-worker2"
  description = "elastic worker running in rancher cluster"
  hypervisor  = "uffizi"
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory  = "4096"
  balloon = "1024"

  networks = [{
    id      = 0
    ip      = "192.168.130.132"
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
    "${rancher2_cluster.staging-workers.cluster_registration_token[0].node_command} --etcd --controlplane --worker"
  ]
}

output "elastic-worker2_summary" {
  value = module.elastic-worker2.summary
}

resource "rancher2_app_v2" "rancher-monitoring" {
  cluster_id = rancher2_cluster.staging-workers.id
  name = "rancher-monitoring"
  namespace = "cattle-monitoring-system"
  repo_name = "rancher-charts"
  chart_name = "rancher-monitoring"
  # chart_version = "9.4.200"
  chart_version = "100.1.0+up19.0.3"
  values = <<EOF
prometheus:
  prometheusSpec:
    requests:
      cpu: "250m"
      memory: "250Mi"
EOF
}

