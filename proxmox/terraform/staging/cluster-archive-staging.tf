# Plan:
# - create cluster with terraform
# - Create nodes as usual through terraform
# - Execute registration command as last post-provisionning step

resource "rancher2_cluster" "archive-staging" {
  name = "archive-staging"
  description = "Archive staging cluster"
  rke_config {
    kubernetes_version = "v1.22.11-rancher1-1"
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

# loader nodes must have the 2nd disk on a local storage to not generate too much
# traffic on ceph
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
    "${rancher2_cluster.archive-staging.cluster_registration_token[0].node_command} --worker --label node_type=generic --label swh/rpc=true"
  ]
}

output "rancher-node-staging-worker1_summary" {
  value = module.rancher-node-staging-worker1.summary
}

# loader nodes must have the 2nd disk on a local storage to not generate too much
# traffic on ceph
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
    storage = "uffizi-scratch"
    size    = "50G"
    }
  ]

  post_provision_steps = [
    "systemctl restart docker",  # workaround
    "${rancher2_cluster.archive-staging.cluster_registration_token[0].node_command} --worker --label node_type=worker --label swh/rpc=true --label swh/loader=true --label swh/lister=true"
  ]
}

output "rancher-node-staging-worker2_summary" {
  value = module.rancher-node-staging-worker2.summary
}

# loader nodes must have the 2nd disk on a local storage to not generate too much
# traffic on ceph
module "rancher-node-staging-worker3" {
  source      = "../modules/node"
  vmid        = 149
  template    = var.templates["stable-zfs"]
  config      = local.config
  hostname    = "rancher-node-staging-worker3"
  description = "elastic worker running in rancher cluster (loader, lister, ...)"
  hypervisor  = "pompidou"
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
    storage = "scratch"
    size    = "50G"
    }
  ]

  post_provision_steps = [
    "systemctl restart docker",  # workaround
    "${rancher2_cluster.archive-staging.cluster_registration_token[0].node_command} --worker --label node_type=worker --label swh/rpc=true --label swh/loader=true --label swh/lister=true"
  ]
}

output "rancher-node-staging-worker3_summary" {
  value = module.rancher-node-staging-worker3.summary
}

# loader nodes must have the 2nd disk on a local storage to not generate too much
# traffic on ceph
module "rancher-node-staging-worker4" {
  source      = "../modules/node"
  vmid        = 137
  template    = var.templates["stable-zfs"]
  config      = local.config
  hostname    = "rancher-node-staging-worker4"
  description = "elastic worker running in rancher cluster (loader, lister, ...)"
  hypervisor  = "pompidou"
  sockets     = "1"
  cores       = "8"
  onboot      = true
  memory      = "16384"
  balloon     = "8192"

  networks = [{
    id      = 0
    ip      = "192.168.130.134"
    gateway = local.config["gateway_ip"]
    bridge  = local.config["vlan"]
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
    "${rancher2_cluster.archive-staging.cluster_registration_token[0].node_command} --worker --label node_type=worker  --label swh/rpc=true --label swh/loader=true --label swh/lister=true"
  ]
}

output "rancher-node-staging-worker4_summary" {
  value = module.rancher-node-staging-worker4.summary
}


resource "rancher2_app_v2" "archive-staging-rancher-monitoring" {
  cluster_id = rancher2_cluster.archive-staging.id
  name = "rancher-monitoring"
  namespace = "cattle-monitoring-system"
  repo_name = "rancher-charts"
  chart_name = "rancher-monitoring"
  chart_version = "100.1.3+up19.0.3"
  values = <<EOF
prometheus:
  enabled: true
  prometheusSpec:
    requests:
      cpu: 250m
      memory: 250Mi
    # mark metrics with discriminative information, check official doc for details
    # see https://thanos.io/tip/thanos/quick-tutorial.md/#external-labels
    externalLabels:
      environment: staging
      infrastructure: kubernetes
      domain: staging
      cluster_name: ${rancher2_cluster.archive-staging.name}
    thanos:
      # thanos-objstore-config-secret is installed in namespace cattle-monitoring-system
      # see k8s-private-data:archive-staging/thanos-objstore-config-secret.yaml. And
      # https://prometheus-operator.dev/docs/operator/thanos/#configuring-thanos-object-storage
      objectStorageConfig:
        key: thanos.yaml
        name: thanos-objstore-config-secret
  # thanos sidecar
  thanosService:
    enabled: false
  # thanos ingress sidecar
  thanosIngress:
    enabled: false
  thanosServiceMonitor:
    enabled: false
  thanosServiceExternal:
    enabled: false
EOF
}
