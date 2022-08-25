# Plan:
# - create cluster with terraform
# - Create nodes as usual through terraform
# - Execute registration command as last post-provisionning step

resource "rancher2_cluster" "archive-staging" {
  name = "archive-staging"
  description = "Archive staging cluster"
  rke_config {
    kubernetes_version = "v1.22.10-rancher1-1"
    network {
      plugin = "canal"
    }
  }
}

output "rancher2_cluster_archive_staging_summary" {
  sensitive = true
  value = rancher2_cluster.archive-staging.kube_config
}

output "rancher2_cluster_archive_staging_command" {
  sensitive = true
  value = rancher2_cluster.archive-staging.cluster_registration_token[0].node_command
}

module "rancher-node-staging-mgmt0" {
  source      = "../modules/node"
  vmid        = 146
  template    = var.templates["stable-zfs"]
  config      = local.config
  hostname    = "rancher-node-staging-mgmt0"
  description = "staging management node"
  hypervisor  = "pompidou"
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
    "systemctl restart docker",  # workaround
    "${rancher2_cluster.archive-staging.cluster_registration_token[0].node_command} --etcd --controlplane --worker"
  ]
}

output "rancher-node-staging-mgmt0_summary" {
  value = module.rancher-node-staging-mgmt0.summary
}

module "rancher-node-staging-worker1" {
  source      = "../modules/node"
  vmid        = 147
  template    = var.templates["stable-zfs"]
  config      = local.config
  hostname    = "rancher-node-staging-worker1"
  description = "elastic worker running in rancher cluster (loader, lister, ...)"
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
    "systemctl restart docker",  # workaround
    "${rancher2_cluster.archive-staging.cluster_registration_token[0].node_command} --worker --label node_type=generic"
  ]
}

output "rancher-node-staging-worker1_summary" {
  value = module.rancher-node-staging-worker1.summary
}

module "rancher-node-staging-worker2" {
  source      = "../modules/node"
  vmid        = 148
  template    = var.templates["stable-zfs"]
  config      = local.config
  hostname    = "rancher-node-staging-worker2"
  description = "elastic worker running in rancher cluster (loader, lister, ...)"
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
    "systemctl restart docker",  # workaround
    "${rancher2_cluster.archive-staging.cluster_registration_token[0].node_command} --worker --label node_type=worker --label swh/loader=true"
  ]
}

output "rancher-node-staging-worker2_summary" {
  value = module.rancher-node-staging-worker2.summary
}

module "rancher-node-staging-worker3" {
  source      = "../modules/node"
  vmid        = 149
  template    = var.templates["stable-zfs"]
  config      = local.config
  hostname    = "rancher-node-staging-worker3"
  description = "elastic worker running in rancher cluster (loader, lister, ...)"
  hypervisor  = "uffizi"
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory      = "8192"
  balloon     = "4096"

  networks = [{
    id      = 0
    ip      = "192.168.130.133"
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
    "systemctl restart docker",  # workaround
    "${rancher2_cluster.archive-staging.cluster_registration_token[0].node_command} --worker --label node_type=worker --label swh/loader=true"
  ]
}

output "rancher-node-staging-worker3_summary" {
  value = module.rancher-node-staging-worker3.summary
}

resource "rancher2_app_v2" "archive-staging-rancher-monitoring" {
  cluster_id = rancher2_cluster.archive-staging.id
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
