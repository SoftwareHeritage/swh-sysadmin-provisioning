# This declares terraform manifests to provision vms and register containers within
# those to a rancher (clusters management service) instance.

# Each software has the following responsibilities:
# - proxmox: provision vms (with docker dependency)
# - rancher: installs kube cluster within containers (running on vms)

# Requires (RANCHER_ACCESS_KEY and RANCHER_SECRET_KEY) in your shell environment
# $ cat ~/.config/terraform/swh/setup.sh
# ...
# key_entry=operations/rancher/azure/elastic-loader-lister-keys
# export RANCHER_ACCESS_KEY=$(swhpass ls $key_entry | head -1 | cut -d: -f1)
# export RANCHER_SECRET_KEY=$(swhpass ls $key_entry | head -1 | cut -d: -f2)

# Plan:
# - create cluster with terraform
# - Create nodes as usual through terraform
# - Retrieve the registration command (out of the cluster creation step) to provide new
#   node

resource "rancher2_cluster" "cluster-graphql" {
  name = "cluster-graphql"
  description = "graphql staging cluster"
  rke_config {
    network {
      plugin = "canal"
    }
  }
}

output "cluster-graphql-config-summary" {
  sensitive = true
  value = rancher2_cluster.cluster-graphql.kube_config
}

output "cluster-graphql-register-command" {
  sensitive = true
  value = rancher2_cluster.cluster-graphql.cluster_registration_token[0].node_command
}
