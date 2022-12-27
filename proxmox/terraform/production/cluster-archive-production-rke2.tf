

resource "rancher2_cluster_v2" "archive-production-rke2" {
  name               = "archive-production-rke2"

  kubernetes_version = "v1.24.8+rke2r1"
  rke_config {
    upgrade_strategy {
      worker_drain_options {
        enabled              = true
        delete_empty_dir_data = true
        timeout              = 300
      }
    }
  }
}

output "rancher2_cluster_archive_production_rke2_summary" {
  sensitive = true
  value     = rancher2_cluster_v2.archive-production-rke2.kube_config
}

output "rancher2_cluster_archive_production_rke2_command" {
  sensitive = true
  value     = rancher2_cluster_v2.archive-production-rke2.cluster_registration_token[0].node_command
}

module "rancher-node-production-rke2-mgmt1" {
  source      = "../modules/node"
  template    = var.templates["stable-zfs"]
  config      = local.config
  hostname    = "rancher-node-production-rke2-mgmt1"
  description = "production rke2 management node"
  hypervisor  = "mucem"
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory      = "8192"
  balloon     = "8192"

  networks = [{
    id      = 0
    ip      = "192.168.100.141"
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
    "${rancher2_cluster_v2.archive-production-rke2.cluster_registration_token[0].node_command} --etcd --controlplane"
  ]
}

output "rancher-node-production-rke2-mgmt1_summary" {
  value = module.rancher-node-production-rke2-mgmt1.summary
}

resource "rancher2_app_v2" "archive-production-rke2-rancher-monitoring" {
  cluster_id    = rancher2_cluster_v2.archive-production-rke2.cluster_v1_id
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
      cluster: ${rancher2_cluster_v2.archive-production-rke2.name}
      domain: production
      environment: production
      infrastructure: kubernetes
    requests:
      cpu: 250m
      memory: 250Mi
      retention: 30d
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
    - k8s-archive-production-rke2-thanos.internal.softwareheritage.org
    loadBalancerIP: 192.168.100.119
    pathType: Prefix
    tls:
    - hosts:
      - k8s-archive-production-rke2-thanos.internal.softwareheritage.org
      secretName: thanos-crt
EOF
}
