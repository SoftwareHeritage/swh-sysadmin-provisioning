resource "rancher2_cluster_v2" "archive-production-rke2" {
  name               = "archive-production-rke2"
  kubernetes_version = "v1.32.5+rke2r1"
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
    max: 5
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
  - --allowed-unsafe-sysctls=net.ipv4.tcp_dsack
  - --max-pods=${local.config["max_pods_per_node"]}
disable:
  - rke2-ingress-nginx
EOF

    etcd_snapshot_create {
      generation = 5
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

  timeouts {}

}

output "rancher2_cluster_archive_production_rke2_summary" {
  sensitive = true
  value     = rancher2_cluster_v2.archive-production-rke2.kube_config
}

output "rancher2_cluster_archive_production_rke2_command" {
  sensitive = true
  value     = rancher2_cluster_v2.archive-production-rke2.cluster_registration_token[0].node_command
}

resource "rancher2_cluster_sync" "archive-production-rke2" {
  cluster_id    = rancher2_cluster_v2.archive-production-rke2.cluster_v1_id
  state_confirm = 2
  timeouts {
    create = "45m"
  }
}

module "rancher-node-production-rke2-mgmt1" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "mucem"
  onboot      = true
  vmid        = 126
  hostname    = "rancher-node-production-rke2-mgmt1"
  description = "production rke2 management node"
  tags        = ["archive-production-rke2"]

  ram = {
    dedicated = 8192
    floating  = 8192
  }

  network = {
    ip          = "192.168.100.141"
    mac_address = "EE:45:E8:41:45:31"
  }

  disks = [
    {
      interface = "virtio0"
      size      = 20
    },
    {
      datastore_id = "scratch"
      interface    = "virtio1"
      size         = 30
    }
  ]

  post_provision_steps = [
    "${rancher2_cluster_v2.archive-production-rke2.cluster_registration_token[0].node_command} --etcd --controlplane"
  ]
}

output "rancher-node-production-rke2-mgmt1_summary" {
  value = module.rancher-node-production-rke2-mgmt1.summary
}

module "rancher-node-production-rke2-mgmt2" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "branly"
  onboot      = true
  vmid        = 117
  hostname    = "rancher-node-production-rke2-mgmt2"
  description = "production rke2 management node"
  tags        = ["archive-production-rke2"]

  ram = {
    dedicated = 8192
    floating  = 8192
  }

  network = {
    ip          = "192.168.100.142"
    mac_address = "F2:DC:D5:76:12:4F"
  }

  disks = [
    {
      interface = "virtio0"
      size      = 20
    },
    {
      datastore_id = "scratch"
      interface    = "virtio1"
      size         = 30
    }
  ]

  post_provision_steps = [
    "${rancher2_cluster_v2.archive-production-rke2.cluster_registration_token[0].node_command} --etcd --controlplane"
  ]
}

output "rancher-node-production-rke2-mgmt2_summary" {
  value = module.rancher-node-production-rke2-mgmt2.summary
}

module "rancher-node-production-rke2-mgmt3" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "chaillot"
  onboot      = true
  vmid        = 132
  hostname    = "rancher-node-production-rke2-mgmt3"
  description = "production rke2 management node"
  tags        = ["archive-production-rke2"]

  ram = {
    dedicated = 8192
    floating  = 8192
  }

  network = {
    ip          = "192.168.100.143"
    mac_address = "66:87:EE:C3:6A:BA"
  }

  disks = [
    {
      interface = "virtio0"
      size      = 20
    },
    {
      datastore_id = "scratch"
      interface    = "virtio1"
      size         = 30
    }
  ]

  post_provision_steps = [
    "${rancher2_cluster_v2.archive-production-rke2.cluster_registration_token[0].node_command} --etcd --controlplane"
  ]
}

output "rancher-node-production-rke2-mgmt3_summary" {
  value = module.rancher-node-production-rke2-mgmt3.summary
}

resource "rancher2_app_v2" "archive-production-rke2-rancher-monitoring" {
  cluster_id    = rancher2_cluster_v2.archive-production-rke2.cluster_v1_id
  name          = "rancher-monitoring"
  namespace     = "cattle-monitoring-system"
  repo_name     = "rancher-charts"
  chart_name    = "rancher-monitoring"
  chart_version = "106.1.2+up69.8.2-rancher.7"
  values        = <<EOF
global:
  cattle:
    clusterId: ${rancher2_cluster_v2.archive-production-rke2.cluster_v1_id}
    clusterName: ${rancher2_cluster_v2.archive-production-rke2.name}
    rkePathPrefix: ""
    rkeWindowsPathPrefix: ""
    systemDefaultRegistry: ""
    systemProjectId: p-9x78m
    url: https://rancher.euwest.azure.internal.softwareheritage.org
  systemDefaultRegistry: ""
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
      cluster: ${rancher2_cluster_v2.archive-production-rke2.name}
      domain: production
      environment: production
      infrastructure: kubernetes
    resources:
      limits:
        cpu: 4
        memory: 32Gi
      requests:
        cpu: 2
        memory: 10Gi
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
    - k8s-archive-production-rke2-thanos.internal.softwareheritage.org
    loadBalancerIP: 192.168.100.119
    pathType: Prefix
    tls:
    - hosts:
      - k8s-archive-production-rke2-thanos.internal.softwareheritage.org
      secretName: thanos-crt
  thanosService:
    enabled: true
prometheus-node-exporter:
  prometheus:
    monitor:
      relabelings:
      - action: replace
        regex: ^(.*)$
        replacement: $1.internal.softwareheritage.org
        separator: ;
        sourceLabels:
        - __meta_kubernetes_pod_node_name
        targetLabel: instance
      scrapeTimeout: 30s
  resources:
    limits:
      memory: 100Mi
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
    rancher2_cluster_sync.archive-production-rke2,
    rancher2_cluster_v2.archive-production-rke2,
    module.rancher-node-production-rke2-mgmt1
  ]
}
