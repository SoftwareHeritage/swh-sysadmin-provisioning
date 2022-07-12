# Provision the rancher cluster for the cassandra
# nodes in production
#
# Provision 3 vms in proxmox to manage the etcd cluster
# and the kubernetes control plane

provider "rancher2" {
  api_url    = "https://rancher.euwest.azure.internal.softwareheritage.org/v3"
  insecure = true
}

resource "rancher2_cluster" "production_cassandra" {
  name = "production-cassandra"
  description = "Production - Cassandra cluster"
  rke_config {
    kubernetes_version = "v1.22.10-rancher1-1"
    network {
      plugin = "canal"
    }
    services {
      kubelet {
        extra_binds = [
          "/srv/prometheus:/srv/prometheus" # prometheus datastore on mngmt nodes
        ]
      }
    }
  }
}

output "production_cassandra_cluster_summary" {
  sensitive = true
  value     = rancher2_cluster.production_cassandra.kube_config
}

output "production_cassandra_cluster_command" {
  sensitive = true
  value     = rancher2_cluster.production_cassandra.cluster_registration_token[0].node_command
}

module "rancher_node_cassandra1" {
  hostname = "rancher-node-cassandra1"

  source      = "../modules/node"
  template    = "debian-bullseye-11.3-zfs-2022-04-21"
  config      = local.config
  description = "Kubernetes management node for cassandra cluster"
  hypervisor  = "beaubourg"
  vmid        = 159
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory      = "8192"
  balloon     = "4096"

  networks = [{
    id      = 0
    ip      = "192.168.100.178"
    gateway = local.config["gateway_ip"]
    macaddr = ""
    bridge  = "vmbr0"
  }]

  storages = [{
    storage = "proxmox"
    size    = "20G"
    }, {
    storage = "proxmox"
    size    = "50G"
    }
  ]

  post_provision_steps = [
    "systemctl restart docker", # workaround
    "${rancher2_cluster.production_cassandra.cluster_registration_token[0].node_command} --etcd --controlplane --worker"
  ]
}

output "rancher_node_cassandra1_summary" {
  value = module.rancher_node_cassandra1.summary
}

module "rancher_node_cassandra2" {
  hostname = "rancher-node-cassandra2"

  source      = "../modules/node"
  template    = "debian-bullseye-11.3-zfs-2022-04-21"
  config      = local.config
  description = "Kubernetes management node for cassandra cluster"
  hypervisor  = "branly"
  vmid        = 160
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory      = "8192"
  balloon     = "4096"

  networks = [{
    id      = 0
    ip      = "192.168.100.179"
    gateway = local.config["gateway_ip"]
    macaddr = ""
    bridge  = "vmbr0"
  }]

  storages = [{
    storage = "proxmox"
    size    = "20G"
    }, {
    storage = "proxmox"
    size    = "50G"
    }
  ]

  post_provision_steps = [
    "systemctl restart docker", # workaround
    "${rancher2_cluster.production_cassandra.cluster_registration_token[0].node_command} --etcd --controlplane --worker"
  ]
}

output "rancher_node_cassandra2_summary" {
  value = module.rancher_node_cassandra2.summary
}

module "rancher_node_cassandra3" {
  hostname = "rancher-node-cassandra3"

  source      = "../modules/node"
  template    = "debian-bullseye-11.3-zfs-2022-04-21"
  config      = local.config
  description = "Kubernetes management node for cassandra cluster"
  hypervisor  = "hypervisor3"
  vmid        = 161
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory      = "8192"
  balloon     = "4096"

  networks = [{
    id      = 0
    ip      = "192.168.100.180"
    gateway = local.config["gateway_ip"]
    macaddr = ""
    bridge  = "vmbr0"
 }]

  storages = [{
    storage = "proxmox"
    size    = "20G"
    }, {
    storage = "proxmox"
    size    = "50G"
    }
  ]

  post_provision_steps = [
    "systemctl restart docker", # workaround
    "${rancher2_cluster.production_cassandra.cluster_registration_token[0].node_command} --etcd --controlplane --worker"
  ]
}

output "rancher_node_cassandra3_summary" {
  value = module.rancher_node_cassandra3.summary
}

# Install the cassandra operator
# https://github.com/k8ssandra/cass-operator
resource "rancher2_catalog_v2" "k8ssandra" {
  cluster_id = rancher2_cluster.production_cassandra.id
  name       = "k8ssandra"
  url        = "https://helm.k8ssandra.io/stable"
}

resource "rancher2_app_v2" "cass_operator" {
  cluster_id = rancher2_cluster.production_cassandra.id
  name = "cass-operator"
  namespace = "cass-operator"
  repo_name = "k8ssandra"
  chart_name = "cass-operator"
  chart_version = "0.37.0"
  values = "replicaCount: 2"
}

