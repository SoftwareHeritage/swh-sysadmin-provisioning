variable "resource_group" {
  description = "Resource group name of the kubernetes cluster. Must already exist"
  type        = string
}

variable "cluster_name" {
  description = "Name of the cluster, for example: euwest-gitlab-staging"
  type        = string
}

variable "node_type" {
  description = "Type of vms in the default node pool"
  default     = "Standard_B2ms"
  type        = string
}

variable "minimal_pool_count" {
  description = "Minimal number of node in the default pool"
  type        = number
  default     = 1
}

variable "maximal_pool_count" {
  description = "Minimal number of node in the default pool"
  type        = number
  default     = 5
}

variable "internal_vnet" {
  description = "A vnet accessible from the VPN"
  type        = string
  default     = "swh-vnet"
}

variable "internal_vnet_rg" {
  description = "The resource group of the vnet accessible from the VPN"
  type        = string
  default     = "swh-resource"
}

variable "public_ip_provisioning" {
  description = "Should a public ip should be provisionned?"
  type        = bool
  default     = true
}

variable "kubernetes_version" {
  description = "The kubernetes version to use, must match https://docs.gitlab.com/operator/installation.html#kubernetes"
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "The id of a log analytics workspace to send Container Insights to"
  type        = string
  default     = null
}
