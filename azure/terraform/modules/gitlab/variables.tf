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
