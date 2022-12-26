# Plan:
# - create cluster with terraform
# - Create nodes as usual through terraform
# - Execute registration command as last post-provisionning step

resource "rancher2_cluster" "archive-production" {
  name        = "archive-production"
  description = "Archive production cluster"
  rke_config {
    kubernetes_version = "v1.23.14-rancher1-1"
    network {
      plugin = "canal"
    }
    ingress {
      default_backend = false
      provider        = "none"
    }
    upgrade_strategy {
      drain                  = true
      max_unavailable_worker = 2
      drain_input {
        delete_local_data = true
        timeout           = 300
      }
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
  hypervisor  = "pompidou"
  sockets     = "2"
  cores       = "8"
  onboot      = true
  memory      = "16384"

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
    storage = "scratch"
    size    = "50G"
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
  hypervisor  = "mucem"
  sockets     = "2"
  cores       = "8"
  onboot      = true
  memory      = "16384"

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
    storage = "scratch"
    size    = "50G"
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
  hypervisor  = "mucem"
  sockets     = "2"
  cores       = "8"
  onboot      = true
  memory      = "16384"

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
    storage = "scratch"
    size    = "50G"
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
    size    = "50G"
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

module "rancher-node-production-worker05" {
  source      = "../modules/node"
  template    = var.templates["stable-zfs"]
  config      = local.config
  hostname    = "rancher-node-production-worker05"
  description = "Generic worker node"
  hypervisor  = "mucem"
  sockets     = "2"
  cores       = "5"
  onboot      = true
  memory      = "65536"

  networks = [{
    id      = 0
    ip      = "192.168.100.125"
    gateway = local.config["gateway_ip"]
    bridge  = local.config["bridge"]
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
    "${rancher2_cluster.archive-production.cluster_registration_token[0].node_command} --worker --label swh/loader=true --label swh/large-scratch-fs=true"
  ]
}

output "rancher-node-production-worker05_summary" {
  value = module.rancher-node-production-worker05.summary
}

resource "rancher2_app_v2" "archive-production-rancher-monitoring" {
  cluster_id    = rancher2_cluster.archive-production.id
  name          = "rancher-monitoring"
  namespace     = "cattle-monitoring-system"
  repo_name     = "rancher-charts"
  chart_name    = "rancher-monitoring"
  chart_version = "100.1.3+up19.0.3"
  values        = <<EOF
nodeExporter:
  serviceMonitor:
    enabled: true
    relabelings:
    - action: replace
      regex: ^(.*)$
      replacement: $1
      sourceLabels:
      - __meta_kubernetes_pod_node_name
      targetLabel: instance
prometheus:
  enabled: true
  prometheusSpec:
    externalLabels:
      cluster: ${rancher2_cluster.archive-production.name}
      domain: production
      environment: production
      infrastructure: kubernetes
    requests:
      cpu: 250m
      memory: 250Mi
      retention: 365d
    thanos:
      objectStorageConfig:
        key: thanos.yaml
        name: thanos-objstore-config-secret
  thanosIngress:
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-production-gandi
      metallb.universe.tf/allow-shared-ip: clusterIP
      nginx.ingress.kubernetes.io/backend-protocol: GRPC
    enabled: true
    hosts:
    - k8s-archive-production-thanos.internal.softwareheritage.org
    loadBalancerIP: 192.168.100.119
    pathType: Prefix
    tls:
    - hosts:
      - k8s-archive-production-thanos.internal.softwareheritage.org
      secretName: thanos-crt
EOF
}
