variable "hostname" {
  description = "Node's hostname"
  type        = string
}

variable "description" {
  description = "Node's description"
  type        = string
}

variable "hypervisor" {
  description = "Hypervisor to install the vm to (choice: orsay, hypervisor3, beaubourg, branly)"
  type        = string
}

variable "template" {
  description = "Template to use (template-debian-9, template-debian-10)"
  type        = string
  default     = "template-debian-10"
}

variable "sockets" {
  description = "Number of sockets"
  type        = string
  default     = "1"
}

variable "cores" {
  description = "Number of cores"
  type        = string
  default     = "1"
}

variable "memory" {
  description = "Memory in Mb"
  type        = string
  default     = "1024"
}

variable "network" {
  description = "staging network's ip/macaddr/bridge"
  type        = map(string)
}


variable "vmid" {
  description = "virtual machine id"
  type        = number
  default     = 0
}

variable "balloon" {
  description = "ballooning option"
  type        = number
  default     = 0
}

variable "numa" {
  type = bool
  default = false
}

variable "storage" {
  description = "Storage disk location and size in the hypervisor storage"
  type        = map(string)
  default = {
    location = "proxmox"
    size     = "32G"
  }
}

variable "config" {
  description = "Local config to avoid duplication from the main module"
  type        = map(string)
}
