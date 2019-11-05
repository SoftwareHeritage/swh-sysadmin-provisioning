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
    default     = "template-debian-10"
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

variable "config" {
    description = "Local config to avoid duplication from the main module"
    type = "map"
}
