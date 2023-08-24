resource "rancher2_cluster_v2" "cluster-admin-rke2" {
  name               = "cluster-admin-rke2"
  kubernetes_version = "v1.26.7+rke2r1"
  rke_config {
    upgrade_strategy {
      worker_drain_options {
        enabled               = false
        delete_empty_dir_data = true
        timeout               = 300
      }
    }

    machine_global_config = <<EOF
cni: "calico"
disable:
  - rke2-ingress-nginx
EOF
  }
}

output "rancher2_cluster_cluster_admin_rke2_summary" {
  sensitive = true
  value     = rancher2_cluster_v2.cluster-admin-rke2.kube_config
}

output "rancher2_cluster_cluster_admin_rke2_command" {
  sensitive = true
  value     = rancher2_cluster_v2.cluster-admin-rke2.cluster_registration_token[0].node_command
}

module "rancher-node-admin-rke2-mgmt1" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "hypervisor3"
  onboot      = true
  vmid        = 175

  template    = var.templates["stable-zfs"]
  hostname    = "rancher-node-admin-rke2-mgmt1"
  description = "admin rke2 management node"
  sockets     = "1"
  cores       = "4"
  memory      = "12288"
  balloon     = "12288"

  networks = [{
    id      = 0
    ip      = "192.168.50.140"
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
    "mkdir -p etc/rancher/rke2/config.yaml.d",
    "echo '{ \"snapshotter\": \"native\" }' >/etc/rancher/rke2/config.yaml.d/50-snaphotter.yaml",
    "${rancher2_cluster_v2.cluster-admin-rke2.cluster_registration_token[0].node_command} --etcd --controlplane"
  ]
}

output "rancher-node-admin-rke2-mgmt1_summary" {
  value = module.rancher-node-admin-rke2-mgmt1.summary
}


module "rancher-node-admin-rke2-node01" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "hypervisor3"
  onboot      = true
  vmid        = 176


  template    = var.templates["stable-zfs"]
  hostname    = "rancher-node-admin-rke2-node01"
  description = "Admin cluster node01"
  sockets     = "1"
  cores       = "4"
  memory      = "16384"
  balloon     = "16384"

  networks = [{
    id      = 0
    ip      = "192.168.50.141"
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
    "mkdir -p etc/rancher/rke2/config.yaml.d",
    "echo '{ \"snapshotter\": \"native\" }' >/etc/rancher/rke2/config.yaml.d/50-snaphotter.yaml",
    "${rancher2_cluster_v2.cluster-admin-rke2.cluster_registration_token[0].node_command} --worker"
  ]
}

output "rancher-node-admin-rke2-node01_summary" {
  value = module.rancher-node-admin-rke2-node01.summary
}

module "rancher-node-admin-rke2-node02" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "branly"
  onboot      = true
  vmid        = 177


  template    = var.templates["stable-zfs"]
  hostname    = "rancher-node-admin-rke2-node02"
  description = "Admin cluster node02"
  sockets     = "1"
  cores       = "4"
  memory      = "16384"
  balloon     = "16384"

  networks = [{
    id      = 0
    ip      = "192.168.50.142"
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
    "mkdir -p etc/rancher/rke2/config.yaml.d",
    "echo '{ \"snapshotter\": \"native\" }' >/etc/rancher/rke2/config.yaml.d/50-snaphotter.yaml",
    "${rancher2_cluster_v2.cluster-admin-rke2.cluster_registration_token[0].node_command} --worker"
  ]
}

output "rancher-node-admin-rke2-node03_summary" {
  value = module.rancher-node-admin-rke2-node03.summary
}

module "rancher-node-admin-rke2-node03" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "mucem"
  onboot      = true
  vmid        = 178


  template    = var.templates["stable-zfs"]
  hostname    = "rancher-node-admin-rke2-node03"
  description = "Admin cluster node03"
  sockets     = "1"
  cores       = "4"
  memory      = "16384"
  balloon     = "16384"

  networks = [{
    id      = 0
    ip      = "192.168.50.143"
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
    "mkdir -p etc/rancher/rke2/config.yaml.d",
    "echo '{ \"snapshotter\": \"native\" }' >/etc/rancher/rke2/config.yaml.d/50-snaphotter.yaml",
    "${rancher2_cluster_v2.cluster-admin-rke2.cluster_registration_token[0].node_command} --worker"
  ]
}

output "rancher-node-admin-rke2-node02_summary" {
  value = module.rancher-node-admin-rke2-node02.summary
}

resource "rancher2_app_v2" "cluster-admin-rke2-rancher-monitoring" {
  cluster_id    = rancher2_cluster_v2.cluster-admin-rke2.cluster_v1_id
  name          = "rancher-monitoring"
  namespace     = "cattle-monitoring-system"
  repo_name     = "rancher-charts"
  chart_name    = "rancher-monitoring"
  chart_version = "102.0.1+up40.1.2"
  values        = <<EOF
alertmanager:
  alertmanagerSpec:
    logLevel: debug
global:
  cattle:
    clusterId: c-m-682nvssh
    clusterName: cluster-admin-rke2
    systemDefaultRegistry: ""
  systemDefaultRegistry: ""
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
      cluster: ${rancher2_cluster_v2.cluster-admin-rke2.name}
      domain: admin
      environment: admin
      infrastructure: kubernetes
    resources:
      requests:
        memory: 1500Mi
    thanos:
      objectStorageConfig:
        key: thanos.yaml
        name: thanos-objstore-config-secret
  thanosIngress:
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-production
      metallb.universe.tf/allow-shared-ip: clusterIP
      nginx.ingress.kubernetes.io/backend-protocol: GRPC
    enabled: true
    hosts:
    - k8s-admin-rke2-thanos.internal.admin.swh.network
    loadBalancerIP: 192.168.50.139
    pathType: Prefix
    tls:
    - hosts:
      - k8s-admin-rke2-thanos.internal.staging.swh.network
      secretName: thanos-crt
prometheusOperator:
  logLevel: debug
EOF
}

