variable "cassandra_servers" {
  default = 0
}

variable "cassandra_disk_size" {
  default = 1024
}

variable "cassandra_disks_per_server" {
  default = 4
}

resource "azurerm_resource_group" "euwest-cassandra" {
  name     = "euwest-cassandra"
  location = "westeurope"

  tags = {
    environment = "Cassandra"
  }
}

locals {
  cassandra_servers = {
    for i in range(var.cassandra_servers) :
    format("cassandra%02d", i + 1) => {
      datadisks = {
        for i in range(var.cassandra_disks_per_server) :
        format("datadisk%02d", i + 1) => {
          lun  = i + 1
          path = format("/dev/disk/azure/scsi1/lun%d", i + 1)
        }
      }
    }
  }
}


resource "azurerm_network_interface" "cassandra-interface" {
  for_each = local.cassandra_servers

  name                = format("%s-interface", each.key)
  location            = "westeurope"
  resource_group_name = azurerm_resource_group.euwest-cassandra.name

  enable_accelerated_networking = true

  ip_configuration {
    name                          = "vaultNicConfiguration"
    subnet_id                     = data.azurerm_subnet.default.id
    public_ip_address_id          = ""
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [azurerm_resource_group.euwest-cassandra]
}

resource "azurerm_network_interface_security_group_association" "cassandra-interface-sga" {
  for_each = local.cassandra_servers

  network_interface_id      = azurerm_network_interface.cassandra-interface[each.key].id
  network_security_group_id = data.azurerm_network_security_group.worker-nsg.id
}

resource "azurerm_virtual_machine" "cassandra-server" {
  for_each = local.cassandra_servers

  depends_on = [azurerm_resource_group.euwest-cassandra]

  name                  = each.key
  location              = "westeurope"
  resource_group_name   = azurerm_resource_group.euwest-cassandra.name
  network_interface_ids = [azurerm_network_interface.cassandra-interface[each.key].id]
  vm_size               = "Standard_DS13_v2"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  boot_diagnostics {
    enabled     = true
    storage_uri = var.boot_diagnostics_uri
  }

  storage_os_disk {
    name              = format("%s-osdisk", each.key)
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  dynamic "storage_data_disk" {
    for_each = each.value.datadisks

    content {
      name              = format("%s-%s", each.key, storage_data_disk.key)
      caching           = "None"
      create_option     = "Empty"
      managed_disk_type = "Standard_LRS"
      disk_size_gb      = var.cassandra_disk_size
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
      host = azurerm_network_interface.cassandra-interface[self.name].private_ip_address
    }
  }

  provisioner "file" {
    content = templatefile("templates/firstboot.sh.tpl", {
      hostname        = self.name
      fqdn            = format("%s.euwest.azure.internal.softwareheritage.org", self.name)
      ip_address      = azurerm_network_interface.cassandra-interface[self.name].private_ip_address
      facter_location = "azure_euwest"
      disk_setup = {
        disks = [
          for disk in local.cassandra_servers[self.name].datadisks : {
            base_disk = disk.path
          }
        ]
        raids = [{
          path          = "/dev/md0"
          level         = 0
          chunk         = "128K"
          members       = [for disk in local.cassandra_servers[self.name].datadisks : format("%s-part1", disk.path)]
          mountpoint    = "/srv/cassandra"
          filesystem    = "ext4"
          mount_options = "defaults"
        }]
      }
    })
    destination = var.firstboot_script

    connection {
      type = "ssh"
      user = "root"
      host = azurerm_network_interface.cassandra-interface[self.name].private_ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "userdel -f ${var.user_admin}",
      "chmod +x ${var.firstboot_script}",
      "cat ${var.firstboot_script}",
      var.firstboot_script,
    ]
    connection {
      type = "ssh"
      user = "root"
      host = azurerm_network_interface.cassandra-interface[self.name].private_ip_address
    }
  }

  tags = {
    environment = "Cassandra"
  }
}
