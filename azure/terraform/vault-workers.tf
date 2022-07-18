# will start from 1 vault-worker01...
variable "vault-workers" {
  default = 1
}

locals {
  vault-workers = {
    for i in range(var.vault-workers) :
    format("vault-worker%02d", i + 1) => {
      datadisks = {}
    }
  }
}

resource "azurerm_network_interface" "vault-worker-interface" {
  for_each = local.vault-workers

  name                = format("%s-interface", each.key)
  location            = "westeurope"
  resource_group_name = "euwest-workers"

  ip_configuration {
    name                          = "vaultWorkerNicConfiguration"
    subnet_id                     = data.azurerm_subnet.default.id
    public_ip_address_id          = ""
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "vault-worker-sga" {
  for_each = local.vault-workers

  network_interface_id      = azurerm_network_interface.vault-worker-interface[each.key].id
  network_security_group_id = data.azurerm_network_security_group.worker-nsg.id
}

resource "azurerm_virtual_machine" "vault-worker" {
  for_each = local.vault-workers

  name                  = each.key
  location              = "westeurope"
  resource_group_name   = "euwest-workers"
  network_interface_ids = [azurerm_network_interface.vault-worker-interface[each.key].id]
  vm_size               = "Standard_B2ms"

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
    ssh_keys {
      path     = "/home/${var.user_admin}/.ssh/authorized_keys"
      key_data = var.ssh_key_data_vsellier
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /root/.ssh",
      "echo ${var.ssh_key_data_ardumont} | sudo tee -a /root/.ssh/authorized_keys",
      "echo ${var.ssh_key_data_olasd} | sudo tee -a /root/.ssh/authorized_keys",
      "echo ${var.ssh_key_data_vsellier} | sudo tee -a /root/.ssh/authorized_keys",
    ]

    connection {
      type = "ssh"
      user = var.user_admin
      host = azurerm_network_interface.vault-worker-interface[each.key].private_ip_address
    }
  }

  provisioner "file" {
    content = templatefile("templates/firstboot.sh.tpl", {
      hostname        = each.key
      fqdn            = format("%s.euwest.azure.internal.softwareheritage.org", each.key),
      ip_address      = azurerm_network_interface.vault-worker-interface[each.key].private_ip_address,
      facter_subnet     = "azure_euwest"
      facter_deployment = "production"

      disk_setup      = {}
    })
    destination = var.firstboot_script

    connection {
      type = "ssh"
      user = "root"
      host = azurerm_network_interface.vault-worker-interface[each.key].private_ip_address
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
      host = azurerm_network_interface.vault-worker-interface[each.key].private_ip_address
    }
  }

  tags = {
    environment = "workers"
  }
}
