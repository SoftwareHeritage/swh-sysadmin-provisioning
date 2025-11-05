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
  started     = false

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

module "jenkins-docker01" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "mucem"
  onboot      = true
  vmid        = 151
  hostname    = "jenkins-docker01"
  description = "Docker-based jenkins agent"

  cpu = {
    type    = "host"
    sockets = 2
    cores   = 4
  }

  ram = {
    dedicated = 32768
    floating  = 2048
  }

  network = {
    ip          = "192.168.100.151"
    mac_address = "DA:1C:7D:C6:31:0E"
  }

  disks = [
    {
      interface = "virtio0"
      size    = 20
    },
    {
      datastore_id = "scratch"
      interface    = "virtio1"
      size         = 200
    }
  ]
}

module "jenkins-docker02" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "branly"
  onboot      = true
  vmid        = 152
  hostname    = "jenkins-docker02"
  description = "Docker-based jenkins agent"

  cpu = {
    type    = "host"
    sockets = 2
    cores   = 4
  }

  ram = {
    dedicated = 32768
    floating  = 2048
  }

  network = {
    ip          = "192.168.100.152"
    mac_address = "C6:B9:79:73:0D:23"
  }

  disks = [
    {
      interface = "virtio0"
      size      = 20
    },
    {
      datastore_id = "scratch"
      interface    = "virtio1"
      size         = 200
    }
  ]
}

module "jenkins-docker03" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "chaillot"
  onboot      = true
  vmid        = 156
  hostname    = "jenkins-docker03"
  description = "Docker-based jenkins agent"

  cpu = {
    type    = "host"
    sockets = 2
    cores   = 4
  }

  ram = {
    dedicated = 32768
    floating  = 2048
  }

  network = {
    ip          = "192.168.100.153"
    mac_address = ""
  }

  disks = [
    {
      interface = "virtio0"
      size      = 20
    },
    {
      datastore_id = "scratch"
      interface    = "virtio1"
      size         = 200
    }
  ]
}
