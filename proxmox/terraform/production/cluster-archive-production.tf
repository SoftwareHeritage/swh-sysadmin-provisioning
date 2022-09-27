# Plan:
# - create cluster with terraform
# - Create nodes as usual through terraform
# - Execute registration command as last post-provisionning step

resource "rancher2_cluster" "archive-production" {
  name = "archive-production"
  description = "Archive production cluster"
  rke_config {
    kubernetes_version = "v1.22.13-rancher1-1"
    network {
      plugin = "canal"
    }
    ingress {
      provider = "none"
    }
  }
}

output "rancher2_cluster_archive_production_summary" {
  sensitive = true
  value = rancher2_cluster.archive-production.kube_config
}

output "rancher2_cluster_archive_production_command" {
  sensitive = true
  value = rancher2_cluster.archive-production.cluster_registration_token[0].node_command
}

module "rancher-node-production-mgmt1" {
  source      = "../modules/node"
  template    = var.templates["stable-zfs"]
  config      = local.config
  hostname    = "rancher-node-production-mgmt1"
  description = "production management node"
  hypervisor  = "branly"
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory      = "8192"
  balloon     = "4096"

  networks = [{
    id      = 0
    ip      = "192.168.100.120"
    gateway = local.config["gateway_ip"]
    bridge  = local.config["bridge"]
  }]

  storages = [{
    storage = "proxmox"
    size    = "20G"
    }, {
    storage = "proxmox"
    size    = "20G"
    }
  ]

  post_provision_steps = [
    "systemctl restart docker",  # workaround
    "${rancher2_cluster.archive-production.cluster_registration_token[0].node_command} --etcd --controlplane"
  ]
}

output "rancher-node-production-mgmt1_summary" {
  value = module.rancher-node-production-mgmt1.summary
}

module "rancher-node-production-worker01" {
  source      = "../modules/node"
  template    = var.templates["stable-zfs"]
  config      = local.config
  hostname    = "rancher-node-production-worker01"
  description = "Generic worker node"
  hypervisor  = "uffizi"
  sockets     = "2"
  cores       = "8"
  onboot      = true
  memory      = "16384"
  balloon     = "8192"

  networks = [{
    id      = 0
    ip      = "192.168.100.121"
    gateway = local.config["gateway_ip"]
    bridge  = local.config["bridge"]
  }]

  storages = [{
    storage = "proxmox"
    size    = "20G"
    }, {
    storage = "uffizi-scratch"
    size    = "20G"
    }
  ]

  post_provision_steps = [
    "systemctl restart docker",  # workaround
    "${rancher2_cluster.archive-production.cluster_registration_token[0].node_command}  --worker"
  ]
}

output "rancher-node-production-worker01_summary" {
  value = module.rancher-node-production-worker01.summary
}

module "rancher-node-production-worker02" {
  source      = "../modules/node"
  template    = var.templates["stable-zfs"]
  config      = local.config
  hostname    = "rancher-node-production-worker02"
  description = "Generic worker node"
  hypervisor  = "uffizi"
  sockets     = "2"
  cores       = "8"
  onboot      = true
  memory      = "16384"
  balloon     = "8192"

  networks = [{
    id      = 0
    ip      = "192.168.100.122"
    gateway = local.config["gateway_ip"]
    bridge  = local.config["bridge"]
  }]

  storages = [{
    storage = "proxmox"
    size    = "20G"
    }, {
    storage = "uffizi-scratch"
    size    = "20G"
    }
  ]

  post_provision_steps = [
    "systemctl restart docker",  # workaround
    "${rancher2_cluster.archive-production.cluster_registration_token[0].node_command} --worker"
  ]
}

output "rancher-node-production-worker02_summary" {
  value = module.rancher-node-production-worker02.summary
}

module "rancher-node-production-worker03" {
  source      = "../modules/node"
  template    = var.templates["stable-zfs"]
  config      = local.config
  hostname    = "rancher-node-production-worker03"
  description = "Generic worker node"
  hypervisor  = "uffizi"
  sockets     = "2"
  cores       = "8"
  onboot      = true
  memory      = "16384"
  balloon     = "8192"

  networks = [{
    id      = 0
    ip      = "192.168.100.123"
    gateway = local.config["gateway_ip"]
    bridge  = local.config["bridge"]
  }]

  storages = [{
    storage = "proxmox"
    size    = "20G"
    }, {
    storage = "uffizi-scratch"
    size    = "20G"
    }
  ]

  post_provision_steps = [
    "systemctl restart docker",  # workaround
    "${rancher2_cluster.archive-production.cluster_registration_token[0].node_command} --worker"
  ]
}

output "rancher-node-production-worker03_summary" {
  value = module.rancher-node-production-worker03.summary
}

module "rancher-node-production-worker04" {
  source      = "../modules/node"
  template    = var.templates["stable-zfs"]
  config      = local.config
  hostname    = "rancher-node-production-worker04"
  description = "Generic worker node"
  hypervisor  = "hypervisor3"
  sockets     = "2"
  cores       = "3"
  onboot      = true
  memory      = "16384"
  balloon     = "8192"

  networks = [{
    id      = 0
    ip      = "192.168.100.124"
    gateway = local.config["gateway_ip"]
    bridge  = local.config["bridge"]
  }]

  storages = [{
    storage = "proxmox"
    size    = "20G"
    }, {
    storage = "scratch"
    size    = "20G"
    }
  ]

  post_provision_steps = [
    "systemctl restart docker",  # workaround
    "${rancher2_cluster.archive-production.cluster_registration_token[0].node_command} --worker"
  ]
}

output "rancher-node-production-worker04_summary" {
  value = module.rancher-node-production-worker04.summary
}

resource "rancher2_app_v2" "archive-production-rancher-monitoring" {
  cluster_id = rancher2_cluster.archive-production.id
  name = "rancher-monitoring"
  namespace = "cattle-monitoring-system"
  repo_name = "rancher-charts"
  chart_name = "rancher-monitoring"
  chart_version = "100.1.3+up19.0.3"
  values = <<EOF
prometheus:
  prometheusSpec:
    requests:
      cpu: "250m"
      memory: "250Mi"
      retention: 365d
EOF
}
