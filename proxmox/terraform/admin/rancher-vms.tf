module "rancher-mgmt1" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "chaillot"
  onboot      = true
  hostname    = "rancher-mgmt1"
  description = "control-plane for Rancher kubernetes cluster"
  tags        = ["rancher"]

  cpu = {
    type = "x86-64-v3"
  }

  ram = {
    dedicated = 16384
    floating  = 16384
  }

  network = {
    ip          = "192.168.50.161"
  }

  disks = [{
    interface = "virtio0"
    size      = 20
  },
  {
    interface    = "virtio1"
    size         = 20
    datastore_id = "scratch"
  }]
}

module "rancher-node1" {
  source      = "../modules/node_bpg"
  config      = local.config
  hypervisor  = "chaillot"
  onboot      = true
  hostname    = "rancher-node1"
  description = "worker for Rancher kubernetes cluster"
  tags        = ["rancher"]

  cpu = {
    type = "x86-64-v3"
  }

  ram = {
    dedicated = 16384
    floating  = 16384
  }

  network = {
    ip          = "192.168.50.164"
  }

  disks = [{
    interface = "virtio0"
    size      = 20
  },
  {
    interface    = "virtio1"
    size         = 20
    datastore_id = "scratch"
  }]
}
