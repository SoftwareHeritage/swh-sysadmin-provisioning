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

variable "networks" {
  description = "Default networks configuration (id, ip, gateway, macaddr, bridge)"
  type = list(object({
    id      = number
    ip      = string
    gateway = string
    macaddr = string
    bridge  = string
  }))
  default = []
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

variable "storages" {
  description = "Default disks configuration (id, storage, size, storage_type)"
  type = list(object({
    id           = number
    storage      = string
    size         = string
    storage_type = string
  }))
  default = [{
    id           = 0
    storage      = "proxmox"
    size         = "32G"
    storage_type = "cephfs"
  }]
}

variable "config" {
  description = "Local config to avoid duplication from the main module"
  type        = map(string)
}
