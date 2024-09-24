variable "hostname" {
  description = "Node's hostname"
  type        = string
}

variable "domainname" {
  description = "Domain name. If empty the config domain is used as fallback."
  type        = string
  default     = ""
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
  description = "Debian image template created by packer"
  # Note: use "buster" template for node with swh services (storage, objstorage, ...).
  # You can use latest "bullseye" templates otherwise.
  type        = string
  default     = "debian-buster-10.10-2021-09-09"
  # other possible template values:
  # - debian-bullseye-11.7-2023-08-29
  # - debian-bullseye-11.7-zfs-2023-08-29  (for extra zfs dependencies)
  # - debian-bookworm-12.1-2023-08-30
  # - debian-bookworm-12.1-zfs-2023-08-30  (for extra zfs dependencies)
}

variable "sockets" {
  description = "Number of sockets"
  type        = number
  default     = 1
}

variable "cores" {
  description = "Number of cores"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory in Mb"
  type        = number
  default     = 1024
}

variable "networks" {
  description = "Default networks configuration (id, ip, gateway, macaddr, bridge)"
  type = list(object({
    id      = number
    ip      = string
    gateway = string
    macaddr = optional(string)
    bridge  = string
  }))
  default = []
}


variable "vmid" {
  description = "virtual machine id"
  type        = number
  default     = null
}

variable "balloon" {
  description = "ballooning option"
  type        = number
  default     = 0
}

variable "numa" {
  type    = bool
  default = false
}

variable "storages" {
  description = "Default disks configuration (storage, size)"
  type = list(object({
    storage = string
    size    = string
  }))
  default = [{
    storage = "proxmox"
    size    = "32G"
  }]
}

variable "config" {
  description = "Local config to avoid duplication from the main module"
  type        = map(string)
}

variable "args" {
  description = "args to pass to the qemu command. should not be used in most cases"
  type        = string
  default     = ""
}

variable "pre_provision_steps" {
  description = "Sequential provisioning steps to apply *before* common provision steps"
  type        = list(string)
  default     = []
}

variable "post_provision_steps" {
  description = "Sequential provisioning steps to apply *after* common provision steps"
  type        = list(string)
  default     = []
}

variable "cicustom" {
  description = "custom ci parameter"
  type        = string
  default     = ""
}

variable "full_clone" {
  description = "Full clone the template"
  type        = bool
  default     = false
}

variable "cpu" {
  description = "CPU type possible values (not exhaustive): kvm64, host, ... The default is kvm64 and must be specified to avoid issues on refresh"
  type        = string
  default     = "kvm64"
}

variable "onboot" {
  description = "Start the vm on hypervisor boot"
  type        = bool
  default     = true
}

variable "cdrom_disk" {
  description = "For legacy vms installed without cdrom"
  type        = bool
  default     = true
}

variable "cdrom_disk_slot" {
  description = "For legacy vms, allow to adapt the cdrom slot id"
  type        = string
  default     = "ide2"
}

variable "cloudinit_disk" {
  description = "For legacy vms installed without cloudinit disk"
  type        = bool
  default     = true
}

variable "cloudinit_disk_slot" {
  description = "For legacy vms, allow to adapt the cloudinit slot id"
  type        = string
  default     = "ide0"
}
