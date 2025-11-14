terraform {
  required_version = ">= 0.13"
  required_providers {
    bpg-proxmox = {
      source = "bpg/proxmox"
      version = "0.73.0"
    }
    rancher2 = {
      source = "rancher/rancher2"
      version = "8.3.1"
    }
  }
}

provider "bpg-proxmox" {
  endpoint = "https://chaillot.internal.softwareheritage.org:8006/"
}
