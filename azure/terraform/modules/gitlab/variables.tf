variable "name" {
  description = "Name of the gitlab environment"
  type        = string
}

variable "location" {
  description = "Name of the gitlab environment"
  type        = string
  default     = "westeurope"
}

variable "blob_storage_name" {
  description = "Blob storage name. lower case, only letters and numbers"
  type        = string
}

variable "blob_storage_containers" {
  description = "Blob storage containers to create on the storage account"
  type        = list(string)
  default = [
    "artifacts", "registry", "external-diffs", "lfs-objects", "uploads",
    "packages", "dependency-proxy", "terraform", "pages",
  ]
}

variable "backups_storage_name" {
  description = "Blob backups name. lower case, only letters and numbers"
  type        = string
}

variable "backups_storage_containers" {
  description = "Blob storage containers to create on the storage account"
  type        = list(string)
  default     = ["backups", "tmp"]
}

variable "kubernetes_version" {
  description = "The kubernetes version to use, must match https://docs.gitlab.com/operator/installation.html#kubernetes"
  type        = string
  default     = "1.22"
}

variable "container_insights" {
  description = "Whether to enable Azure Container Insights"
  type        = bool
  default     = false
}

variable "minimal_pool_count" {
  description = "minimal nodes count to instanciate in the node pool"
  type        = number
  default     = 1
}

variable "maximal_pool_count" {
  description = "minimal nodes count to instanciate in the node pool"
  type        = number
  default     = 5
}

variable "pool_node_type" {
  description = "node type for pools"
  type        = string
  default     = "Standard_B2ms"
}

variable "pool_name" {
  description = "name of default node pool"
  type        = string
  default     = "default"
}
