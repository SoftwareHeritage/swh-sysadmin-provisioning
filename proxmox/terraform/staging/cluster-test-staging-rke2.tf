resource "rancher2_cluster_v2" "test-staging-rke2" {
  name               = "test-staging-rke2"
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
  - --max-pods=120
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

    # to disable when the cluster will be managed
    # by argocd as the other ones
    # disable:
    #   - rke2-ingress-nginx

  }

  local_auth_endpoint {
      enabled  = true
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
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "branly"
  onboot      = false
  vmid        = 143
  hostname    = "rancher-node-test-rke2-mgmt1"
  description = "test rke2 management node"
  tags        = ["test-staging-rke2"]

  ram = {
    dedicated = 16384
    floating  = 16384
  }

  network = {
    ip          = "192.168.130.210"
    mac_address = "92:CF:4E:83:30:8A"
  }

  disks = [
    {
      interface = "virtio0"
      size      = 20
    },
    {
      datastore_id = "scratch"
      interface    = "virtio1"
      size         = 20
    }
  ]

  post_provision_steps = [
    "${rancher2_cluster_v2.test-staging-rke2.cluster_registration_token[0].node_command} --etcd --controlplane"
  ]
}

output "rancher-node-test-rke2-mgmt1_summary" {
  value = module.rancher-node-test-rke2-mgmt1.summary
}

module "rancher-node-test-rke2-mgmt2" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "uffizi"
  onboot      = false
  vmid        = 159
  hostname    = "rancher-node-test-rke2-mgmt2"
  description = "test rke2 management node"
  tags        = ["test-staging-rke2"]

  ram = {
    dedicated = 16384
    floating  = 16384
  }

  network = {
    ip          = "192.168.130.214"
    mac_address = "96:BF:F3:92:04:86"
  }

  disks = [
    {
      interface = "virtio0"
      size      = 20
    },
    {
      datastore_id = "scratch"
      interface    = "virtio1"
      size         = 20
    }
  ]

  post_provision_steps = [
    "${rancher2_cluster_v2.test-staging-rke2.cluster_registration_token[0].node_command} --etcd --controlplane"
  ]
}

output "rancher-node-test-rke2-mgmt2_summary" {
  value = module.rancher-node-test-rke2-mgmt2.summary
}

module "rancher-node-test-rke2-mgmt3" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "mucem"
  onboot      = false
  vmid        = 160
  hostname    = "rancher-node-test-rke2-mgmt3"
  description = "test rke2 management node"
  tags        = ["test-staging-rke2"]

  ram = {
    dedicated = 16384
    floating  = 16384
  }

  network = {
    ip          = "192.168.130.215"
    mac_address = "BE:64:6B:73:D3:CC"
  }

  disks = [
    {
      size      = 20
      interface = "virtio0"
    },
    {
      datastore_id = "scratch"
      interface    = "virtio1"
      size         = 20
    }
  ]

  post_provision_steps = [
    "${rancher2_cluster_v2.test-staging-rke2.cluster_registration_token[0].node_command} --etcd --controlplane"
  ]
}

output "rancher-node-test-rke2-mgmt3_summary" {
  value = module.rancher-node-test-rke2-mgmt3.summary
}

# Disabled, it should be created and maintained by argocd
resource "rancher2_app_v2" "test-staging-rke2-rancher-monitoring" {
  cluster_id    = rancher2_cluster_v2.test-staging-rke2.cluster_v1_id
  name          = "rancher-monitoring"
  namespace     = "cattle-monitoring-system"
  repo_name     = "rancher-charts"
  chart_name    = "rancher-monitoring"
  chart_version = "103.2.0+up57.0.3"
  values        = <<EOF
global:
  cattle:
    clusterId: ${rancher2_cluster_v2.test-staging-rke2.cluster_v1_id}
    clusterName: ${rancher2_cluster_v2.test-staging-rke2.name}
    rkePathPrefix: ""
    rkeWindowsPathPrefix: ""
    systemDefaultRegistry: ""
    systemProjectId: p-h4vvn
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
  depends_on = [
    rancher2_cluster_sync.test-staging-rke2,
    rancher2_cluster_v2.test-staging-rke2,
    module.rancher-node-test-rke2-mgmt1,
    module.rancher-node-test-rke2-worker1,
  ]
}

# Dedicated node for rpc services (e.g. graphql, ...)
module "rancher-node-test-rke2-worker1" {
  source       = "../modules/node_bpg"
  config       = local.config
  hypervisor   = "uffizi"
  onboot       = false
  vmid         = 146
  hostname    = "rancher-node-test-rke2-worker1"
  description = "elastic worker for rpc services (e.g. graphql, ...)"
  tags        = ["test-staging-rke2"]

  cpu = {
    type  = "host"
    cores = 6
  }

  ram = {
    dedicated = 32768
    floating  = 16384
  }

  network = {
    ip          = "192.168.130.211"
    mac_address = "92:30:9E:96:99:6B"
  }

  disks = [
    {
      interface = "virtio0"
      size      = 20
    },
    {
      datastore_id = "scratch"
      interface    = "virtio1"
      size         = 100
    }
  ]

  post_provision_steps = [
    "${rancher2_cluster_v2.test-staging-rke2.cluster_registration_token[0].node_command} --worker --label node_type=worker --label swh/lister=true --label swh/loader=true --label swh/rpc=true --label swh/toolbox=true --label swh/webhooks=true"
  ]
}

output "rancher-node-test-rke2-worker1_summary" {
  value = module.rancher-node-test-rke2-worker1.summary
}

# loader nodes must have a 2nd disk on hypervisor local storage to avoid
# unnecessary ceph traffic on ceph
module "rancher-node-test-rke2-worker2" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "uffizi"
  onboot      = false
  vmid        = 147
  hostname    = "rancher-node-test-rke2-worker2"
  description = "elastic worker for computations (e.g. loader, lister, ...)"
  tags        = ["test-staging-rke2"]

  cpu = {
    type  = "host"
    cores = 6
  }

  ram = {
    dedicated = 32768
    floating  = 16384
  }

  network = {
    ip          = "192.168.130.212"
    mac_address = "46:BC:4B:E4:81:EA"
  }

  disks = [
    {
      interface = "virtio0"
      size      = 20
    },
    {
      datastore_id = "scratch"
      interface    = "virtio1"
      size         = 100
    }
  ]

  post_provision_steps = [
    "${rancher2_cluster_v2.test-staging-rke2.cluster_registration_token[0].node_command} --worker --label node_type=worker --label swh/lister=true --label swh/loader=true --label swh/rpc=true --label swh/toolbox=true --label swh/webhooks=true --label swh/storage=true"
  ]
}

output "rancher-node-test-rke2-worker2_summary" {
  value = module.rancher-node-test-rke2-worker2.summary
}

# loader nodes must have a 2nd disk on hypervisor local storage to avoid
# unnecessary ceph traffic on ceph
module "rancher-node-test-rke2-worker3" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "uffizi"
  onboot      = false
  vmid        = 154
  hostname    = "rancher-node-test-rke2-worker3"
  description = "elastic worker for computations (e.g. loader, lister, ...)"
  tags        = ["test-staging-rke2"]

  cpu = {
    type  = "host"
    cores = 6
  }

  ram = {
    dedicated = 32768
    floating  = 16384
  }

  network = {
    ip          = "192.168.130.213"
    mac_address = "3E:3A:20:B9:3B:39"
  }

  disks = [
    {
      interface = "virtio0"
      size      = 20
    },
    {
      datastore_id = "scratch"
      interface    = "virtio1"
      size         = 100
    }
  ]

  post_provision_steps = [
    "${rancher2_cluster_v2.test-staging-rke2.cluster_registration_token[0].node_command} --worker --label node_type=worker --label swh/lister=true --label swh/loader=true --label swh/rpc=true --label swh/toolbox=true --label swh/webhooks=true"
  ]
}

output "rancher-node-test-rke2-worker3_summary" {
  value = module.rancher-node-test-rke2-worker3.summary
}
