variable "hostname" {
  description = "Node hostname"
  type        = string
}

variable "domainname" {
  description = "Domain name. If empty the config domain is used as fallback."
  type        = string
  default     = ""
}

variable "description" {
  description = "Node description"
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
  type        = map(string)
  default = {
    # CPU type possible values (not exhaustive): kvm64, host, ... The default is kvm64 and must be specified to avoid issues on refresh
    type    = "kvm64"
    cores   = 4
    sockets = 1
  }
}

variable "ram" {
  description = "RAM hardware configuration (dedicated, floating)"
  type        = map(string)
  default = {
    dedicated = 4096
    floating  = 1024
  }
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
  description = "CDROM configuration (file_id, interface)"
  type = map(string)
  default = {
    file_id   = "none"
    interface = "ide2"
  }
}

variable "cloudinit-drive" {
  description = "Default cloudinit drive configuration (datastore_id, interface)"
  type = map(string)
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
  description = "List of disk configurations (e.g. datastore_id, interface, size, dicard, file_format, path_in_datastore)"
  type = list(map(string))
  default = [{
    datastore_id = "proxmox"
    interface    = "virtio0"
    size         = 32
    discard      = "ignore"
    file_format  = "raw"
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

variable "kvm_args" {
  description = "Extra kvm arguments"
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
