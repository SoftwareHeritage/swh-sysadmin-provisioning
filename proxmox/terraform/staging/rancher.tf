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
provider "rancher2" {
  api_url    = "https://rancher.euwest.azure.internal.softwareheritage.org/v3"
  # for now
  insecure = true
}

# Plan:
# - create cluster with terraform
# - Create nodes as usual through terraform
# - Retrieve the registration command (out of the cluster creation step) to provide new
#   node

resource "rancher2_cluster" "staging-workers" {
  name = "staging-workers"
  description = "staging workers cluster"
  rke_config {
    network {
      plugin = "canal"
    }
  }
}

output "rancher2_cluster_summary" {
  sensitive = true
  value = rancher2_cluster.staging-workers.kube_config
}

output "rancher2_cluster_command" {
  value = rancher2_cluster.staging-workers.cluster_registration_token[0].node_command
}
