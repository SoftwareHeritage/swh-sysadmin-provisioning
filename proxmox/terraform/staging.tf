# Keyword use:
# - provider: Define the provider(s)
# - data: Retrieve data information to be used within the file
# - resource: Define resource and create/update

provider "proxmox" {
  pm_tls_insecure = true
  pm_api_url      = "https://orsay.internal.softwareheritage.org:8006/api2/json"
  # in a shell (see README): source ./setup.sh
}

# Default configuration passed along module calls
# (There is no other way to avoid duplication)
locals {
  config = {
    dns                       = var.dns
    domain                    = var.domain
    puppet_environment        = var.puppet_environment
    puppet_master             = var.puppet_master
    gateway_ip                = var.gateway_ip
    user_admin                = var.user_admin
    user_admin_ssh_public_key = var.user_admin_ssh_public_key
  }
}


# Define the staging network gateway
# FIXME: Find a way to reuse the module "node"
# Main difference between node in module and this:
# - gateway define 2 network interfaces
# - provisioning step is more complex
resource "proxmox_vm_qemu" "gateway" {
  name = "gateway"
  desc = "staging gateway node"

  # hypervisor onto which make the vm
  target_node = "orsay"

  # See init-template.md to see the template vm bootstrap
  clone = "template-debian-10"

  # linux kernel 2.6
  qemu_os = "l26"

  # generic setup
  sockets = 1
  cores   = 1
  memory  = 1024

  boot = "c"

  # boot machine when hypervirsor starts
  onboot = true

  #### cloud-init setup
  # to actually set some information per os_type (values: ubuntu, centos,
  # cloud-init). Keep this as cloud-init
  os_type = "cloud-init"

  # ciuser - User name to change ssh keys and password for instead of the
  # image’s configured default user.
  ciuser   = var.user_admin
  ssh_user = var.user_admin

  # searchdomain - Sets DNS search domains for a container.
  searchdomain = var.domain

  # nameserver - Sets DNS server IP address for a container.
  nameserver = var.dns

  # sshkeys - public ssh keys, one per line
  sshkeys = var.user_admin_ssh_public_key

  # FIXME: When T1872 lands, this will need to be updated
  # ipconfig0 - [gw =] [,ip=<IPv4Format/CIDR>]
  # ip to communicate for now with the prod network through louvre
  ipconfig0 = "ip=192.168.100.125/24,gw=192.168.100.1"

  # vms from the staging network will use this vm as gateway
  ipconfig1 = "ip=${var.gateway_ip}/24"
  disk {
    id           = 0
    type         = "virtio"
    storage      = "orsay-ssd-2018"
    storage_type = "ssd"
    size         = "20G"
  }
  network {
    id      = 0
    model   = "virtio"
    bridge  = "vmbr0"
    macaddr = "6E:ED:EF:EB:3C:AA"
  }
  network {
    id      = 1
    model   = "virtio"
    bridge  = "vmbr0"
    macaddr = "FE:95:CC:A5:EB:43"
  }

  # Delegate to puppet at the end of the provisioning the software setup
  # Delegate to puppet at the end of the provisioning the software setup
  provisioner "remote-exec" {
    inline = [
      "sysctl -w net.ipv4.ip_forward=1",
      "sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf",
      "iptables -t nat -A POSTROUTING -s 192.168.128.0/24 -o eth0 -j MASQUERADE",
      "sed -i 's/127.0.1.1/${var.gateway_ip}/g' /etc/hosts",
      "puppet agent --server ${var.puppet_master} --environment=${var.puppet_environment} --waitforcert 60 --test || echo 'Node provisionned!'",
    ]
  }

  lifecycle {
    ignore_changes = [
      bootdisk,
      scsihw,
    ]
  }
}

module "storage0" {
  source = "./modules/node"
  config = local.config

  hostname    = "storage0"
  description = "swh storage services"
  cores       = "4"
  memory      = "8192"
  network = {
    ip      = "192.168.128.2"
    macaddr = "CA:73:7F:ED:F9:01"
  }
}

output "storage0_summary" {
  value = module.storage0.summary
}

module "db0" {
  source = "./modules/node"
  config = local.config

  hostname    = "db0"
  description = "Node to host storage/indexer/scheduler dbs"
  cores       = "4"
  memory      = "16384"
  network = {
    ip      = "192.168.128.3"
    macaddr = "3A:65:31:7C:24:17"
  }
  storage = {
    location = "orsay-ssd-2018"
    size     = "100G"
  }
}

output "db0_summary" {
  value = module.db0.summary
}

module "scheduler0" {
  source = "./modules/node"
  config = local.config

  hostname    = "scheduler0"
  description = "Scheduler api services"
  cores       = "4"
  memory      = "16384"
  network = {
    ip      = "192.168.128.4"
    macaddr = "92:02:7E:D0:B9:36"
  }
}

output "scheduler0_summary" {
  value = module.scheduler0.summary
}

module "worker0" {
  source = "./modules/node"
  config = local.config

  hostname    = "worker0"
  description = "Loader/lister service node"
  cores       = "4"
  memory      = "16384"
  network = {
    ip      = "192.168.128.5"
    macaddr = "72:D9:03:46:B1:47"
  }
}

output "worker0_summary" {
  value = module.worker0.summary
}

module "worker1" {
  source = "./modules/node"
  config = local.config

  hostname    = "worker1"
  description = "Loader/lister service node"
  cores       = "4"
  memory      = "16384"
  network = {
    ip      = "192.168.128.6"
    macaddr = "D6:A9:6F:02:E3:66"
  }
}

output "worker1_summary" {
  value = module.worker1.summary
}

module "webapp" {
  source = "./modules/node"
  config = local.config

  hostname    = "webapp"
  description = "Archive/Webapp service node"
  cores       = "4"
  memory      = "16384"
  network = {
    ip      = "192.168.128.8"
    macaddr = "1A:00:39:95:D4:5F"
  }
}

output "webapp_summary" {
  value = module.webapp.summary
}

module "deposit" {
  source = "./modules/node"
  config = local.config

  hostname    = "deposit"
  description = "Deposit service node"
  cores       = "4"
  memory      = "16384"
  network = {
    ip      = "192.168.128.7"
    macaddr = "9E:81:DD:58:15:3B"
  }
}

output "deposit_summary" {
  value = module.deposit.summary
}

module "vault" {
  source = "./modules/node"
  config = local.config

  hostname    = "vault"
  description = "Vault services node"
  cores       = "4"
  memory      = "16384"
  network = {
    ip      = "192.168.128.9"
    macaddr = "16:15:1C:79:CB:DB"
  }
}

output "vault_summary" {
  value = module.vault.summary
}

module "journal0" {
  source = "./modules/node"
  config = local.config

  hostname    = "journal0"
  description = "Journal services node"
  cores       = "4"
  memory      = "16384"
  network = {
    ip      = "192.168.128.10"
    macaddr = "1E:98:C2:66:BF:33"
  }
}

output "journal0_summary" {
  value = module.journal0.summary
}

module "worker2" {
  source = "./modules/node"
  config = local.config

  hostname    = "worker2"
  description = "Loader/lister service node"
  cores       = "4"
  memory      = "16384"
  network = {
    ip      = "192.168.128.11"
    macaddr = "AA:57:27:51:75:18"
  }
}

output "worker2_summary" {
  value = module.worker2.summary
}

