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
  default     = "192.168.128.1"
}

variable "user_admin" {
  description = "User admin to use for managing the node"
  type        = string
  default     = "root"
}

# define input variables for the modules
# `pass search terraform-proxmox` in credential store
variable "user_admin_ssh_public_key" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDVKCfpeIMg7GS3Pk03ZAcBWAeDZ+AvWk2k/pPY0z8MJ3YAbqZkRtSK7yaDgJV6Gro7nn/TxdJLo2jEzzWvlC8d8AEzhZPy5Z/qfVVjqBTBM4H5+e+TItAHFfaY5+0WvIahxcfsfaq70MWfpJhszAah3ThJ4mqzYaw+dkr42+a7Gx3Ygpb/m2dpnFnxvXdcuAJYStmHKU5AWGWWM+Fm50/fdMqUfNd8MbKhkJt5ihXQmZWMOt7ls4N8i5NZWnS9YSWow8X/ENOEqCRN9TyRkc+pPS0w9DNi0BCsWvSRJOkyvQ6caEnKWlNoywCmM1AlIQD3k4RUgRWe0vqg/UKPpH3Z root@terraform"
}

