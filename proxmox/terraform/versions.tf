terraform {
  required_version = ">= 0.13"
  required_providers {
    proxmox = {
      source = "local/telmate/proxmox"
      version = "0.0.1"
    }
  }
}
