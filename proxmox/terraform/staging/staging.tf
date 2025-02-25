module "scheduler0" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "pompidou"
  onboot      = true

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

module "webapp" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "pompidou"
  onboot      = true

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
  onboot      = true

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
  onboot      = true

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

module "search0" {
  source      = "../modules/node"
  config      = local.config
  hypervisor  = "pompidou"
  onboot      = true

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
  onboot      = true

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

###### NEW ######

resource "proxmox_virtual_environment_vm" "runner0" {
  provider      = bpg-proxmox
  name          = "runner0"
  description   = "Gitlab runner to process add-forge-now requests"
  node_name     = "branly"
  vm_id         = 148
  tags          = ["staging","gitlab-runner",]

  # do not uncomment otherwise it will destroy and create again
  #clone {
  #  vm_id = 10014 # debian-bookworm-12.1-zfs-2023-08-30
  #}

  cpu {
    sockets   = 1
    cores     = 4
    type      = "kvm64"
  }

  memory {
    dedicated = 4096
    floating  = 1024
  }

  agent {
    enabled = false
  }

  initialization {

    datastore_id = "proxmox"
    interface    = "ide0"
    ip_config {
      ipv4 {
        address = "192.168.130.221/24"
        gateway = local.config["gateway_ip"]
      }
    }
    dns {
      domain  = local.config["domain"]
      servers = [local.config["dns"],]
    }

    user_account {
      keys     = [
        local.config["user_admin_ssh_public_key"],
      ]
      username = local.config["user_admin"]
    }
  }

  disk {
    datastore_id = "proxmox"
    interface    = "virtio0"
    discard      = "ignore"
    size         = 20
    file_format  = "raw"
    path_in_datastore = "base-10012-disk-0/vm-148-disk-0"
  }

  disk {
    datastore_id = "proxmox"
    interface    = "virtio1"
    discard      = "ignore"
    size         = 30
    file_format  = "raw"
    path_in_datastore = "vm-148-disk-1"
  }

  network_device {
    bridge       = local.config["bridge"]
    mac_address  = "1A:4B:96:85:01:64"
    disconnected = false
  }
}
output "runner0_summary" {
  value = <<EOF

hostname: ${proxmox_virtual_environment_vm.runner0.name}
fqdn: ${proxmox_virtual_environment_vm.runner0.name}.${local.config["domain"]}
network: ${proxmox_virtual_environment_vm.runner0.initialization[0].ip_config[0].ipv4[0].address}
EOF
}

resource "proxmox_virtual_environment_vm" "maven-exporter0" {
  provider      = bpg-proxmox
  name          = "maven-exporter0"
  description   = "Maven index exporter to run containers and expose export.fld files"
  node_name     = "chaillot"
  vm_id         = 122
  tags          = ["staging",]

  # do not uncomment otherwise it will destroy and create again
  #clone {
  #  vm_id = 10014 # debian-bookworm-12.1-zfs-2023-08-30
  #}

  cpu {
    sockets   = 1
    cores     = 4
    type      = "kvm64"
  }

  memory {
    dedicated = 4096
    floating  = 1024
  }

  agent {
    enabled = false
  }

  cdrom {
    file_id   = "proxmox:vm-122-cloudinit"
  }

  operating_system {
    type = "l26"
  }

  initialization {

    datastore_id = "proxmox"
    interface    = "ide3"
    ip_config {
      ipv4 {
        address = "192.168.130.70/24"
        gateway = local.config["gateway_ip"]
      }
    }
    dns {
      domain  = local.config["domain"]
      servers = [local.config["dns"],]
    }

    user_account {
      keys     = [
        local.config["user_admin_ssh_public_key"],
      ]
      username = local.config["user_admin"]
    }
  }

  disk {
    datastore_id = "proxmox"
    interface    = "virtio0"
    discard      = "ignore"
    size         = 20
    file_format  = "raw"
    path_in_datastore = "base-10005-disk-0/vm-122-disk-0"
  }

  disk {
    datastore_id = "proxmox"
    interface    = "virtio1"
    discard      = "ignore"
    size         = 50
    file_format  = "raw"
    path_in_datastore = "vm-122-disk-1"
  }

  network_device {
    bridge       = local.config["bridge"]
    mac_address  = "36:86:F6:F9:2A:5D"
    disconnected = false
  }
}

output "maven-exporter0_summary" {
  value = <<EOF

hostname: ${proxmox_virtual_environment_vm.maven-exporter0.name}
fqdn: ${proxmox_virtual_environment_vm.maven-exporter0.name}.${local.config["domain"]}
network: ${proxmox_virtual_environment_vm.maven-exporter0.initialization[0].ip_config[0].ipv4[0].address}
EOF
}

