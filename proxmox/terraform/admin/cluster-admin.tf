resource "rancher2_cluster" "cluster-admin" {
  name        = "cluster-admin"
  description = "cluster for admin tools (argocd, minio, ...)"

  rke_config {
    kubernetes_version = "v1.22.13-rancher1-1"
    network {
      plugin = "canal"
    }
    ingress {
      provider = "none"
    }
 }
}

output "cluster-admin-config-summary" {
  sensitive = true
  value     = rancher2_cluster.cluster-admin.kube_config
}

output "cluster-admin-register-command" {
  sensitive = true
  value     = rancher2_cluster.cluster-admin.cluster_registration_token[0].node_command
}

module "rancher-node-admin-mgmt1" {
  hostname = "rancher-node-admin-mgmt1"
  vmid     = 171

  source      = "../modules/node"
  template    = var.templates["stable-zfs"]
  config      = local.config
  description = "Admin cluster node with etcd, controlplane and worker roles"
  hypervisor  = "hypervisor3"
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory      = "12288"
  balloon     = "8192"

  networks = [{
    id      = 0
    ip      = "192.168.50.45"
    gateway = local.config["gateway_ip"]
    bridge  = local.config["vlan"]
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
    "systemctl restart docker", # workaround
    "${rancher2_cluster.cluster-admin.cluster_registration_token[0].node_command} --etcd --controlplane"
  ]
}

output "rancher-node-admin-mgmt1_summary" {
  value = module.rancher-node-admin-mgmt1.summary
}

module "rancher-node-admin-node01" {
  hostname = "rancher-node-admin-node01"
  vmid     = 172

  source      = "../modules/node"
  template    = var.templates["stable-zfs"]
  config      = local.config
  description = "Admin cluster node01"
  hypervisor  = "hypervisor3"
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory      = "16384"
  balloon     = "8192"

  networks = [{
    id      = 0
    ip      = "192.168.50.46"
    gateway = local.config["gateway_ip"]
    bridge  = local.config["vlan"]
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
    "systemctl restart docker", # workaround
    "${rancher2_cluster.cluster-admin.cluster_registration_token[0].node_command} --worker"
  ]
}

output "rancher-node-admin-node01_summary" {
  value = module.rancher-node-admin-node01.summary
}

module "rancher-node-admin-node02" {
  hostname = "rancher-node-admin-node02"
  vmid     = 173

  source      = "../modules/node"
  template    = var.templates["stable-zfs"]
  config      = local.config
  description = "Admin cluster node02"
  hypervisor  = "branly"
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory      = "16384"
  balloon     = "8192"

  networks = [{
    id      = 0
    ip      = "192.168.50.47"
    gateway = local.config["gateway_ip"]
    bridge  = local.config["vlan"]
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
    "systemctl restart docker", # workaround
    "${rancher2_cluster.cluster-admin.cluster_registration_token[0].node_command} --worker"
  ]
}

output "rancher-node-admin-node02_summary" {
  value = module.rancher-node-admin-node02.summary
}

module "rancher-node-admin-node03" {
  hostname = "rancher-node-admin-node03"
  vmid     = 174

  source      = "../modules/node"
  template    = var.templates["stable-zfs"]
  config      = local.config
  description = "Admin cluster node03"
  hypervisor  = "pompidou"
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory      = "16384"
  balloon     = "8192"

  networks = [{
    id      = 0
    ip      = "192.168.50.48"
    gateway = local.config["gateway_ip"]
    bridge  = local.config["vlan"]
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
    "systemctl restart docker", # workaround
    "${rancher2_cluster.cluster-admin.cluster_registration_token[0].node_command} --worker"
  ]
}

output "rancher-node-admin-node03_summary" {
  value = module.rancher-node-admin-node03.summary
}

resource "rancher2_app_v2" "cluster-admin-rancher-monitoring" {
  cluster_id = rancher2_cluster.cluster-admin.id
  name = "rancher-monitoring"
  namespace = "cattle-monitoring-system"
  repo_name = "rancher-charts"
  chart_name = "rancher-monitoring"
  chart_version = "100.1.3+up19.0.3"
  values = <<EOF
prometheus:
  enabled: true
  prometheusSpec:
    requests:
      cpu: 250m
      memory: 250Mi
      retention: 15d # Temporary until the sync to azure is in place
    # mark metrics with discriminative information, check official doc for details
    # see https://thanos.io/tip/thanos/quick-tutorial.md/#external-labels
    externalLabels:
      environment: admin
      infrastructure: kubernetes
      domain: admin
      cluster_name: ${rancher2_cluster.cluster-admin.name}
    thanos:
      # thanos-objstore-config-secret is installed in namespace cattle-monitoring-system
      # see k8s-private-data:admin/thanos-objstore-config-secret.yaml. And
      # https://prometheus-operator.dev/docs/operator/thanos/#configuring-thanos-object-storage
      objectStorageConfig:
        key: thanos.yaml
        name: thanos-objstore-config-secret
  # thanos sidecar
  thanosService:
    enabled: false
  thanosIngress:
    enabled: true
    hosts: ["k8s-admin-thanos.internal.softwareheritage.org"]
    loadBalancerIP: 192.168.50.44
    pathType: Prefix
    annotations:
      metallb.universe.tf/allow-shared-ip: clusterIP
      nginx.ingress.kubernetes.io/backend-protocol: GRPC
  thanosServiceMonitor:
    enabled: false
  thanosServiceExternal:
    enabled: false
    loadBalancerIP: 192.168.50.44
    annotations:
      metallb.universe.tf/allow-shared-ip: clusterIP
EOF
}
