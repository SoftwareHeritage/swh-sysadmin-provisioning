resource "rancher2_cluster_v2" "archive-staging-rke2" {
  name               = "archive-staging-rke2"
  kubernetes_version = "v1.24.9+rke2r2"
  rke_config {
    upgrade_strategy {
      worker_drain_options {
        enabled               = true
        delete_empty_dir_data = true
        timeout               = 300
      }
    }
  }
}

output "rancher2_cluster_archive_staging_rke2_summary" {
  sensitive = true
  value     = rancher2_cluster_v2.archive-staging-rke2.kube_config
}

output "rancher2_cluster_archive_staging_rke2_command" {
  sensitive = true
  value     = rancher2_cluster_v2.archive-staging-rke2.cluster_registration_token[0].node_command
}

module "rancher-node-staging-rke2-mgmt1" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "pompidou"
  onboot      = true

  template    = var.templates["stable-zfs"]
  hostname    = "rancher-node-staging-rke2-mgmt1"
  description = "staging rke2 management node"
  sockets     = "1"
  cores       = "4"
  memory      = "16384"
  balloon     = "16384"

  networks = [{
    id      = 0
    ip      = "192.168.130.140"
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
    "${rancher2_cluster_v2.archive-staging-rke2.cluster_registration_token[0].node_command} --etcd --controlplane"
  ]
}

output "rancher-node-staging-rke2-mgmt1_summary" {
  value = module.rancher-node-staging-rke2-mgmt1.summary
}

resource "rancher2_app_v2" "archive-staging-rke2-rancher-monitoring" {
  cluster_id    = rancher2_cluster_v2.archive-staging-rke2.cluster_v1_id
  name          = "rancher-monitoring"
  namespace     = "cattle-monitoring-system"
  repo_name     = "rancher-charts"
  chart_name    = "rancher-monitoring"
  chart_version = "102.0.1+up40.1.2"
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
      cluster: ${rancher2_cluster_v2.archive-staging-rke2.name}
      domain: staging
      environment: staging
      infrastructure: kubernetes
    requests:
      cpu: 250m
      memory: 250Mi
    thanos:
      objectStorageConfig:
        key: thanos.yaml
        name: thanos-objstore-config-secret
    resources:
      limits:
        memory: 5000Mi
        cpu: 2000m
      requests:
        memory: 3500Mi
        cpu: 750m
  thanosIngress:
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-production-gandi
      metallb.universe.tf/allow-shared-ip: clusterIP
      nginx.ingress.kubernetes.io/backend-protocol: GRPC
    enabled: true
    hosts:
    - k8s-archive-staging-rke2-thanos.internal.staging.swh.network
    loadBalancerIP: 192.168.100.119
    pathType: Prefix
    tls:
    - hosts:
      - k8s-archive-staging-rke2-thanos.internal.staging.swh.network
      secretName: thanos-crt
EOF
}

# Dedicated node for rpc services (e.g. graphql, ...)
module "rancher-node-staging-rke2-worker1" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "pompidou"
  onboot      = true

  template    = var.templates["stable-zfs"]
  hostname    = "rancher-node-staging-rke2-worker1"
  description = "elastic worker for rpc services (e.g. graphql, ...)"
  sockets     = "1"
  cores       = "6"
  memory      = "32768"
  balloon     = "16384"

  networks = [{
    id      = 0
    ip      = "192.168.130.141"
    gateway = local.config["gateway_ip"]
    bridge  = local.config["bridge"]
  }]

  storages = [{
    storage = "proxmox"
    size    = "20G"
    }, {
    storage = "scratch"
    size    = "100G"
    }
  ]

  post_provision_steps = [
    "systemctl restart docker",  # workaround
    "${rancher2_cluster_v2.archive-staging-rke2.cluster_registration_token[0].node_command} --worker --label node_type=generic --label swh/rpc=true"
  ]
}

output "rancher-node-staging-rke2-worker1_summary" {
  value = module.rancher-node-staging-rke2-worker1.summary
}

# loader nodes must have a 2nd disk on hypervisor local storage to avoid
# unnecessary ceph traffic on ceph
module "rancher-node-staging-rke2-worker2" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "pompidou"
  onboot      = true

  template    = var.templates["stable-zfs"]
  hostname    = "rancher-node-staging-rke2-worker2"
  description = "elastic worker for computations (e.g. loader, lister, ...)"
  sockets     = "1"
  cores       = "6"
  memory      = "32768"
  balloon     = "16384"

  networks = [{
    id      = 0
    ip      = "192.168.130.142"
    gateway = local.config["gateway_ip"]
    bridge  = local.config["bridge"]
  }]

  storages = [{
    storage = "proxmox"
    size    = "20G"
    }, {
    storage = "scratch"
    size    = "100G"
    }
  ]

  post_provision_steps = [
    "systemctl restart docker",  # workaround
    "${rancher2_cluster_v2.archive-staging-rke2.cluster_registration_token[0].node_command} --worker --label node_type=worker --label swh/rpc=true --label swh/loader=true --label swh/lister=true"
  ]
}

output "rancher-node-staging-rke2-worker2_summary" {
  value = module.rancher-node-staging-rke2-worker2.summary
}

# loader nodes must have a 2nd disk on hypervisor local storage to avoid
# unnecessary ceph traffic on ceph
module "rancher-node-staging-rke2-worker3" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "pompidou"
  onboot      = true

  template    = var.templates["stable-zfs"]
  hostname    = "rancher-node-staging-rke2-worker3"
  description = "elastic worker for computations (e.g. loader, lister, ...)"
  sockets     = "1"
  cores       = "6"
  memory      = "32768"
  balloon     = "16384"

  networks = [{
    id      = 0
    ip      = "192.168.130.143"
    gateway = local.config["gateway_ip"]
    bridge  = local.config["bridge"]
  }]

  storages = [{
    storage = "proxmox"
    size    = "20G"
    }, {
    storage = "scratch"
    size    = "100G"
    }
  ]

  post_provision_steps = [
    "systemctl restart docker",  # workaround
    "${rancher2_cluster_v2.archive-staging-rke2.cluster_registration_token[0].node_command} --worker --label node_type=worker --label swh/rpc=true --label swh/loader=true --label swh/lister=true --label swh/indexer=true"
  ]
}

output "rancher-node-staging-rke2-worker3_summary" {
  value = module.rancher-node-staging-rke2-worker3.summary
}

# loader nodes must have a 2nd disk on hypervisor local storage to avoid
# unnecessary ceph traffic on ceph
module "rancher-node-staging-rke2-worker4" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "pompidou"
  onboot      = true

  template    = var.templates["stable-zfs"]
  hostname    = "rancher-node-staging-rke2-worker4"
  description = "elastic worker for computations (e.g. loader, lister, ...)"
  sockets     = "1"
  cores       = "6"
  memory      = "32768"
  balloon     = "16384"

  networks = [{
    id      = 0
    ip      = "192.168.130.144"
    gateway = local.config["gateway_ip"]
    bridge  = local.config["bridge"]
  }]

  storages = [{
    storage = "proxmox"
    size    = "20G"
    }, {
    storage = "scratch"
    size    = "100G"
    }
  ]

  post_provision_steps = [
    "systemctl restart docker",  # workaround
    "${rancher2_cluster_v2.archive-staging-rke2.cluster_registration_token[0].node_command} --worker --label node_type=worker --label swh/rpc=true --label swh/loader=true"
  ]
}

output "rancher-node-staging-rke2-worker4_summary" {
  value = module.rancher-node-staging-rke2-worker4.summary
}

# loader nodes must have a 2nd disk on hypervisor local storage to avoid
# unnecessary ceph traffic on ceph
module "rancher-node-staging-rke2-worker5" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "pompidou"
  onboot      = true

  template    = var.templates["stable-zfs"]
  hostname    = "rancher-node-staging-rke2-worker5"
  description = "elastic worker for computations (e.g. loader, lister, ...)"
  sockets     = "1"
  cores       = "6"
  memory      = "32768"
  balloon     = "16384"

  networks = [{
    id      = 0
    ip      = "192.168.130.145"
    gateway = local.config["gateway_ip"]
    bridge  = local.config["bridge"]
  }]

  storages = [{
    storage = "proxmox"
    size    = "20G"
    }, {
    storage = "scratch"
    size    = "100G"
    }
  ]

  post_provision_steps = [
    "systemctl restart docker",  # workaround
    "${rancher2_cluster_v2.archive-staging-rke2.cluster_registration_token[0].node_command} --worker --label node_type=worker --label swh/rpc=true --label swh/loader=true"
  ]
}

output "rancher-node-staging-rke2-worker5_summary" {
  value = module.rancher-node-staging-rke2-worker5.summary
}

# loader nodes must have a 2nd disk on hypervisor local storage to avoid
# unnecessary ceph traffic on ceph
module "rancher-node-staging-rke2-worker6" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "uffizi"
  onboot      = true

  template    = var.templates["stable-zfs"]
  hostname    = "rancher-node-staging-rke2-worker6"
  description = "elastic worker for computations (e.g. loader, lister, ...)"
  sockets     = "1"
  cores       = "6"
  memory      = "32768"
  balloon     = "16384"

  networks = [{
    id      = 0
    ip      = "192.168.130.146"
    gateway = local.config["gateway_ip"]
    bridge  = local.config["bridge"]
  }]

  storages = [{
    storage = "proxmox"
    size    = "20G"
    }, {
    storage = "scratch"
    size    = "100G"
    }
  ]

  post_provision_steps = [
    "systemctl restart docker",  # workaround
    "${rancher2_cluster_v2.archive-staging-rke2.cluster_registration_token[0].node_command} --worker --label node_type=worker --label swh/rpc=true --label swh/loader=true"
  ]
}

output "rancher-node-staging-rke2-worker6_summary" {
  value = module.rancher-node-staging-rke2-worker6.summary
}
