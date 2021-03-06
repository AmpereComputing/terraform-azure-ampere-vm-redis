variable "ssh_key_file" {
  default = "/etc/ansible/keys/.ssh/id_rsa"
}

variable "azure_vm_count" {
  default = 2
}

variable "instance_prefix" {
  description = "Name prefix for vm instances"
  default = "azure-ampere-vm"
}

variable "resource_group" {
  description = "The name of the resource group in which to create the virtual network."
  default     = "Terraform-Ampere-on-Azure"
}

variable "rg_prefix" {
  description = "The shortened abbreviation to represent your resource group that will go on the front of some resources."
  default     = "rg"
}

#variable "hostname" {
#  description = "VM name referenced also in storage-related names."
#
#  default = {
#    "0" = "az01"
#    "1" = "az02"
#  }
#}

variable "osdisk" {
  description = "VM name referenced also in storage-related names."

  default = {
    "0" = "osdisk1"
    "1" = "osdisk2"
  }
}

variable "location" {
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
  default     = "westus2"
}

variable "virtual_network_name" {
  description = "The name for the virtual network."
  default     = "vnet"
}

variable "address_space" {
  description = "The address space that is used by the virtual network. You can supply more than one address space. Changing this forces a new resource to be created."
  default     = "10.2.0.0/16"
}

variable "subnet_prefix" {
  description = "The address prefix to use for the subnet."
  default     = "10.2.1.0/24"
}

variable "vm_size" {
  description = "Specifies the size of the virtual machine."
  default     = "Standard_D16ps_v5"
# default     = "Basic_A0"
}

variable "image_publisher" {
  description = "name of the publisher of the image (az vm image list)"
  default     = "canonical"
}

variable "image_offer" {
  description = "the name of the offer (az vm image list)"
  default     = "0001-com-ubuntu-server-arm-preview-focal"
}

variable "image_sku" {
  description = "image sku to apply (az vm image list)"
  default     = "20_04-LTS"
}

variable "image_version" {
  description = "version of the image to apply (az vm image list)"
  default     = "latest"
}
variable "admin_username" {
  description = "administrator user name"
  default     = "ubuntu"
}

variable "admin_password" {
  description = "administrator password"
  default     = "ubuntu"
}

variable "tags" {
  type = map

  default = {
    environment = "Public Cloud"
  }
}
variable subscription_id {}
variable tenant_id {}
variable ssh_key_path {
  default = "/home/ubuntu/.ssh/authorized_keys"
}
variable "run_redis_copies" {
    default = "1"
    description = "Value for copies which is used when running run-redis.sh"
    type    = string
}
