terraform {
  required_version = ">= 0.13"
  experiments      = [module_variable_optional_attrs]
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "2.9.10"
    }
    rancher2 = {
      source = "rancher/rancher2"
      version = "1.23.0"
    }
  }
}

provider "proxmox" {
  pm_tls_insecure = true
  pm_api_url      = "https://beaubourg.internal.softwareheritage.org:8006/api2/json"
  # in a shell (see README): source ../setup.sh

  # Uncomment this section to activate the proxmox execution logs
  # pm_log_enable = true
  # pm_log_file = "terraform-plugin-proxmox.log"
  # pm_debug = true
  # pm_log_levels = {
  #   _default = "debug"
  #   _capturelog = ""
  # }
}
