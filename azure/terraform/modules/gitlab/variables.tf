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
