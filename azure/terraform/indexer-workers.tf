# will start from 1 indexer-worker01...
variable "indexer-workers" {
  default = 6
}

locals {
  indexer-workers = {
    for i in range(var.indexer-workers) :
    format("indexer-worker%02d", i + 1) => {
      datadisks = {}
    }
  }
}

resource "azurerm_network_interface" "indexer-worker-interface" {
  for_each = local.indexer-workers

  name                = format("%s-interface", each.key)
  location            = "westeurope"
  resource_group_name = "euwest-workers"

  ip_configuration {
    name                          = "indexerWorkerNicConfiguration"
    subnet_id                     = data.azurerm_subnet.default.id
    public_ip_address_id          = ""
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "indexer-worker-sga" {
  for_each = local.indexer-workers

  network_interface_id      = azurerm_network_interface.indexer-worker-interface[each.key].id
  network_security_group_id = data.azurerm_network_security_group.worker-nsg.id
}

resource "azurerm_linux_virtual_machine" "indexer-worker" {
  for_each = local.indexer-workers

  name                  = each.key
  computer_name         = "${each.key}.euwest.azure.internal.softwareheritage.org"
  location              = "westeurope"
  resource_group_name   = "euwest-workers"
  network_interface_ids = [azurerm_network_interface.indexer-worker-interface[each.key].id]
  size                  = "Standard_B2ms"
  admin_username        = var.user_admin

  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics_uri
  }

  os_disk {
    name                 = format("%s-osdisk", each.key)
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "debian"
    offer     = "debian-10"
    sku       = "10"
    version   = "latest"
  }

  admin_ssh_key {
    username = var.user_admin
    public_key = file("ssh-keys/id-rsa-ardumont.pub")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /root/.ssh",
      "echo ${var.ssh_key_data_ardumont} | sudo tee /root/.ssh/authorized_keys",
      "echo ${var.ssh_key_data_olasd} | sudo tee -a /root/.ssh/authorized_keys",
      "echo ${var.ssh_key_data_vsellier} | sudo tee -a /root/.ssh/authorized_keys",
    ]

    connection {
      type = "ssh"
      user = var.user_admin
      host = azurerm_network_interface.indexer-worker-interface[each.key].private_ip_address
    }
  }

  provisioner "file" {
    content = templatefile("templates/firstboot.sh.tpl", {
      hostname        = each.key
      fqdn            = format("%s.euwest.azure.internal.softwareheritage.org", each.key),
      ip_address      = azurerm_network_interface.indexer-worker-interface[each.key].private_ip_address,
      facter_subnet     = "azure_euwest"
      facter_deployment = "production"

      disk_setup      = {}
    })
    destination = var.firstboot_script

    connection {
      type = "ssh"
      user = var.user_admin
      host = azurerm_network_interface.indexer-worker-interface[each.key].private_ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "userdel -f ${var.user_admin}",
      "chmod +x ${var.firstboot_script}",
      var.firstboot_script,
    ]
    connection {
      type = "ssh"
      user = "root"
      host = azurerm_network_interface.indexer-worker-interface[each.key].private_ip_address
    }
  }

  tags = {
    environment = "workers"
  }
}
