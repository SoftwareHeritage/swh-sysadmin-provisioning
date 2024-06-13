resource "rancher2_cluster_v2" "test-staging-rke2" {
  name               = "test-staging-rke2"
  kubernetes_version = "v1.28.10+rke2r1"
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

  etcd_snapshot_create {
                generation = 3
              }

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

    registries {
      dynamic "mirrors" {
        for_each = var.docker_registry_mirrors
        content {
          hostname  = mirrors.value.hostname
          endpoints = [format("https://%s/%s/v2", var.docker_registry_mirror_hostname, mirrors.value.prefix)]
        }
      }
    }

    # to disable when the cluster will be managed
    # by argocd as the other ones
    # disable:
    #   - rke2-ingress-nginx

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
  cluster_id    = rancher2_cluster_v2.test-staging-rke2.cluster_v1_id
  state_confirm = 2
  timeouts {
    create = "45m"
  }
}

module "rancher-node-test-rke2-mgmt1" {
  source     = "../modules/node"
  config     = local.config
  hypervisor = "uffizi"
  onboot     = false
  vmid       = 143

  template    = var.templates["bullseye-zfs"]
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
    storage = "scratch"
    size    = "20G"
    }
  ]

  post_provision_steps = [
    "systemctl restart docker", # workaround
    "mkdir -p /etc/rancher/rke2/config.yaml.d",
    "echo '{ \"snapshotter\": \"zfs\" }' >/etc/rancher/rke2/config.yaml.d/50-snapshotter.yaml",
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
  chart_version = "103.1.0+up45.31.1"
  values        = <<EOF
alertmanager:
  alertmanagerSpec:
    alertmanagerConfigMatcherStrategy:
      type: None
    configSecret: alertmanager-rancher-monitoring-alertmanager
    useExistingSecret: true
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
    resources:
      limits:
        cpu: 2000m
        memory: 5000Mi
      requests:
        cpu: 750m
        memory: 3500Mi
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
  depends_on = [rancher2_cluster_sync.test-staging-rke2,
    rancher2_cluster_v2.test-staging-rke2,
    module.rancher-node-test-rke2-mgmt1,
    module.rancher-node-test-rke2-worker1,
  module.rancher-node-test-rke2-worker2]
}

# Dedicated node for rpc services (e.g. graphql, ...)
module "rancher-node-test-rke2-worker1" {
  source     = "../modules/node"
  config     = local.config
  hypervisor = "uffizi"
  onboot     = false
  vmid       = 146

  template    = var.templates["bullseye-zfs"]
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
    "systemctl restart docker", # workaround
    "mkdir -p /etc/rancher/rke2/config.yaml.d",
    "echo '{ \"snapshotter\": \"zfs\" }' >/etc/rancher/rke2/config.yaml.d/50-snapshotter.yaml",
    "${rancher2_cluster_v2.test-staging-rke2.cluster_registration_token[0].node_command} --worker --label node_type=generic --label --label swh/lister=true --label swh/loader=true --label swh/rpc=true --label swh/toolbox=true --label swh/webhooks=true"
  ]
}

output "rancher-node-test-rke2-worker1_summary" {
  value = module.rancher-node-test-rke2-worker1.summary
}

# loader nodes must have a 2nd disk on hypervisor local storage to avoid
# unnecessary ceph traffic on ceph
module "rancher-node-test-rke2-worker2" {
  source     = "../modules/node"
  config     = local.config
  hypervisor = "uffizi"
  onboot     = false
  vmid       = 147

  template    = var.templates["bullseye-zfs"]
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
    "systemctl restart docker", # workaround
    "mkdir -p /etc/rancher/rke2/config.yaml.d",
    "echo '{ \"snapshotter\": \"zfs\" }' >/etc/rancher/rke2/config.yaml.d/50-snapshotter.yaml",
    "${rancher2_cluster_v2.test-staging-rke2.cluster_registration_token[0].node_command} --worker --label node_type=worker --label swh/lister=true --label swh/loader=true --label swh/rpc=true --label swh/toolbox=true --label swh/webhooks=true --label swh/storage=true"
  ]
}

output "rancher-node-test-rke2-worker2_summary" {
  value = module.rancher-node-test-rke2-worker2.summary
}

# loader nodes must have a 2nd disk on hypervisor local storage to avoid
# unnecessary ceph traffic on ceph
module "rancher-node-test-rke2-worker3" {
  source     = "../modules/node"
  config     = local.config
  hypervisor = "uffizi"
  onboot     = false
  #vmid       = 154 # specifying the vmid tells terraform to recreate the worker

  template    = var.templates["bullseye-zfs"]
  hostname    = "rancher-node-test-rke2-worker3"
  description = "elastic worker for computations (e.g. loader, lister, ...)"
  sockets     = "1"
  cores       = "6"
  memory      = "32768"
  balloon     = "16384"

  networks = [{
    id      = 0
    ip      = "192.168.130.213"
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
    "systemctl restart docker", # workaround
    "mkdir -p /etc/rancher/rke2/config.yaml.d",
    "echo '{ \"snapshotter\": \"zfs\" }' >/etc/rancher/rke2/config.yaml.d/50-snapshotter.yaml",
    "${rancher2_cluster_v2.test-staging-rke2.cluster_registration_token[0].node_command} --worker --label node_type=worker --label swh/lister=true --label swh/loader=true --label swh/rpc=true --label swh/toolbox=true --label swh/webhooks=true"
  ]
}

output "rancher-node-test-rke2-worker3_summary" {
  value = module.rancher-node-test-rke2-worker3.summary
}
