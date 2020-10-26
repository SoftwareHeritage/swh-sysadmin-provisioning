variable "cassandra_replay_servers" {
  default = 0
}

resource "azurerm_resource_group" "euwest-cassandra-replay" {
  # Disable this
  count    = 0

  name     = "euwest-cassandra-replay"
  location = "westeurope"

  tags = {
    environment = "Cassandra"
  }
}

locals {
  cassandra_replay_servers = {
    for i in range(var.cassandra_replay_servers):
      format("cassandra-replay%02d", i + 1) => {
        datadisks = {}
      }
  }
}



resource "azurerm_network_interface" "cassandra-replayer-interface" {
  for_each                      = local.cassandra_replay_servers

  name                          = format("%s-interface", each.key)
  location                      = "westeurope"
  resource_group_name           = azurerm_resource_group.euwest-cassandra-replay[0].name
  network_security_group_id     = data.azurerm_network_security_group.worker-nsg.id

  enable_accelerated_networking = true

  ip_configuration {
    name                          = "vaultNicConfiguration"
    subnet_id                     = data.azurerm_subnet.default.id
    public_ip_address_id          = ""
    private_ip_address_allocation = "Dynamic"
  }

  depends_on                = [azurerm_resource_group.euwest-cassandra-replay]
}


resource "azurerm_virtual_machine" "cassandra-replay-server" {
  for_each              = local.cassandra_replay_servers

  depends_on            = [azurerm_resource_group.euwest-cassandra-replay]

  name                  = each.key
  location              = "westeurope"
  resource_group_name   = azurerm_resource_group.euwest-cassandra-replay[0].name
  network_interface_ids = [azurerm_network_interface.cassandra-replayer-interface[each.key].id]
  vm_size               = "Standard_F8s_v2"

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
      host = azurerm_network_interface.cassandra-replayer-interface[self.name].private_ip_address
    }
  }

  provisioner "file" {
    content     = templatefile("templates/firstboot.sh.tpl", {
      hostname   = self.name
      fqdn       = format("%s.euwest.azure.internal.softwareheritage.org", self.name)
      ip_address = azurerm_network_interface.cassandra-replayer-interface[self.name].private_ip_address
      facter_location = "azure_euwest"
      disk_setup = {}
    })
    destination = var.firstboot_script

    connection {
      type = "ssh"
      user = "root"
      host = azurerm_network_interface.cassandra-replayer-interface[self.name].private_ip_address
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
      host = azurerm_network_interface.cassandra-replayer-interface[self.name].private_ip_address
    }
  }

  tags = {
    environment = "Cassandra"
  }
}
