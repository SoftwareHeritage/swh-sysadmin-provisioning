variable "boatbucket_disk_size" {
  default = 1024
}

variable "boatbucket_zfs_disk_size" {
  default = 1024
}

variable "boatbucket_zfs_slog_disk_size" {
  default = 128
}

variable "boatbucket_zfs_special_disk_size" {
  default = 256
}

variable "boatbucket_disks_per_server" {
  default = 8
}

variable "boatbucket_zfs_slog_disks_per_server" {
  default = 2
}

variable "boatbucket_zfs_slog_lun_offset" {
  default = 9
}

variable "boatbucket_zfs_disks_per_server" {
  default = 8
}

variable "boatbucket_zfs_lun_offset" {
  default = 15
}

variable "boatbucket_zfs_special_disks_per_server" {
  default = 2
}

variable "boatbucket_zfs_special_lun_offset" {
  default = 31
}



resource "azurerm_resource_group" "euwest-boatbucket" {
  name     = "euwest-boatbucket"
  location = "westeurope"

  tags = {
    environment = "Boatbucket"
  }
}


resource "azurerm_network_security_group" "boatbucket-public-nsg" {
  name                = "boatbucket-public-nsg"
  location            = "westeurope"
  resource_group_name = azurerm_resource_group.euwest-boatbucket.name

  security_rule {
    name                       = "boatbucket-icmp-inbound-public"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "0"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "boatbucket-ssh-inbound-public"
    priority                   = 2000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }
}


locals {
  boatbucket_servers = {
    boatbucket = {
      datadisks = {
        for i in range(var.boatbucket_disks_per_server):
        format("datadisk%02d", i + 1) => {
          lun  = i + 1
          path = format("/dev/disk/azure/scsi1/lun%d", i + 1)
        }
      }
      zfs_slog_disks = {
        for i in range(var.boatbucket_zfs_slog_disks_per_server):
        format("zfs-slog%02d", i + 1) => {
          lun  = i + var.boatbucket_zfs_slog_lun_offset
          path = format("/dev/disk/azure/scsi1/lun%d", i + var.boatbucket_zfs_slog_lun_offset)
        }
      }
      zfs_disks = {
        for i in range(var.boatbucket_zfs_disks_per_server):
        format("zfs%02d", i + 1) => {
          lun  = i + var.boatbucket_zfs_lun_offset
          path = format("/dev/disk/azure/scsi1/lun%d", i + var.boatbucket_zfs_lun_offset)
        }
      }
      zfs_special_disks = {
        for i in range(var.boatbucket_zfs_special_disks_per_server):
        format("zfs-special%02d", i + 1) => {
          lun  = i + var.boatbucket_zfs_special_lun_offset
          path = format("/dev/disk/azure/scsi1/lun%d", i + var.boatbucket_zfs_special_lun_offset)
        }
      }
   }
  }
}


resource "azurerm_public_ip" "boatbucket-public-ip" {
  for_each = local.boatbucket_servers

  name                    = format("%s-ip", each.key)
  domain_name_label       = format("swh-%s", each.key)
  location                = "westeurope"
  resource_group_name     = azurerm_resource_group.euwest-boatbucket.name
  allocation_method       = "Static"
  sku                     = "Standard"
  idle_timeout_in_minutes = 30
}

resource "azurerm_network_interface" "boatbucket-interface" {
  for_each                      = local.boatbucket_servers

  name                          = format("%s-interface", each.key)
  location                      = "westeurope"
  resource_group_name           = azurerm_resource_group.euwest-boatbucket.name
  network_security_group_id     = azurerm_network_security_group.boatbucket-public-nsg.id

  enable_accelerated_networking = true

  ip_configuration {
    name                          = "vaultNicConfiguration"
    subnet_id                     = data.azurerm_subnet.default.id
    public_ip_address_id          = azurerm_public_ip.boatbucket-public-ip[each.key].id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_virtual_machine" "boatbucket-server" {
  for_each              = local.boatbucket_servers

  name                  = each.key
  location              = "westeurope"
  resource_group_name   = azurerm_resource_group.euwest-boatbucket.name
  network_interface_ids = [azurerm_network_interface.boatbucket-interface[each.key].id]
  vm_size               = "Standard_D16as_v4"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  boot_diagnostics {
    enabled     = true
    storage_uri = var.boot_diagnostics_uri
  }

  storage_os_disk {
    name              = format("%s-osdisk2", each.key)
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  dynamic storage_data_disk {
    for_each = each.value.datadisks

    content {
      name              = format("%s-%s", each.key, storage_data_disk.key)
      caching           = "ReadOnly"
      create_option     = "Empty"
      managed_disk_type = "Premium_LRS"
      disk_size_gb      = var.boatbucket_disk_size
      lun               = storage_data_disk.value.lun
    }
  }

  dynamic storage_data_disk {
    for_each = each.value.zfs_slog_disks

    content {
      name              = format("%s-%s", each.key, storage_data_disk.key)
      caching           = "None"
      create_option     = "Empty"
      managed_disk_type = "Premium_LRS"
      disk_size_gb      = var.boatbucket_zfs_slog_disk_size
      lun               = storage_data_disk.value.lun
    }
  }

  dynamic storage_data_disk {
    for_each = each.value.zfs_disks

    content {
      name              = format("%s-%s", each.key, storage_data_disk.key)
      caching           = "None"
      create_option     = "Empty"
      managed_disk_type = "Standard_LRS"
      disk_size_gb      = var.boatbucket_zfs_disk_size
      lun               = storage_data_disk.value.lun
    }
  }

  dynamic storage_data_disk {
    for_each = each.value.zfs_special_disks

    content {
      name              = format("%s-%s", each.key, storage_data_disk.key)
      caching           = "None"
      create_option     = "Empty"
      managed_disk_type = "Premium_LRS"
      disk_size_gb      = var.boatbucket_zfs_special_disk_size
      lun               = storage_data_disk.value.lun
    }
  }

  storage_image_reference {
    publisher = "debian"
    offer     = "debian-10"
    sku       = "10"
    version   = "latest"
  }

  os_profile {
    computer_name  = each.key
    admin_username = var.user_admin
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.user_admin}/.ssh/authorized_keys"
      key_data = var.ssh_key_data_olasd
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir /root/.ssh",
      "echo ${var.ssh_key_data_ardumont} | sudo tee -a /root/.ssh/authorized_keys",
      "echo ${var.ssh_key_data_olasd} | sudo tee -a /root/.ssh/authorized_keys",
    ]

    connection {
      type = "ssh"
      user = var.user_admin
      host = azurerm_network_interface.boatbucket-interface[self.name].private_ip_address
    }
  }

  provisioner "file" {
    content     = templatefile("templates/firstboot.sh.tpl", {
      hostname   = self.name
      fqdn       = format("%s.euwest.azure.internal.softwareheritage.org", self.name)
      ip_address = azurerm_network_interface.boatbucket-interface[self.name].private_ip_address
      facter_location = "azure_euwest",
      disk_setup = {
      disks = [
        for disk in local.boatbucket_servers[self.name].datadisks: {
          base_disk = disk.path
        }
      ]
      raids = [{
        path          = "/dev/md0"
        level         = 0
        chunk         = "128K"
        members       = [for disk in local.boatbucket_servers[self.name].datadisks: format("%s-part1", disk.path)]
      }]
      lvm_vgs = [{
        name          = format("%s-vg", self.name)
        pvs           = ["/dev/md0"]
        lvs           = [{
          name          = "data"
          extents       = "50%FREE"
          mountpoint    = "/srv/boatbucket"
          filesystem    = "ext4"
          mount_options = "defaults"
          mkfs_options  = "-T small"
        }]
      }]
      }
    })
    destination = var.firstboot_script

    connection {
      type = "ssh"
      user = "root"
      host = azurerm_network_interface.boatbucket-interface[self.name].private_ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "userdel -f ${var.user_admin}",
      "chmod +x ${var.firstboot_script}",
      "cat ${var.firstboot_script}",
      "${var.firstboot_script}",
    ]
    connection {
      type = "ssh"
      user = "root"
      host = azurerm_network_interface.boatbucket-interface[self.name].private_ip_address
    }
  }

  tags = {
    environment = "Boatbucket"
  }
}
