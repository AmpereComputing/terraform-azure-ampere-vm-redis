![Ampere Computing](https://avatars2.githubusercontent.com/u/34519842?s=400&u=1d29afaac44f477cbb0226139ec83f73faefe154&v=4)

# terraform-azure-ampere-vm

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## Description

Terraform code to launch a Ampere virtual machine on Microsoft Azure.

## Requirements

 * [Terraform](https://www.terraform.io/downloads.html)
 * [Microsoft Azure Account](https://azure.microsoft.com/en-us/)

## What exactly is Terraform doing

The goal of this code is to supply the minimal ammount of information to quickly have working Ampere virtual machine on ["Azure"](https://azure.microsoft.com/en-us/).
This instance is configured with cloud-config using the Azure metadata provider APIs.
It will automatically install a redis server and client.

Addtional tasks performed by this code:

* Dynamically creating sshkeys to use when logging into the instance.
* Creating necessary core networking configurations for the tenancy
* Rendering metadata to pass into the Ampere virtual machine
* Launch Ampere virtual machine with metadata and ssh keys.
* Output IP information to connect to the instance.

To get started clone this repository from GitHub locally.

## Configuration with terraform.tfvars

The easiest way to configure is to use a terraform.tfvars in the project directory.  
The following is an example of what terraform.tfvars should look like:

```
subscription_id = "12345678-abcd-1234-abcd-1234567890ab"
client_id = "87654321-dcba-4321-dcba-ba0987654321"
client_secret = "01234567-1234-1234-1234-1234567890ab"
tenant_id = "01234567-1234-abcd-1234-abcdef123456"
```

### Running Terraform

```
terraform init && terraform plan && terraform apply -auto-approve
```
### run-redis.sh

The same script is used on both client and server side, the script will install the necessary package and build redis and memtier. 


### Server side
#install and warmup N copies
./run-redis.sh --install --warmup --copies N

### Client side
#load the server with N memtier copies
#vary clients, pipeline, threads to get the best throughput 
./run-redis.sh --load --server <ip> --copies N --threads 1 --clients 4 --pipeline 32 --numruns 3

## References

* [Now in preview Azure virtual machines with ampere altra based processors](https://azure.microsoft.com/en-us/blog/now-in-preview-azure-virtual-machines-with-ampere-altra-armbased-processors)
* [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
* [Install the Azure CLI on Linux](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt)
* [Install Azure CLI on macOS](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-macos)
* [Install Azure CLI on Windows](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows)
* [Azure CLI authentication in Terraform](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli)
* [cloud-init support for virtual machines in Azure](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/using-cloud-init)