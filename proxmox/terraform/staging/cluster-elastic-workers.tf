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

output "rancher2_cluster_staging_workers_summary" {
  sensitive = true
  value = rancher2_cluster.staging-workers.kube_config
}

output "rancher2_cluster_staging_worker_command" {
  sensitive = true
  value = rancher2_cluster.staging-workers.cluster_registration_token[0].node_command
}

module "elastic-worker0" {
  source      = "../modules/node"
  template    = var.templates["stable-zfs"]
  vmid        = 146
  config      = local.config
  hostname    = "elastic-worker0"
  description = "elastic worker running in rancher cluster"
  hypervisor  = "uffizi"
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory      = "8192"
  balloon     = "4096"

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
  template    = var.templates["stable-zfs"]
  config      = local.config
  hostname    = "elastic-worker1"
  description = "elastic worker running in rancher cluster"
  hypervisor  = "uffizi"
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory      = "8192"
  balloon     = "4096"

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
  template    = var.templates["stable-zfs"]
  config      = local.config
  hostname    = "elastic-worker2"
  description = "elastic worker running in rancher cluster"
  hypervisor  = "uffizi"
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory      = "8192"
  balloon     = "4096"

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

resource "rancher2_catalog_v2" "keda" {
  cluster_id = rancher2_cluster.staging-workers.id
  name       = "keda"
  url        = "https://kedacore.github.io/charts/"
}

resource "rancher2_app_v2" "keda" {
  cluster_id = rancher2_cluster.staging-workers.id
  name = "keda"
  namespace = "kedacore"
  repo_name = "keda"
  chart_name = "keda"
  chart_version = "2.6.2"
}
