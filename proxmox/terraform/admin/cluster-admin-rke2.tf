resource "rancher2_cluster_v2" "cluster-admin-rke2" {
  name               = "cluster-admin-rke2"
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

  timeouts {}

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
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "chaillot"
  onboot      = true
  vmid        = 175
  hostname    = "rancher-node-admin-rke2-mgmt1"
  description = "Admin rke2 management node 1"
  tags        = ["cluster-admin-rke2"]

  ram = {
    dedicated = 16384
    floating  = 16384
  }

  network = {
    ip          = "192.168.50.140"
    mac_address = "76:5B:C2:49:14:9B"
  }

  disks = [{
    interface = "virtio0"
    size      = 20
  },
  {
    datastore_id = "scratch"
    interface    = "virtio1"
    size         = 20
    }]

  post_provision_steps = [
    "${rancher2_cluster_v2.cluster-admin-rke2.cluster_registration_token[0].node_command} --etcd --controlplane"
  ]
}

output "rancher-node-admin-rke2-mgmt1_summary" {
  value = module.rancher-node-admin-rke2-mgmt1.summary
}

module "rancher-node-admin-rke2-mgmt2" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "branly"
  onboot      = true
  vmid        = 153
  hostname    = "rancher-node-admin-rke2-mgmt2"
  description = "Admin rke2 management node 2"
  tags        = ["cluster-admin-rke2"]

  ram = {
    dedicated = 16384
    floating  = 16384
  }

  network = {
    ip          = "192.168.50.152"
    mac_address = "E6:ED:56:24:BB:01"
  }

  disks = [{
    interface = "virtio0"
    size      = 20
  },
  {
    datastore_id = "scratch"
    interface    = "virtio1"
    size         = 20
    }]

  post_provision_steps = [
    "${rancher2_cluster_v2.cluster-admin-rke2.cluster_registration_token[0].node_command} --etcd --controlplane"
  ]
}

output "rancher-node-admin-rke2-mgmt2_summary" {
  value = module.rancher-node-admin-rke2-mgmt2.summary
}

module "rancher-node-admin-rke2-mgmt3" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "mucem"
  onboot      = true
  vmid        = 110
  hostname    = "rancher-node-admin-rke2-mgmt3"
  description = "Admin rke2 management node 3"
  tags        = ["cluster-admin-rke2"]

  ram = {
    dedicated = 16384
    floating  = 16384
  }

  network = {
    ip          = "192.168.50.153"
    mac_address = "82:B2:0C:68:77:A6"
  }

  disks = [{
    interface = "virtio0"
    size      = 20
  },
  {
    datastore_id = "scratch"
    interface    = "virtio1"
    size         = 20
    }]

  post_provision_steps = [
    "${rancher2_cluster_v2.cluster-admin-rke2.cluster_registration_token[0].node_command} --etcd --controlplane"
  ]
}

output "rancher-node-admin-rke2-mgmt3_summary" {
  value = module.rancher-node-admin-rke2-mgmt3.summary
}

module "rancher-node-admin-rke2-node01" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "mucem"
  onboot      = true
  vmid        = 176
  hostname    = "rancher-node-admin-rke2-node01"
  description = "Admin cluster node01"
  tags        = ["cluster-admin-rke2"]

  cpu = {
    type = "x86-64-v3"
  }

  ram = {
    dedicated = 49152
    floating  = 0
  }

  network = {
    ip          = "192.168.50.141"
    mac_address = "E6:BB:B1:0A:E6:C5"
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
    dedicated = 49152
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
    dedicated = 49152
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
  chart_version = "106.1.2+up69.8.2-rancher.7"
  values        = <<EOF
global:
  cattle:
    clusterId: ${rancher2_cluster_v2.cluster-admin-rke2.cluster_v1_id}
    clusterName: ${rancher2_cluster_v2.cluster-admin-rke2.name}
    rkePathPrefix: ""
    rkeWindowsPathPrefix: ""
    systemDefaultRegistry: ""
    systemProjectId: p-kbxrp
    url: https://rancher.euwest.azure.internal.softwareheritage.org
  systemDefaultRegistry: ""
alertmanager:
  alertmanagerSpec:
    alertmanagerConfigMatcherStrategy:
      type: None
    configSecret: alertmanager-rancher-monitoring-alertmanager
    useExistingSecret: true
prometheus:
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
