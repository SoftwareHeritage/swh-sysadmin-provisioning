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
  description = "Debian image template vm id"
  type        = number
  default     = 10014
  # other possible template values (see in Proxmox UI):
  # - 10012: debian-bullseye-11.7-zfs-2023-08-29  (for extra zfs dependencies)
  # - 10013:  debian-bookworm-12.1-2023-08-30
  # - 10014: debian-bookworm-12.1-zfs-2023-08-30  (for extra zfs dependencies)
}

variable "cpu" {
  description = "CPU hardware configuration (cores, sockets, types)"
  type        = object({
    # CPU type possible values (not exhaustive): kvm64, host, ... The default is kvm64 and must be specified to avoid issues on refresh
    type    = optional(string)
    cores   = optional(number)
    sockets = optional(number)
  })
  default = {
    type    = "kvm64"
    cores   = 4
    sockets = 1
  }
}

variable "ram" {
  description = "RAM hardware configuration (dedicated, floating)"
  type        = object({
    dedicated = optional(number)
    # ballooning option
    floating  = optional(number)
  })
  default = {
    dedicated = 4096
    floating  = 1024
  }
}

variable "memory" {
  description = "Memory in Mb"
  type        = number
  default     = 1024
}
variable "balloon" {
  description = "ballooning option"
  type        = number
  default     = 0
}


variable "network" {
  description = "Default networks configuration (ip, gateway, macaddr, bridge)"
  type        = object({
    ip          = string
    gateway     = string
    mac_address = optional(string)
    bridge      = string
  })
}

variable "cdrom" {
  description = "Default networks configuration (ip, gateway, macaddr, bridge)"
  type = object({
    file_id   = optional(string)
    interface = optional(string)
  })
  default = {
    file_id   = "none"
    interface = "ide2"
  }
}

variable "cloudinit-drive" {
  description = "Default cloudinit drive configuration (datastore_id, interface)"
  type = object({
    datastore_id = optional(string)
    interface    = optional(string)
  })
  default = {
    datastore_id = "proxmox"
    interface    = "ide0"
  }
}

variable "tags" {
  description = "List of tags applied to VM (e.g. production)"
  type = list(string)
  default = []
}

variable "vmid" {
  description = "virtual machine id"
  type        = number
  default     = null
}


variable "disks" {
  description = "List of disk configurations (datastore_id, size, ...)"
  type = list(object({
      datastore_id      = string
      interface         = string
      size              = number
      discard           = optional(string)
      file_format       = optional(string)
      path_in_datastore = optional(string)
  }))
  default = [{
    datastore_id = "proxmox"
    interface    = "virtio0"
    size         = 32
  }]
}

variable "config" {
  description = "Local config to avoid duplication from the main module"
  type        = map(string)
}


variable "onboot" {
  description = "Start the vm on hypervisor boot"
  type        = bool
  default     = true
}
