module "scheduler0" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "branly"
  onboot      = true
  tags        = ["staging",]
  vmid        = 116
  hostname    = "scheduler0"
  description = "Scheduler api services"

  # to match the real vm configuration in proxmox to remove
  kvm_args    = "-device virtio-rng-pci"

  ram = {
    dedicated = 8192
  }

  network = {
    ip      = "192.168.130.50"
    gateway = local.config["gateway_ip"]
    macaddr = "92:02:7E:D0:B9:36"
    bridge  = local.config["bridge"]
  }

  disks = [{
    path_in_datastore = "vm-116-disk-1"
  }]
}

output "scheduler0_summary" {
  value = module.scheduler0.summary
}

module "rp0" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "pompidou"
  onboot      = true

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
  onboot      = true

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

module "counters0" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "pompidou"
  onboot      = true

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

###### NEW BPG VMs######

module "runner0" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "branly"
  onboot      = true
  tags        = ["staging","gitlab-runner"]

  vmid        = 148
  hostname    = "runner0"
  description = "Gitlab runner to process add-forge-now requests"

  cdrom = {
    interface = "ide2"
  }

  network = {
    ip          = "192.168.130.221"
    gateway     = local.config["gateway_ip"]
    mac_address = "1A:4B:96:85:01:64"
    bridge      = local.config["bridge"]
  }

  disks = [{
      datastore_id      = "proxmox"
      interface         = "virtio0"
      size              = 20
      path_in_datastore = "base-10012-disk-0/vm-148-disk-0"
    },
    {
      datastore_id      = "proxmox"
      interface         = "virtio1"
      size              = 30
      path_in_datastore = "vm-148-disk-1"
    }]
}

output "runner0_summary" {
  value = module.runner0.summary
}

module "maven-exporter0" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "chaillot"
  onboot      = true
  tags        = ["staging",]
  vmid        = 122
  hostname    = "maven-exporter0"
  description = "Maven index exporter to run containers and expose export.fld files"

  network = {
    ip          = "192.168.130.70"
    gateway     = local.config["gateway_ip"]
    mac_address = "36:86:F6:F9:2A:5D"
    bridge      = local.config["bridge"]
  }

  disks = [{
      datastore_id      = "proxmox"
      interface         = "virtio0"
      size              = 20
      path_in_datastore = "base-10005-disk-0/vm-122-disk-0"
    },
    {
      datastore_id      = "proxmox"
      interface         = "virtio1"
      size              = 50
      path_in_datastore = "vm-122-disk-1"
    }]
}

output "maven-exporter0_summary" {
  value = module.maven-exporter0.summary
}
