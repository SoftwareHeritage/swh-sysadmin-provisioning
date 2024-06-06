# will start from 1 storage01...
variable "storage_servers" {
  default = 0
}

variable "storage_disk_size" {
  default = 30720
}


locals {
  storage_servers = {
    for i in range(var.storage_servers) :
    format("storage%02d", i + 1) => {
      datadisks = {}
    }
  }
}


resource "azurerm_network_interface" "storage-interface" {
  for_each = local.storage_servers

  name                = format("%s-interface", each.key)
  location            = "westeurope"
  resource_group_name = "euwest-servers"

  ip_configuration {
    name                          = "storageNicConfiguration"
    subnet_id                     = data.azurerm_subnet.default.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "storage-interface-sga" {
  for_each = local.storage_servers

  network_interface_id      = azurerm_network_interface.storage-interface[each.key].id
  network_security_group_id = data.azurerm_network_security_group.worker-nsg.id
}

resource "azurerm_virtual_machine" "storage-server" {
  for_each = local.storage_servers

  name                  = each.key
  location              = "westeurope"
  resource_group_name   = "euwest-servers"
  network_interface_ids = [azurerm_network_interface.storage-interface[each.key].id]
  vm_size               = "Standard_D8s_v3"

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
      key_data = var.ssh_key_data_ardumont
    }
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
      host = azurerm_network_interface.storage-interface[each.key].private_ip_address
    }
  }

  provisioner "file" {
    content = templatefile("templates/firstboot.sh.tpl", {
      hostname        = each.key
      fqdn            = format("%s.euwest.azure.internal.softwareheritage.org", each.key),
      ip_address      = azurerm_network_interface.storage-interface[each.key].private_ip_address,
      facter_subnet     = "azure_euwest"
      facter_deployment = "production"

      disk_setup      = {}
    })
    destination = var.firstboot_script

    connection {
      type = "ssh"
      user = "root"
      host = azurerm_network_interface.storage-interface[each.key].private_ip_address
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
      host = azurerm_network_interface.storage-interface[each.key].private_ip_address
    }
  }

  tags = {
    environment = "Storage"
  }
}
