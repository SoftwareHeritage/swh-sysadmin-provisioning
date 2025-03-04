resource "rancher2_cluster_v2" "cluster-admin-rke2" {
  name               = "cluster-admin-rke2"
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
EOT

    machine_global_config = <<EOF
cni: "calico"
kubelet-arg:
  - --image-gc-high-threshold=70
  - --image-gc-low-threshold=50
  - --max-pods=${local.config["max_pods_per_node"]}
disable:
  - rke2-ingress-nginx
EOF

    etcd_snapshot_create {
      generation = 8
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

output "rancher2_cluster_cluster_admin_rke2_summary" {
  sensitive = true
  value     = rancher2_cluster_v2.cluster-admin-rke2.kube_config
}

output "rancher2_cluster_cluster_admin_rke2_command" {
  sensitive = true
  value     = rancher2_cluster_v2.cluster-admin-rke2.cluster_registration_token[0].node_command
}

resource "rancher2_cluster_sync" "cluster-admin-rke2" {
  cluster_id    = rancher2_cluster_v2.cluster-admin-rke2.cluster_v1_id
  state_confirm = 2
  timeouts {
    create = "45m"
  }
}

module "rancher-node-admin-rke2-mgmt1" {
  source     = "../modules/node"
  config     = local.config
  hypervisor = "hypervisor3"
  onboot     = true
  vmid       = 175

  template    = var.templates["bullseye-zfs"]
  hostname    = "rancher-node-admin-rke2-mgmt1"
  description = "admin rke2 management node"
  sockets     = "1"
  cores       = "4"
  memory      = "16384"
  balloon     = "16384"

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
    storage = "scratch"
    size    = "20G"
    }
  ]

  post_provision_steps = [
    "${rancher2_cluster_v2.cluster-admin-rke2.cluster_registration_token[0].node_command} --etcd --controlplane"
  ]
}

output "rancher-node-admin-rke2-mgmt1_summary" {
  value = module.rancher-node-admin-rke2-mgmt1.summary
}

module "rancher-node-admin-rke2-mgmt2" {
  source     = "../modules/node"
  config     = local.config
  hypervisor = "branly"
  onboot     = true

  template    = var.templates["bullseye-zfs"]
  hostname    = "rancher-node-admin-rke2-mgmt2"
  description = "admin rke2 management node"
  sockets     = "1"
  cores       = "4"
  memory      = "16384"
  balloon     = "16384"

  networks = [{
    id      = 0
    ip      = "192.168.50.152"
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
    "${rancher2_cluster_v2.cluster-admin-rke2.cluster_registration_token[0].node_command} --etcd --controlplane"
  ]
}

output "rancher-node-admin-rke2-mgmt2_summary" {
  value = module.rancher-node-admin-rke2-mgmt2.summary
}

module "rancher-node-admin-rke2-mgmt3" {
  source     = "../modules/node"
  config     = local.config
  hypervisor = "mucem"
  onboot     = true

  template    = var.templates["bullseye-zfs"]
  hostname    = "rancher-node-admin-rke2-mgmt3"
  description = "admin rke2 management node"
  sockets     = "1"
  cores       = "4"
  memory      = "16384"
  balloon     = "16384"

  networks = [{
    id      = 0
    ip      = "192.168.50.153"
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
    "${rancher2_cluster_v2.cluster-admin-rke2.cluster_registration_token[0].node_command} --etcd --controlplane"
  ]
}

output "rancher-node-admin-rke2-mgmt3_summary" {
  value = module.rancher-node-admin-rke2-mgmt3.summary
}

module "rancher-node-admin-rke2-node01" {
  source     = "../modules/node"
  config     = local.config
  hypervisor = "hypervisor3"
  onboot     = true
  vmid       = 176


  template    = var.templates["bullseye-zfs"]
  hostname    = "rancher-node-admin-rke2-node01"
  description = "Admin cluster node01"
  sockets     = "1"
  cores       = "4"
  memory      = "32768"

  networks = [{
    id      = 0
    ip      = "192.168.50.141"
    gateway = local.config["gateway_ip"]
    bridge  = local.config["bridge"]
  }]

  storages = [{
    storage = "proxmox"
    size    = "40G"
    }, {
    storage = "scratch"
    size    = "40G"
    }
  ]

  post_provision_steps = [
    "mkdir -p etc/rancher/rke2/config.yaml.d",
    "echo '{ \"snapshotter\": \"native\" }' >/etc/rancher/rke2/config.yaml.d/50-snapshotter.yaml",
    "${rancher2_cluster_v2.cluster-admin-rke2.cluster_registration_token[0].node_command} --worker"
  ]
}

output "rancher-node-admin-rke2-node01_summary" {
  value = module.rancher-node-admin-rke2-node01.summary
}

module "rancher-node-admin-rke2-node02" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "branly"
  onboot      = true
  vmid        = 177
  hostname    = "rancher-node-admin-rke2-node02"
  description = "Admin cluster node02"
  tags        = ["cluster-admin-rke2"]

  cpu = {
    type = "x86-64-v3"
  }

  ram = {
    dedicated = 32768
    floating  = 0
  }

  network = {
    ip          = "192.168.50.142"
    mac_address = "86:D2:59:92:61:3A"
  }

  disks = [{
    interface = "virtio0"
    size      = 40
  },
  {
    datastore_id = "scratch"
    interface    = "virtio1"
    size         = 40
    }]

  post_provision_steps = [
    "${rancher2_cluster_v2.cluster-admin-rke2.cluster_registration_token[0].node_command} --worker"
  ]
}

output "rancher-node-admin-rke2-node02_summary" {
  value = module.rancher-node-admin-rke2-node02.summary
}

module "rancher-node-admin-rke2-node03" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "mucem"
  onboot      = true
  vmid        = 178
  hostname    = "rancher-node-admin-rke2-node03"
  description = "Admin cluster node03"
  tags        = ["cluster-admin-rke2"]

  cpu = {
    type = "x86-64-v3"
  }

  ram = {
    dedicated = 32768
    floating  = 0
  }

  network = {
    ip          = "192.168.50.143"
    mac_address = "1A:B9:ED:59:2F:B4"
  }

  disks = [{
    interface = "virtio0"
    size      = 40
  },
  {
    datastore_id = "scratch"
    interface    = "virtio1"
    size         = 40
    }]

  post_provision_steps = [
    "${rancher2_cluster_v2.cluster-admin-rke2.cluster_registration_token[0].node_command} --worker"
  ]
}

output "rancher-node-admin-rke2-node03_summary" {
  value = module.rancher-node-admin-rke2-node03.summary
}

resource "rancher2_app_v2" "cluster-admin-rke2-rancher-monitoring" {
  cluster_id    = rancher2_cluster_v2.cluster-admin-rke2.cluster_v1_id
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
prometheus:
  enabled: true
  prometheusSpec:
    externalLabels:
      cluster: ${rancher2_cluster_v2.cluster-admin-rke2.name}
      domain: admin
      environment: admin
      infrastructure: kubernetes
    resources:
      limits:
        cpu: 2000m
        memory: 3500Mi
      requests:
        cpu: 750m
        memory: 200Mi
    thanos:
      objectStorageConfig:
        existingSecret:
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
      - k8s-admin-rke2-thanos.internal.admin.swh.network
      secretName: thanos-crt
  thanosService:
    enabled: true
prometheus-node-exporter:
  prometheus:
    monitor:
      relabelings:
      - action: replace
        regex: ^(.*)$
        replacement: $1.internal.admin.swh.network
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
  depends_on = [rancher2_cluster_sync.cluster-admin-rke2,
    rancher2_cluster_v2.cluster-admin-rke2,
    module.rancher-node-admin-rke2-mgmt1,
  module.rancher-node-admin-rke2-node01]
}
