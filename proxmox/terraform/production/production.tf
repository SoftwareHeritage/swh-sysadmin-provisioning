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
  memory      = "16384"
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

module "migration" {
  source      = "../modules/node"
  config      = local.config
  template    = var.templates["bullseye-zfs"]

  hostname    = "migration"
  description = "Migration"
  hypervisor  = "branly"
  sockets     = "1"
  cores       = "4"
  memory      = "16192"

  networks = [{
    id      = 0
    ip      = "192.168.100.140"
    gateway = local.config["gateway_ip"]
    bridge  = local.config["bridge"]
  }]

  storages = [{
    storage = "proxmox"
    size    = "20G"
    }, {
    storage = "proxmox"
    size    = "20G"
    }
  ]
}

output "migration_summary" {
  value = module.migration.summary
}

module "maven-exporter" {
  source      = "../modules/node"
  template    = var.templates["bullseye-zfs"]
  config      = local.config
  hostname    = "maven-exporter"
  description = "Maven index exporter to run containers and expose export.fld files"
  hypervisor  = "mucem"
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

module "jenkins-docker01" {
  source      = "../modules/node"
  template    = var.templates["bullseye-zfs"]
  vmid        = 151
  config      = local.config
  hostname    = "jenkins-docker01"
  description = "Docker-based jenkins agent"
  hypervisor  = "mucem"
  cpu         = "host"
  sockets     = "2"
  cores       = "4"
  onboot      = true
  memory      = "16384"
  balloon     = "2048"

  networks = [{
    id      = 0
    ip      = "192.168.100.151"
    gateway = local.config["gateway_ip"]
    bridge  = local.config["bridge"]
  }]

  storages = [{
    storage = "proxmox"
    size    = "20G"
    }, {
    storage = "scratch"
    size    = "200G"
    }
  ]
}

module "jenkins-docker02" {
  source      = "../modules/node"
  template    = var.templates["bullseye-zfs"]
  vmid        = 152
  config      = local.config
  hostname    = "jenkins-docker02"
  description = "Docker-based jenkins agent"
  hypervisor  = "mucem"
  cpu         = "host"
  sockets     = "2"
  cores       = "4"
  onboot      = true
  memory      = "16384"
  balloon     = "2048"

  networks = [{
    id      = 0
    ip      = "192.168.100.152"
    gateway = local.config["gateway_ip"]
    bridge  = local.config["bridge"]
  }]

  storages = [{
    storage = "proxmox"
    size    = "20G"
    }, {
    storage = "scratch"
    size    = "200G"
    }
  ]
}
