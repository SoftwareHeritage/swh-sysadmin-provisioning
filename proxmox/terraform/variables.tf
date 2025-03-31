variable "domain" {
  description = "DNS zone for the staging area"
  type        = string
  default     = "internal.staging.swh.network"
}

variable "puppet_environment" {
  description = "Puppet environment to use (swh-site's git branch)"
  type        = string
  default     = "staging"
}

variable "puppet_master" {
  description = "Puppet master FQDN"
  type        = string
  default     = "pergamon.internal.softwareheritage.org"
}

variable "dns" {
  description = "DNS server ip"
  type        = string
  default     = "192.168.100.29"
}

variable "gateway_ip" {
  description = "Staging network gateway ip"
  type        = string
  default     = "192.168.130.1"
}

variable "user_admin" {
  description = "User admin to use for managing the node"
  type        = string
  default     = "root"
}

# public key part to install through cloud-init so ssh connection is possible
# `pass search terraform-proxmox` in credential store
variable "user_admin_ssh_public_key" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDVKCfpeIMg7GS3Pk03ZAcBWAeDZ+AvWk2k/pPY0z8MJ3YAbqZkRtSK7yaDgJV6Gro7nn/TxdJLo2jEzzWvlC8d8AEzhZPy5Z/qfVVjqBTBM4H5+e+TItAHFfaY5+0WvIahxcfsfaq70MWfpJhszAah3ThJ4mqzYaw+dkr42+a7Gx3Ygpb/m2dpnFnxvXdcuAJYStmHKU5AWGWWM+Fm50/fdMqUfNd8MbKhkJt5ihXQmZWMOt7ls4N8i5NZWnS9YSWow8X/ENOEqCRN9TyRkc+pPS0w9DNi0BCsWvSRJOkyvQ6caEnKWlNoywCmM1AlIQD3k4RUgRWe0vqg/UKPpH3Z root@terraform"
}

# private key path so the provisioning step can leverage the ssh connection
# `pass search terraform-proxmox` in credential store and install the key locally
variable "user_admin_ssh_private_key_path" {
  type    = string
  default = "~/.ssh/id-rsa-terraform-proxmox-root"
}

# Hashmap of debian release to our associated vm templates
# This should be maintained up-to-date with most recent built templates
variable "templates" {
  description = "Debian image templates created by packer"
  type = map(string)
  default = {
    buster       = "debian-buster-10.10-2021-09-09"
    bullseye     = "debian-bullseye-11.7-2023-08-29"
    bullseye-zfs = "debian-bullseye-11.7-zfs-2023-08-29"
    bookworm     = "debian-bookworm-12.10-2025-03-31"
    bookworm-zfs = "debian-bookworm-12.10-zfs-2025-03-31"
  }
}

variable "docker_registry_mirror_hostname" {
  description = "Host for the docker registry mirror"
  type        = string
  default     = "docker-cache.internal.admin.swh.network"
}

variable "docker_registry_mirrors" {
  description = "Docker image registry mirrors"
  type        = list(object({ hostname = string, prefix = string }))
  default = [{
    hostname = "container-registry.softwareheritage.org"
    prefix   = "swh"
    }, {
    hostname = "docker.io"
    prefix   = "docker.io"
    }, {
    hostname = "ghcr.io"
    prefix   = "ghcr.io"
    }, {
    hostname = "quay.io"
    prefix   = "quay.io"
    }, {
    hostname = "registry.k8s.io"
    prefix   = "registry.k8s.io"
  }]
}
