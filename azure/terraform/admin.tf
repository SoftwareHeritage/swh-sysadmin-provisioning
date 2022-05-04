# Define a new resource for the admin nodes
# matching what we names elsewhere "euwest-${resource}"
variable "backup_servers" {
  default = 1
}

variable "backup_disks_per_server" {
  default = 1
}

# Size in gb
variable "backup_disk_size" {
  default = 256
}

locals {
  backup_servers = {
    for i in range(var.backup_servers) :
    format("backup%02d", i + 1) => {
      backupdisks = {
        for i in range(var.backup_disks_per_server) :
        format("datadisk%02d", i + 1) => {
          lun  = i + 1
          path = format("/dev/disk/azure/scsi1/lun%d", i + 1)
        }
      }
    }
  }
}

resource "azurerm_resource_group" "euwest-admin" {
  name     = "euwest-admin"
  location = "westeurope"

  tags = {
    environment = "SWH Admin"
  }
}

resource "azurerm_network_interface" "backup-interface" {
  for_each = local.backup_servers

  name                = format("%s-interface", each.key)
  location            = "westeurope"
  resource_group_name = azurerm_resource_group.euwest-admin.name

  ip_configuration {
    name                          = "backupNicConfiguration"
    subnet_id                     = data.azurerm_subnet.default.id
    public_ip_address_id          = ""
    private_ip_address            = "192.168.200.50"
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_network_interface_security_group_association" "backup-interface-sga" {
  for_each = local.backup_servers

  network_interface_id      = azurerm_network_interface.backup-interface[each.key].id
  network_security_group_id = data.azurerm_network_security_group.worker-nsg.id
}

resource "azurerm_virtual_machine" "backup-server" {
  for_each = local.backup_servers

  name                  = each.key
  location              = "westeurope"
  resource_group_name   = azurerm_resource_group.euwest-admin.name
  network_interface_ids = [azurerm_network_interface.backup-interface[each.key].id]
  vm_size               = "Standard_B2s"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = false

  boot_diagnostics {
    enabled     = true
    storage_uri = var.boot_diagnostics_uri
  }

  storage_os_disk {
    name              = format("%s-osdisk", each.key)
    caching           = "None"
    create_option     = "FromImage"
    disk_size_gb      = 32
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "debian"
    offer     = "debian-11"
    sku       = "11"
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

  dynamic "storage_data_disk" {
    for_each = each.value.backupdisks

    content {
      name              = format("%s-%s", each.key, storage_data_disk.key)
      caching           = "None"
      create_option     = "Empty"
      managed_disk_type = "Standard_LRS"
      disk_size_gb      = var.backup_disk_size
      lun               = storage_data_disk.value.lun
    }
  }

  # Configuring the root user
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /root/.ssh", # just in case
      # Remove the content populated by the azure provisionning
      # blocking the connection as root
      "sudo rm -v /root/.ssh/authorized_keys",
      "echo ${var.ssh_key_data_ardumont} | sudo tee -a /root/.ssh/authorized_keys",
      "echo ${var.ssh_key_data_olasd} | sudo tee -a /root/.ssh/authorized_keys",
      "echo ${var.ssh_key_data_vsellier} | sudo tee -a /root/.ssh/authorized_keys",
    ]

    connection {
      type = "ssh"
      user = var.user_admin
      host = azurerm_network_interface.backup-interface[each.key].private_ip_address
    }
  }

  # Copy the initial configuration script
  provisioner "file" {
    content = templatefile("templates/firstboot.sh.tpl", {
      hostname          = each.key
      fqdn              = format("%s.euwest.azure.internal.softwareheritage.org", each.key),
      ip_address        = azurerm_network_interface.backup-interface[each.key].private_ip_address,
      facter_subnet     = "azure_euwest"
      facter_deployment = "admin"
      disk_setup        = {}
    })
    destination = var.firstboot_script

    connection {
      type = "ssh"
      user = "root"
      host = azurerm_network_interface.backup-interface[each.key].private_ip_address
    }
  }

  # Remove the tmpadmin user
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
      host = azurerm_network_interface.backup-interface[each.key].private_ip_address
    }
  }

  lifecycle {
    ignore_changes = [ storage_data_disk[0].create_option ]
  }

  tags = {
    environment = "Backup"
  }
}
