module "kelvingrove" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "chaillot"
  onboot      = true
  vmid        = 123
  hostname    = "kelvingrove"
  description = "Keycloak server"

  ram = {
    dedicated = 8192
    floating  = 0
  }

  cpu = {
    type = "host"
    numa = true
  }

  network = {
    ip          = "192.168.100.106"
    mac_address = "72:55:5E:58:01:0B"
  }
}

output "kelvingrove_summary" {
  value = module.kelvingrove.summary
}

module "counters1" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "branly"
  onboot      = true
  vmid        = 139
  hostname    = "counters1"
  description = "swh-counters node"

  ram = {
    dedicated = 2048
  }

  network = {
    ip          = "192.168.100.95"
    mac_address = "26:8E:7F:D1:F7:99"
  }
}

output "counters1_summary" {
  value = module.counters1.summary
}

module "migration" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "branly"
  onboot      = false
  vmid        = 118
  hostname    = "migration"
  description = "Migration"

  ram = {
    dedicated = 16384
    floating  = 0
  }

  network = {
    ip          = "192.168.100.140"
    mac_address = "FE:29:E8:08:F1:93"
  }

  disks = [
    {
      interface = "virtio0"
      size      = 20
    },
    {
      interface = "virtio1"
      size      = 20
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
  memory      = "32768"
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
  memory      = "32768"
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
