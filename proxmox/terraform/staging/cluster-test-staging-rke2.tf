resource "rancher2_cluster_v2" "test-staging-rke2" {
  name               = "test-staging-rke2"
  kubernetes_version = "v1.26.7+rke2r1"
  rke_config {
    upgrade_strategy {
      worker_drain_options {
        enabled               = false
        delete_empty_dir_data = true
        timeout               = 300
      }
    }
  }
}

output "rancher2_cluster_test_staging_rke2_summary" {
  sensitive = true
  value     = rancher2_cluster_v2.test-staging-rke2.kube_config
}

output "rancher2_cluster_test_staging_rke2_command" {
  sensitive = true
  value     = rancher2_cluster_v2.test-staging-rke2.cluster_registration_token[0].node_command
}

resource "rancher2_cluster_sync" "test-staging-rke2" {
  cluster_id =  rancher2_cluster_v2.test-staging-rke2.cluster_v1_id
  state_confirm = 2
  timeouts {
    create = "45m"
  }
}

module "rancher-node-test-rke2-mgmt1" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "uffizi"
  onboot      = false
  vmid        = 143

  template    = var.templates["stable-zfs"]
  hostname    = "rancher-node-test-rke2-mgmt1"
  description = "test rke2 management node"
  sockets     = "1"
  cores       = "4"
  memory      = "16384"
  balloon     = "16384"

  networks = [{
    id      = 0
    ip      = "192.168.130.210"
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
    "mkdir -p /etc/rancher/rke2/config.yaml.d",
    "echo '{ \"snapshotter\": \"native\" }' >/etc/rancher/rke2/config.yaml.d/50-snaphotter.yaml",
    "${rancher2_cluster_v2.test-staging-rke2.cluster_registration_token[0].node_command} --etcd --controlplane"
  ]
}

output "rancher-node-test-rke2-mgmt1_summary" {
  value = module.rancher-node-test-rke2-mgmt1.summary
}

# Disabled, it should be created and maintained by argocd
resource "rancher2_app_v2" "test-staging-rke2-rancher-monitoring" {
  cluster_id    = rancher2_cluster_v2.test-staging-rke2.cluster_v1_id
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
      cluster: ${rancher2_cluster_v2.test-staging-rke2.name}
      domain: staging
      environment: test
      infrastructure: kubernetes
    requests:
      cpu: 250m
      memory: 250Mi
    # thanos:
    #   objectStorageConfig:
    #     key: thanos.yaml
    #     name: thanos-objstore-config-secret
    resources:
      limits:
        memory: 5000Mi
        cpu: 2000m
      requests:
        memory: 3500Mi
        cpu: 750m
#   thanosIngress:
#     annotations:
#       cert-manager.io/cluster-issuer: letsencrypt-production-gandi
#       metallb.universe.tf/allow-shared-ip: clusterIP
#       nginx.ingress.kubernetes.io/backend-protocol: GRPC
#     enabled: true
#     hosts:
#     - k8s-test-staging-rke2-thanos.internal.staging.swh.network
#     loadBalancerIP: 192.168.130.129
#     pathType: Prefix
#     tls:
#     - hosts:
#       - k8s-test-staging-rke2-thanos.internal.staging.swh.network
#       secretName: thanos-crt
EOF
depends_on = [rancher2_cluster_sync.test-staging-rke2,
              rancher2_cluster_v2.test-staging-rke2,
              module.rancher-node-test-rke2-mgmt1,
              module.rancher-node-test-rke2-worker1,
              module.rancher-node-test-rke2-worker2]
}

# Dedicated node for rpc services (e.g. graphql, ...)
module "rancher-node-test-rke2-worker1" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "uffizi"
  onboot      = false
  vmid        = 146

  template    = var.templates["stable-zfs"]
  hostname    = "rancher-node-test-rke2-worker1"
  description = "elastic worker for rpc services (e.g. graphql, ...)"
  sockets     = "1"
  cores       = "6"
  memory      = "32768"
  balloon     = "16384"

  networks = [{
    id      = 0
    ip      = "192.168.130.211"
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
    "mkdir -p /etc/rancher/rke2/config.yaml.d",
    "echo '{ \"snapshotter\": \"native\" }' >/etc/rancher/rke2/config.yaml.d/50-snaphotter.yaml",
    "${rancher2_cluster_v2.test-staging-rke2.cluster_registration_token[0].node_command} --worker --label node_type=generic --label swh/rpc=true"
  ]
}

output "rancher-node-test-rke2-worker1_summary" {
  value = module.rancher-node-test-rke2-worker1.summary
}

# loader nodes must have a 2nd disk on hypervisor local storage to avoid
# unnecessary ceph traffic on ceph
module "rancher-node-test-rke2-worker2" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "uffizi"
  onboot      = false
  vmid        = 147

  template    = var.templates["stable-zfs"]
  hostname    = "rancher-node-test-rke2-worker2"
  description = "elastic worker for computations (e.g. loader, lister, ...)"
  sockets     = "1"
  cores       = "6"
  memory      = "32768"
  balloon     = "16384"

  networks = [{
    id      = 0
    ip      = "192.168.130.212"
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
    "mkdir -p /etc/rancher/rke2/config.yaml.d",
    "echo '{ \"snapshotter\": \"native\" }' >/etc/rancher/rke2/config.yaml.d/50-snaphotter.yaml",
    "${rancher2_cluster_v2.test-staging-rke2.cluster_registration_token[0].node_command} --worker --label node_type=worker --label swh/rpc=true --label swh/loader=true --label swh/lister=true"
  ]
}

output "rancher-node-test-rke2-worker2_summary" {
  value = module.rancher-node-test-rke2-worker2.summary
}

