resource "rancher2_cluster_v2" "archive-staging-rke2" {
  name               = "archive-staging-rke2"
  kubernetes_version = "v1.28.15+rke2r1"
  rke_config {
    upgrade_strategy {
      worker_drain_options {
        enabled               = false
        delete_empty_dir_data = true
        timeout               = 300
      }
    }

    chart_values = <<-EOT
rke2-calico: {}
rke2-coredns:
  autoscaler:
    max: 2
    coresPerReplica: 64
    preventSinglePointFailure: true
  resources:
    requests:
      cpu: 500m
      memory: 128Mi
    limits:
      cpu: 8 # Unset is not working
EOT

    machine_global_config = <<EOF
cni: "calico"
kubelet-arg:
  - --image-gc-high-threshold=70
  - --image-gc-low-threshold=50
  - --runtime-request-timeout=60m
  - --max-pods=${local.config["max_pods_per_node"]}
disable:
  - rke2-ingress-nginx
EOF

    etcd_snapshot_create {
      generation = 4
    }

    machine_selector_config {
      config = {
        cloud-provider-name = ""
      }
    }

    registries {
      dynamic "mirrors" {
        for_each = var.docker_registry_mirrors
        content {
          hostname  = mirrors.value.hostname
          endpoints = [format("https://%s/%s/v2", var.docker_registry_mirror_hostname, mirrors.value.prefix)]
        }
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

resource "rancher2_cluster_sync" "archive-staging-rke2" {
  cluster_id    = rancher2_cluster_v2.archive-staging-rke2.cluster_v1_id
  state_confirm = 2
  timeouts {
    create = "45m"
  }
}

module "rancher-node-staging-rke2-mgmt1" {
  source     = "../modules/node"
  config     = local.config
  hypervisor = "pompidou"
  onboot     = true

  template    = var.templates["bullseye-zfs"]
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
    storage = "scratch"
    size    = "40G"
    }
  ]

  post_provision_steps = [
    "systemctl restart docker", # workaround
    "${rancher2_cluster_v2.archive-staging-rke2.cluster_registration_token[0].node_command} --etcd --controlplane"
  ]
}

output "rancher-node-staging-rke2-mgmt1_summary" {
  value = module.rancher-node-staging-rke2-mgmt1.summary
}

module "rancher-node-staging-rke2-mgmt2" {
  source     = "../modules/node"
  config     = local.config
  hypervisor = "branly"
  onboot     = true

  template    = var.templates["bullseye-zfs"]
  hostname    = "rancher-node-staging-rke2-mgmt2"
  description = "staging rke2 management node"
  sockets     = "1"
  cores       = "4"
  memory      = "16384"
  balloon     = "16384"

  networks = [{
    id      = 0
    ip      = "192.168.130.162"
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
    "${rancher2_cluster_v2.archive-staging-rke2.cluster_registration_token[0].node_command} --etcd --controlplane"
  ]
}

output "rancher-node-staging-rke2-mgmt2_summary" {
  value = module.rancher-node-staging-rke2-mgmt2.summary
}

module "rancher-node-staging-rke2-mgmt3" {
  source     = "../modules/node"
  config     = local.config
  hypervisor = "mucem"
  onboot     = true

  template    = var.templates["bullseye-zfs"]
  hostname    = "rancher-node-staging-rke2-mgmt3"
  description = "staging rke2 management node"
  sockets     = "1"
  cores       = "4"
  memory      = "16384"
  balloon     = "16384"

  networks = [{
    id      = 0
    ip      = "192.168.130.163"
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
    "${rancher2_cluster_v2.archive-staging-rke2.cluster_registration_token[0].node_command} --etcd --controlplane"
  ]
}

output "rancher-node-staging-rke2-mgmt3_summary" {
  value = module.rancher-node-staging-rke2-mgmt3.summary
}

resource "rancher2_app_v2" "archive-staging-rke2-rancher-monitoring" {
  cluster_id    = rancher2_cluster_v2.archive-staging-rke2.cluster_v1_id
  name          = "rancher-monitoring"
  namespace     = "cattle-monitoring-system"
  repo_name     = "rancher-charts"
  chart_name    = "rancher-monitoring"
  chart_version = "103.2.0+up57.0.3"
  values        = <<EOF
alertmanager:
  alertmanagerSpec:
    alertmanagerConfigMatcherStrategy:
      type: None
    configSecret: alertmanager-rancher-monitoring-alertmanager
    useExistingSecret: true
defaultRules:
  disabled:
    KubeHpaMaxedOut: true
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
    resources:
      limits:
        cpu: 2000m
        memory: 5000Mi
      requests:
        cpu: 750m
        memory: 3500Mi
    retention: 2d
    thanos:
      objectStorageConfig:
        existingSecret:
          key: thanos.yaml
          name: thanos-objstore-config-secret
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
  thanosService:
    enabled: true
prometheus-node-exporter:
  prometheus:
    monitor:
      relabelings:
      - action: replace
        regex: ^(.*)$
        replacement: $1.internal.staging.swh.network
        separator: ;
        sourceLabels:
        - __meta_kubernetes_pod_node_name
        targetLabel: instance
      scrapeTimeout: 30s
rke2ControllerManager:
  enabled: true
rke2Etcd:
  enabled: true
rke2Proxy:
  enabled: true
rke2Scheduler:
  enabled: true
EOF
  depends_on = [
    rancher2_cluster_sync.archive-staging-rke2,
    rancher2_cluster_v2.archive-staging-rke2,
    module.rancher-node-staging-rke2-mgmt1
  ]
}
