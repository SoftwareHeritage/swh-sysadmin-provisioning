terraform {
  required_version = ">= 0.13"
  required_providers {
    proxmox = {
      source = "local/telmate/proxmox"
      version = "0.0.1"
    }
  }
}

provider "proxmox" {
  pm_tls_insecure = true
  pm_api_url      = "https://beaubourg.internal.softwareheritage.org:8006/api2/json"
  # in a shell (see README): source ../setup.sh
}
