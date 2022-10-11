module "kelvingrove" {
  source = "../modules/node"
  config = local.config

  hostname    = "kelvingrove"
  description = "Keycloak server"
  hypervisor  = "hypervisor3"
  cores       = "4"
  memory      = "8192"
  cpu         = "host"
  numa        = true
  balloon     = 0
  networks = [{
    id      = 0
    ip      = "192.168.100.106"
    gateway = local.config["gateway_ip"]
    macaddr = "72:55:5E:58:01:0B"
    bridge  = local.config["bridge"]
  }]
}

module "webapp1" {
  source = "../modules/node"
  config = local.config

  hostname    = "webapp1"
  description = "Webapp for swh-search tests"
  hypervisor  = "branly"
  cores       = "2"
  memory      = "12288"
  balloon     = 8192
  networks = [{
    id      = 0
    ip      = "192.168.100.71"
    gateway = local.config["gateway_ip"]
    macaddr = "06:FF:02:95:31:CF"
    bridge  = local.config["bridge"]
  }]
}

module "search1" {
  source = "../modules/node"
  config = local.config

  hostname    = "search1"
  description = "swh-search node"
  hypervisor  = "branly"
  cores       = "4"
  memory      = "6144"
  balloon     = 1024
  networks = [{
    id      = 0
    ip      = "192.168.100.85"
    gateway = local.config["gateway_ip"]
    macaddr = "3E:46:D3:88:44:F4"
    bridge  = local.config["bridge"]
  }]
}

module "counters1" {
  source = "../modules/node"
  config = local.config

  hostname    = "counters1"
  description = "swh-counters node"
  hypervisor  = "branly"
  cores       = "4"
  memory      = "2048"
  balloon     = 1024
  networks = [{
    id      = 0
    ip      = "192.168.100.95"
    gateway = local.config["gateway_ip"]
    macaddr = "26:8E:7F:D1:F7:99"
    bridge  = local.config["bridge"]
  }]
}

module "worker17" {
  source = "../modules/node"
  config = local.config

  hostname    = "worker17"
  domainname  = "softwareheritage.org"
  description = "swh-worker node (temporary)"
  hypervisor  = "uffizi"
  cores       = "5"
  sockets     = "2"
  memory      = "65536"
  balloon     = "32768"
  networks = [{
    id      = 0
    ip      = "192.168.100.43"
    gateway = local.config["gateway_ip"]
    macaddr = "36:E0:2D:70:7C:52"
    bridge  = local.config["bridge"]
  }]
}

module "provenance-client01" {
  source = "../modules/node"
  config = local.config

  hostname    = "provenance-client01"
  description = "Provenance client"
  template    = var.templates["stable"]
  hypervisor  = "uffizi"
  cores       = "4"
  sockets     = "4"
  memory      = "131072"
  balloon     = 32768
  networks = [{
    id      = 0
    ip      = "192.168.100.111"
    gateway = local.config["gateway_ip"]
    macaddr = null
    bridge  = local.config["bridge"]
  }]
}

module "scrubber1" {
  source      = "../modules/node"
  config      = local.config
  vmid        = 153
  onboot      = true

  hostname    = "scrubber1"
  description = "Scrubber checker services"
  hypervisor  = "branly"
  sockets     = "1"
  cores       = "4"
  memory      = "4096"

  networks = [{
    id      = 0
    ip      = "192.168.100.90"
    gateway = local.config["gateway_ip"]
    macaddr = "B2:E5:3F:E2:77:13"
    bridge  = local.config["bridge"]
  }]
}

output "scrubber1_summary" {
  value = module.scrubber1.summary
}

module "maven-exporter" {
  source      = "../modules/node"
  template    = var.templates["stable-zfs"]
  config      = local.config
  hostname    = "maven-exporter"
  description = "Maven index exporter to run containers and expose export.fld files"
  hypervisor  = "pompidou"
  sockets     = "1"
  cores       = "4"
  onboot      = true
  memory      = "4096"
  balloon     = "2048"

  networks = [{
    id      = 0
    ip      = "192.168.100.10"
    gateway = local.config["gateway_ip"]
    bridge  = local.config["bridge"]
    macaddr = "D2:7E:0B:35:89:FF"
  }]

  storages = [{
    storage = "proxmox"
    size    = "20G"
    }, {
    storage = "proxmox"
    size    = "50G"
    }
  ]
}
