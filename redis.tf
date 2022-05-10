

locals {
    redis_server           = data.azurerm_public_ip.pip.0.ip_address
    redis_server_privateip = azurerm_network_interface.nic.0.private_ip_address
    redis_client           = data.azurerm_public_ip.pip.1.ip_address
    copies                 = var.run_redis_copies
}

resource "null_resource" "run_redis_file" {
  count    = var.azure_vm_count
  triggers = {
    instance_public_ip = element(data.azurerm_public_ip.pip.*.ip_address, count.index)
  }
  connection {
    type        = "ssh"
    host        = element(data.azurerm_public_ip.pip.*.ip_address, count.index)
    user        = "ubuntu"
    private_key = tls_private_key.azure.private_key_pem
  }

  provisioner "file" {
    content = file("${path.module}/scripts/run-redis.sh")
    destination = "/home/ubuntu/run-redis.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /home/ubuntu/run-redis.sh /opt/run-redis.sh",
      "sudo chmod 0777 /opt/run-redis.sh",
    ]
  }
}
resource "null_resource" "redis_server" {
  triggers = {
    instance_public_ip = element(data.azurerm_public_ip.pip.*.ip_address, 0)
  }
  depends_on = [ null_resource.run_redis_file ]
  connection {
    type        = "ssh"
    host        = element(data.azurerm_public_ip.pip.*.ip_address, 0)
    user        = "ubuntu"
    private_key = tls_private_key.azure.private_key_pem
  }

  provisioner "remote-exec" {
     inline = [
       "cloud-init status --wait"
     ]
  }

  provisioner "remote-exec" {
    inline = [
      "/opt/run-redis.sh --install --warmup --copies ${var.run_redis_copies}"
    ]
  }
}

resource "null_resource" "redis_client" {
  triggers = {
    instance_public_ip = element(data.azurerm_public_ip.pip.*.ip_address, 1)
  }
  depends_on = [ null_resource.run_redis_file, null_resource.redis_server ]
  connection {
    type        = "ssh"
    host        = element(data.azurerm_public_ip.pip.*.ip_address, 1)
    user        = "ubuntu"
    private_key = tls_private_key.azure.private_key_pem
  }

  provisioner "remote-exec" {
     inline = [
       "cloud-init status --wait"
     ]
  }

  provisioner "remote-exec" {
    inline = [
    # "/opt/run-redis.sh --load --server ${azurerm_virtual_machine.vm.0.private_ip_address} --copies ${var.run_redis_copies} --threads 1 --clients 4 --pipeline 32 --numruns 3"
      "/opt/run-redis.sh --load --server ${local.redis_server_privateip} --copies ${var.run_redis_copies} --threads 1 --clients 4 --pipeline 32 --numruns 3"

    ]
  }
}
