variable "hostname" {
    description = "Node's hostname"
    type        = "string"
}

variable "description" {
    description = "Node's description"
    type        = "string"
}

variable "hypervisor" {
    description = "Hypervisor to install the vm to (choice: orsay, hypervisor3, beaubourg)"
    type        = "string"
    default     = "orsay"
}

variable "template" {
    description = "Template to use (template-debian-9, template-debian-10)"
    type        = "string"
    default     = "template-debian-9"
}

variable "sockets" {
    description = "Number of sockets"
    type        = "string"
    default     = "1"
}

variable "cores" {
    description = "Number of cores"
    type        = "string"
    default     = "1"
}

variable "memory" {
    description = "Memory in Mb"
    type        = "string"
    default     = "1024"
}

variable "network" {
    description = "staging network's ip/macaddr"
    type        = "map"
}

variable "storage" {
    description = "Storage disk location and size in the hypervisor storage"
    type = "map"
     default = {
         location = "orsay-ssd-2018"
         size     = "32G"
     }
}

#### Below, variables are duplicated (/me is sad, don't know how to avoid it
#### for now)

variable "domain" {
    description = "DNS zone for the staging area"
    type        = "string"
    default     = "internal.staging.swh.network"
}

variable "puppet_environment" {
    description = "Puppet environment to use (swh-site's git branch)"
    type        = "string"
    default     = "new_staging"
}

variable "puppet_master" {
    description = "Puppet master FQDN"
    type        = "string"
    default     = "pergamon.internal.softwareheritage.org"
}

variable "dns" {
    description = "DNS server ip"
    type        = "string"
    default     = "192.168.100.29"
}

variable "gateway_ip" {
    description = "Staging network gateway ip"
    type        = "string"
    default     = "192.168.128.1"
}

variable "user_admin" {
    description = "User admin to use for managing the node"
    type        = "string"
    default     = "root"
}

# define input variables for the modules
# `pass search terraform-proxmox` in credential store
variable "user_admin_ssh_public_key" {
  type    = "string"
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDVKCfpeIMg7GS3Pk03ZAcBWAeDZ+AvWk2k/pPY0z8MJ3YAbqZkRtSK7yaDgJV6Gro7nn/TxdJLo2jEzzWvlC8d8AEzhZPy5Z/qfVVjqBTBM4H5+e+TItAHFfaY5+0WvIahxcfsfaq70MWfpJhszAah3ThJ4mqzYaw+dkr42+a7Gx3Ygpb/m2dpnFnxvXdcuAJYStmHKU5AWGWWM+Fm50/fdMqUfNd8MbKhkJt5ihXQmZWMOt7ls4N8i5NZWnS9YSWow8X/ENOEqCRN9TyRkc+pPS0w9DNi0BCsWvSRJOkyvQ6caEnKWlNoywCmM1AlIQD3k4RUgRWe0vqg/UKPpH3Z root@terraform"
}
