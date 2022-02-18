# Define a new resource for a (test) mirror
# matching what we name elsewhere "euwest-${resource}"

variable "mirror_replay_servers" {
  default = 0
}

data "azurerm_platform_image" "debian10" {
  location  = "westeurope"
  publisher = "debian"
  offer     = "debian-10"
  sku       = "10"
}

resource "azurerm_resource_group" "euwest-mirror-test" {
  # disable this
  count = 0

  name     = "euwest-mirror-test"
  location = "westeurope"

  tags = {
    environment = "SWH Mirror"
  }
}

resource "azurerm_network_security_group" "mirror-nsg" {
  # disable this
  count = 0

  name                = "mirror-nsg"
  resource_group_name = "euwest-mirror-test"
  location            = "westeurope"
}

locals {
  mirror_replay_servers = {
    for i in range(var.mirror_replay_servers) :
    format("mirror-replay%02d", i + 1) => {
      datadisks = {}
    }
  }
}


# master machine - run the docker swarm master node on which will run
# most of the services but the db and replayers
resource "azurerm_network_interface" "mirror-master-interface" {
  # disable this
  count = 0

  name                = "mirror-master-interface"
  location            = "westeurope"
  resource_group_name = "euwest-mirror-test"

  ip_configuration {
    name                          = "mirrorMasterNicConfiguration"
    subnet_id                     = data.azurerm_subnet.default.id
    public_ip_address_id          = ""
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "mirror-master-interface-sga" {
  count                     = 0
  network_interface_id      = azurerm_network_interface.mirror-master-interface[0].id
  network_security_group_id = azurerm_network_security_group.mirror-nsg[0].id
}

#resource "azurerm_managed_disk" "mirror-master-osdisk" {
#  name                  = "mirror-master-osdisk"
#  create_option         = "FromImage"
#  location              = "westeurope"
#  resource_group_name   = "euwest-mirror-test"
#  storage_account_type  = "Premium_LRS"
#  image_reference_id    = data.azurerm_platform_image.debian10.id
#image_reference_id    = "/Subscriptions/49b7f681-8efc-4689-8524-870fc0c1db09/Providers/Microsoft.Compute/Locations/westeurope/Publishers/Debian/ArtifactTypes/VMImage/Offers/debian-10/Skus/10"
#}
resource "azurerm_virtual_machine" "mirror-master" {
  # disable this
  count = 0

  name                  = "mirror-master"
  location              = "westeurope"
  resource_group_name   = "euwest-mirror-test"
  network_interface_ids = [azurerm_network_interface.mirror-master-interface[count.index].id]
  vm_size               = "Standard_B2ms"


  delete_os_disk_on_termination = true

  #  storage_os_disk {
  #	create_option      = "attach"
  #    name               = "mirror-master-osdisk"
  #    caching            = "ReadWrite"
  #	managed_disk_id    = azurerm_managed_disk.mirror-master-osdisk.id
  #	os_type            = "Linux"
  #  }

  storage_os_disk {
    name              = "mirror-master-osdisk"
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
    computer_name  = "mirror-master"
    admin_username = var.user_admin
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.user_admin}/.ssh/authorized_keys"
      key_data = var.ssh_key_data_douardda
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir /root/.ssh",
      "echo ${var.ssh_key_data_ardumont} | sudo tee -a /root/.ssh/authorized_keys",
      "echo ${var.ssh_key_data_douardda} | sudo tee -a /root/.ssh/authorized_keys",
      "echo ${var.ssh_key_data_olasd} | sudo tee -a /root/.ssh/authorized_keys"
    ]

    connection {
      type = "ssh"
      user = var.user_admin
      host = azurerm_network_interface.mirror-master-interface[count.index].private_ip_address
    }
  }

  tags = {
    environment = "SWH Mirror"
  }
}

# the DB host
resource "azurerm_network_interface" "mirror-db-interface" {
  # disable this
  count = 0

  name                = "mirror-db-interface"
  location            = "westeurope"
  resource_group_name = "euwest-mirror-test"
  # network_security_group_id = azurerm_network_security_group.mirror-nsg[0].id

  ip_configuration {
    name                          = "mirrorDbNicConfiguration"
    subnet_id                     = data.azurerm_subnet.default.id
    public_ip_address_id          = ""
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "mirror-db-interface-sga" {
  count = 0

  network_interface_id      = azurerm_network_interface.mirror-db-interface[0].id
  network_security_group_id = azurerm_network_security_group.mirror-nsg[0].id
}


resource "azurerm_managed_disk" "mirror-db-storage" {
  # disable this
  count = 0

  name                 = "mirror-db-disk1"
  location             = azurerm_resource_group.euwest-mirror-test[0].location
  resource_group_name  = azurerm_resource_group.euwest-mirror-test[0].name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 1024
}

resource "azurerm_virtual_machine_data_disk_attachment" "mirror-db-storage" {
  # disable this
  count = 0

  managed_disk_id    = azurerm_managed_disk.mirror-db-storage[count.index].id
  virtual_machine_id = azurerm_virtual_machine.mirror-db[count.index].id
  lun                = "10"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine" "mirror-db" {
  # disable this
  count = 0

  name                          = "mirror-db"
  location                      = "westeurope"
  resource_group_name           = "euwest-mirror-test"
  network_interface_ids         = [azurerm_network_interface.mirror-db-interface[count.index].id]
  vm_size                       = "Standard_F8s_v2"
  delete_os_disk_on_termination = true

  storage_os_disk {
    name              = "mirror-db-osdisk"
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
    computer_name  = "mirror-db"
    admin_username = var.user_admin
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.user_admin}/.ssh/authorized_keys"
      key_data = var.ssh_key_data_douardda
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir /root/.ssh",
      "echo ${var.ssh_key_data_ardumont} | sudo tee -a /root/.ssh/authorized_keys",
      "echo ${var.ssh_key_data_douardda} | sudo tee -a /root/.ssh/authorized_keys",
      "echo ${var.ssh_key_data_olasd} | sudo tee -a /root/.ssh/authorized_keys"
    ]

    connection {
      type = "ssh"
      user = var.user_admin
      host = azurerm_network_interface.mirror-db-interface[count.index].private_ip_address
    }
  }

  tags = {
    environment = "SWH Mirror"
  }
}

# replayer machines
resource "azurerm_network_interface" "mirror-replayer-interface" {
  for_each = local.mirror_replay_servers

  name                = format("%s-interface", each.key)
  location            = "westeurope"
  resource_group_name = azurerm_resource_group.euwest-mirror-test[0].name
  #enable_accelerated_networking = true

  ip_configuration {
    name                          = "mirrorReplayerNicConfiguration"
    subnet_id                     = data.azurerm_subnet.default.id
    public_ip_address_id          = ""
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [azurerm_resource_group.euwest-mirror-test]
}

resource "azurerm_network_interface_security_group_association" "mirror-replayer-interface-sga" {
  for_each = local.mirror_replay_servers

  network_interface_id      = azurerm_network_interface.mirror-replayer-interface[each.key].id
  network_security_group_id = azurerm_network_security_group.mirror-nsg[0].id
}

resource "azurerm_virtual_machine" "mirror-replayer" {
  for_each              = local.mirror_replay_servers
  name                  = each.key
  location              = "westeurope"
  resource_group_name   = "euwest-mirror-test"
  network_interface_ids = [azurerm_network_interface.mirror-replayer-interface[each.key].id]
  vm_size               = "Standard_B2s"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

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
      key_data = var.ssh_key_data_douardda
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir /root/.ssh",
      "echo ${var.ssh_key_data_ardumont} | sudo tee -a /root/.ssh/authorized_keys",
      "echo ${var.ssh_key_data_douardda} | sudo tee -a /root/.ssh/authorized_keys",
      "echo ${var.ssh_key_data_olasd} | sudo tee -a /root/.ssh/authorized_keys"
    ]

    connection {
      type = "ssh"
      user = var.user_admin
      host = azurerm_network_interface.mirror-replayer-interface[self.name].private_ip_address
    }
  }

  tags = {
    environment = "SWH Mirror"
  }
}

# for the obj storage, if any
#resource "azurerm_storage_account" "mirror-storage" {
#  name                     = "mirror-storage"
#  resource_group_name      = "${azurerm_resource_group.euwest-mirror-test[0].name}"
#  location                 = "westeurope"
#  account_tier             = "Standard"
#  account_replication_type = "LRS"
#  account_kind             = "BlobStorage"
#  access_tier              = "Cool"
#  tags = {
#      environment = "SWH Mirror Storage"
#  }
#}

# A container for the blob storage named 'contents' (as other blob storages)
#resource "azurerm_storage_container" "mirror-graph-storage" {
#  name                  = "mirror-graph-storage"
#  resource_group_name   = "${azurerm_resource_group.euwest-mirror-test[0].name}"
#  storage_account_name  = "${azurerm_storage_account.mirror-storage.name}"
#  container_access_type = "private"
#}
