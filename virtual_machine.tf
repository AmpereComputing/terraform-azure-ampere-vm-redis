# Define VMs
resource "azurerm_virtual_machine" "vm" {
  name                             = "vm${count.index}"
  location                         = var.location
  resource_group_name              = azurerm_resource_group.rg.name
  vm_size                          = var.vm_size
  network_interface_ids            = ["${element(azurerm_network_interface.nic.*.id, count.index)}"]
  delete_data_disks_on_termination = true
  delete_os_disk_on_termination    = true
  count                            = var.azure_vm_count
  depends_on                       = [azurerm_network_interface.nic]

  storage_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  storage_os_disk {
    name          = "${lookup(var.osdisk, count.index)}"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = format("${var.instance_prefix}-%02d", count.index+1)
    admin_username = var.admin_username
    admin_password = var.admin_password
    custom_data    = "${base64encode(data.template_file.cloud_config.rendered)}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
       path     = var.ssh_key_path
       key_data = tls_private_key.azure.public_key_openssh
    }
  }

}
