terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.0"
    }
  }
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "terraform-training"
}

variable "location" {
  description = "The location of the resources"
  type        = string
  default     = "France Central"
}

variable "vnet_subnet_id" {
  description = "The ID of the subnet"
  type        = string
}

variable "source_image_id" {
  description = "The ID of the source image"
  type        = string
}

variable "vm_size" {
  description = "The size of the VM"
  type        = string
  default     = "Standard_B1ls"
}

variable "admin_username" {
  description = "The username of the VM"
  type        = string
  default     = "webserver"
}

variable "name" {
  description = "The name of the VM"
  type        = string
  default     = "webserver"
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_public_ip" "pip" {
  name                = "${var.name}-pip"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.name}-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    primary                       = true
    name                          = "public"
    subnet_id                     = var.vnet_subnet_id
    public_ip_address_id          = azurerm_public_ip.pip.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "azurerm_virtual_machine" "webserver" {
  name                = "${var.name}-vm"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]
  vm_size                       = var.vm_size
  delete_os_disk_on_termination = true

  storage_image_reference {
    id = var.source_image_id
  }

  storage_os_disk {
    name              = "webserver-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.name}-vm"
    admin_username = var.admin_username
    admin_password = random_password.password.result
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

output "ip" {
  value = azurerm_public_ip.pip.ip_address
}

output "username" {
  value = var.admin_username
}

output "password" {
  value = random_password.password.result
}