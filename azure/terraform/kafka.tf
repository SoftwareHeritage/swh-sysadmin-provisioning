variable "kafka_servers" {
  default = 6
}

variable "kafka_disk_size" {
  default = 8192
}

resource "azurerm_resource_group" "euwest-kafka" {
  name     = "euwest-kafka"
  location = "westeurope"

  tags = {
    environment = "Kafka"
  }
}

resource "azurerm_network_security_group" "kafka-public-nsg" {
  name                = "kafka-public-nsg"
  location            = "westeurope"
  resource_group_name = "euwest-kafka"

  security_rule {
    name                       = "kafka-icmp-inbound-public"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "kafka-tls-inbound-public"
    priority                   = 2000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9093"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }
}

resource "azurerm_public_ip" "kafka-public-ip" {
  count = var.kafka_servers

  name                = format("kafka%02d-ip", count.index + 1)
  domain_name_label   = format("swh-kafka%02d", count.index + 1)
  location            = "westeurope"
  resource_group_name = "euwest-kafka"
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "kafka-interface" {
  count = var.kafka_servers

  name                      = format("kafka%02d-interface", count.index + 1)
  location                  = "westeurope"
  resource_group_name       = "euwest-kafka"
  network_security_group_id = azurerm_network_security_group.kafka-public-nsg.id

  ip_configuration {
    name                          = "vaultNicConfiguration"
    subnet_id                     = data.azurerm_subnet.default.id
    public_ip_address_id          = azurerm_public_ip.kafka-public-ip[count.index].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "kafka-server" {
  count = var.kafka_servers

  name                  = format("kafka%02d", count.index + 1)
  location              = "westeurope"
  resource_group_name   = "euwest-kafka"
  network_interface_ids = [azurerm_network_interface.kafka-interface[count.index].id]
  vm_size               = "Standard_B2s"

  boot_diagnostics {
    enabled     = true
    storage_uri = var.boot_diagnostics_uri
  }

  storage_os_disk {
    name              = format("kafka%02d-osdisk", count.index + 1)
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_data_disk {
    name              = format("kafka%02d-datadisk", count.index + 1)
    caching           = "None"
    create_option     = "Empty"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = var.kafka_disk_size
    lun               = 1
  }

  storage_image_reference {
    publisher = "credativ"
    offer     = "Debian"
    sku       = "9"
    version   = "latest"
  }

  os_profile {
    computer_name  = format("kafka%02d", count.index + 1)
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
      host = azurerm_network_interface.kafka-interface[count.index].private_ip_address
    }
  }

  provisioner "file" {
    content = templatefile("templates/firstboot.sh.tpl", {
      hostname        = format("kafka%02d", count.index + 1),
      fqdn            = format("kafka%02d.euwest.azure.internal.softwareheritage.org", count.index + 1),
      ip_address      = azurerm_network_interface.kafka-interface[count.index].private_ip_address,
      facter_location = "azure_euwest",
      disk_setup = {
      disks = [{
        base_disk     = "/dev/sdc",
        mountpoint    = "/srv/kafka",
        filesystem    = "ext4",
        mount_options = "defaults",
      }]
      }
    })
    destination = var.firstboot_script

    connection {
      type = "ssh"
      user = "root"
      host = azurerm_network_interface.kafka-interface[count.index].private_ip_address
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
      host = azurerm_network_interface.kafka-interface[count.index].private_ip_address
    }
  }

  tags = {
    environment = "Kafka"
  }
}
