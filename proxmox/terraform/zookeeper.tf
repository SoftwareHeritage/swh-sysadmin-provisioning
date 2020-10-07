module "zookeeper1" {
  source = "./modules/node"
  config = local.config

  hostname    = "zookeeper1"
  description = "Zookeeper server"
  hypervisor  = "hypervisor3"
  vmid        = 125
  cores       = "2"
  memory      = "4096"
  networks = [{
    id      = 0
    ip      = "192.168.100.131"
    gateway = local.config["gateway_ip"]
    macaddr = "9A:BF:FB:6D:49:27"
    bridge  = "vmbr0"
  }]
}

module "zookeeper2" {
  source = "./modules/node"
  config = local.config

  hostname    = "zookeeper2"
  description = "Zookeeper server"
  hypervisor  = "branly"
  vmid        = 124
  cores       = "2"
  memory      = "4096"
  networks = [{
    id      = 0
    ip      = "192.168.100.132"
    gateway = local.config["gateway_ip"]
    macaddr = "66:B0:72:A8:70:5C"
    bridge  = "vmbr0"
  }]
}

module "zookeeper3" {
  source = "./modules/node"
  config = local.config

  hostname    = "zookeeper3"
  description = "Zookeeper server"
  hypervisor  = "beaubourg"
  vmid        = 102
  cores       = "2"
  memory      = "4096"
  networks = [{
    id      = 0
    ip      = "192.168.100.133"
    gateway = local.config["gateway_ip"]
    macaddr = "E2:7C:D7:6A:F6:B0"
    bridge  = "vmbr0"
  }]
}
