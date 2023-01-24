module "scheduler0" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "pompidou"
  onboot      = false

  vmid        = 116
  hostname    = "scheduler0"
  description = "Scheduler api services"
  # to match the real vm configuration in proxmox
  # to remove
  args    = "-device virtio-rng-pci"
  cores   = 4
  memory  = 8192
  balloon = 1024
  networks = [{
    id      = 0
    ip      = "192.168.130.50"
    gateway = local.config["gateway_ip"]
    macaddr = "92:02:7E:D0:B9:36"
    bridge  = local.config["bridge"]
  }]
}

output "scheduler0_summary" {
  value = module.scheduler0.summary
}

module "worker0" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "beaubourg"
  onboot      = false

  vmid        = 117
  hostname    = "worker0"
  description = "Loader/lister service node"
  cores       = "2"
  memory      = 4096
  balloon     = 1024
  args        = "-device virtio-rng-pci"

  networks = [{
    id      = 0
    ip      = "192.168.130.100"
    gateway = local.config["gateway_ip"]
    macaddr = "72:D9:03:46:B1:47"
    bridge  = local.config["bridge"]
  }]
}

output "worker0_summary" {
  value = module.worker0.summary
}

module "webapp" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "pompidou"
  onboot      = false

  vmid        = 119
  hostname    = "webapp"
  description = "Archive/Webapp service node"
  cores       = 4
  memory      = 16384
  balloon     = 1024
  # to match the real vm configuration in proxmox
  # to remove
  args = "-device virtio-rng-pci"
  networks = [{
    id      = 0
    ip      = "192.168.130.30"
    gateway = local.config["gateway_ip"]
    macaddr = "1A:00:39:95:D4:5F"
    bridge  = local.config["bridge"]
  }]
}

output "webapp_summary" {
  value = module.webapp.summary
}

module "deposit" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "pompidou"
  onboot      = false

  vmid        = 120
  hostname    = "deposit"
  description = "Deposit service node"
  cores       = "4"
  memory      = "8192"
  balloon     = 1024
  # to match the real vm configuration in proxmox
  # to remove
  args = "-device virtio-rng-pci"
  networks = [{
    id      = 0
    ip      = "192.168.130.31"
    gateway = local.config["gateway_ip"]
    macaddr = "9E:81:DD:58:15:3B"
    bridge  = local.config["bridge"]
  }]
}

output "deposit_summary" {
  value = module.deposit.summary
}

module "vault" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "pompidou"
  onboot      = false

  vmid        = 121
  hostname    = "vault"
  description = "Vault services node"
  cores       = "4"
  memory      = "8192"
  balloon     = 1024
  # to match the real vm configuration in proxmox
  # to remove
  args = "-device virtio-rng-pci"
  networks = [{
    id      = 0
    ip      = "192.168.130.60"
    gateway = local.config["gateway_ip"]
    macaddr = "16:15:1C:79:CB:DB"
    bridge  = local.config["bridge"]
  }]
}

output "vault_summary" {
  value = module.vault.summary
}

module "rp0" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "pompidou"
  onboot      = false

  vmid        = 129
  hostname    = "rp0"
  description = "Node to host the reverse proxy"
  cores       = 2
  memory      = 2048
  balloon     = 1024
  networks = [{
    id      = 0
    ip      = "192.168.130.20"
    gateway = local.config["gateway_ip"]
    macaddr = "4A:80:47:5D:DF:73"
    bridge  = local.config["bridge"]
  }]
  # facter_subnet     = "sesi_rocquencourt_staging"
  # factor_deployment = "staging"
}

output "rp0_summary" {
  value = module.rp0.summary
}


module "search-esnode0" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "pompidou"
  onboot      = false

  vmid        = 130
  hostname    = "search-esnode0"
  description = "Node to host the elasticsearch instance"
  cores       = "4"
  memory      = "32768"
  balloon     = 9216
  networks = [{
    id      = 0
    ip      = "192.168.130.80"
    gateway = local.config["gateway_ip"]
    macaddr = "96:74:49:BD:B5:08"
    bridge  = local.config["bridge"]
  }]
  storages = [{
    id      = 0
    storage = "proxmox"
    size    = "32G"
    }, {
    id      = 1
    storage = "proxmox"
    size    = "200G"
  }]
}

output "search-esnode0_summary" {
  value = module.search-esnode0.summary
}

module "search0" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "pompidou"
  onboot      = false

  vmid        = 131
  hostname    = "search0"
  description = "Node to host the swh-search rpc backend service"
  cores       = 2
  memory      = 4096
  balloon     = 1024
  networks = [{
    id      = 0
    ip      = "192.168.130.90"
    gateway = local.config["gateway_ip"]
    macaddr = "EE:FA:76:55:CF:99"
    bridge  = local.config["bridge"]
  }]
}

output "search0_summary" {
  value = module.search0.summary
}

module "objstorage0" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "pompidou"
  onboot      = false

  vmid        = 102
  hostname    = "objstorage0"
  description = "Node to host a read-only objstorage for mirrors"
  cores       = 2
  memory      = 12288
  balloon     = 3072
  networks = [{
    id      = 0
    ip      = "192.168.130.110"
    gateway = local.config["gateway_ip"]
    macaddr = "5E:28:EA:7D:50:0D"
    bridge  = local.config["bridge"]
  }]
}

output "objstorage0_summary" {
  value = module.objstorage0.summary
}

module "counters0" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "pompidou"
  onboot      = false

  vmid        = 138
  hostname    = "counters0"
  description = "Counters server"
  cores       = "4"
  memory      = "6096"
  balloon     = 2048
  networks = [{
    id      = 0
    ip      = "192.168.130.95"
    gateway = local.config["gateway_ip"]
    macaddr = "E2:6E:12:C7:3E:A4"
    bridge  = local.config["bridge"]
  }]
}

output "counters0_summary" {
  value = module.counters0.summary
}

module "mirror-test" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "pompidou"
  onboot      = false

  vmid        = 132
  hostname    = "mirror-test"
  description = "Sandbox VM to test the mirror environment"
  sockets     = "2"
  cores       = "4"

  memory      = "65536"
  balloon     = "20480"
  networks = [{
    id      = 0
    ip      = "192.168.130.160"
    gateway = local.config["gateway_ip"]
    macaddr = "E6:3C:8A:B7:26:5D"
    bridge  = local.config["bridge"]
  }]
}

output "mirror-tests_summary" {
  value = module.mirror-test.summary
}

module "maven-exporter0" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "pompidou"
  onboot      = false

  template    = var.templates["stable-zfs"]
  vmid        = 122
  hostname    = "maven-exporter0"
  description = "Maven index exporter to run containers and expose export.fld files"
  sockets     = "1"
  cores       = "4"

  memory  = "4096"
  balloon = "1024"

  networks = [{
    id      = 0
    ip      = "192.168.130.70"
    gateway = local.config["gateway_ip"]
    macaddr = "36:86:F6:F9:2A:5D"
    bridge  = local.config["bridge"]
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

output "maven-exporter0_summary" {
  value = module.maven-exporter0.summary
}

module "scrubber0" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "pompidou"
  onboot      = false

  vmid        = 142
  hostname    = "scrubber0"
  description = "Scrubber checker services"
  sockets     = "1"
  cores       = "4"

  memory  = "4096"
  balloon = "1024"

  networks = [{
    id      = 0
    ip      = "192.168.130.120"
    gateway = local.config["gateway_ip"]
    macaddr = "86:09:0A:61:AB:C1"
    bridge  = local.config["bridge"]
  }]

  storages = [{
    storage = "proxmox"
    size    = "30G"
    }
  ]
}

output "scrubber0_summary" {
  value = module.scrubber0.summary
}
