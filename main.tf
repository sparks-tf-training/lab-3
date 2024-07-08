provider "azurerm" {
  features {}
}

# Define the resource group
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# Call the VNet module from a remote source
module "vnet" {
  source  = "Azure/network/azurerm"
  version = "4.0.0"

  resource_group_name = data.azurerm_resource_group.rg.name
  vnet_name           = "module-vnet"
  address_space       = "10.1.0.0/20"
  subnet_prefixes     = ["10.1.0.0/24"]
  subnet_names        = ["sub1"]
}


data "azurerm_image" "webserver" {
  name                = "webserver"
  resource_group_name = data.azurerm_resource_group.rg.name
}


# Call the webserver module (local module)
module "webservers" {
  source              = "./modules/webserver"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  vnet_subnet_id      = module.vnet.vnet_subnets.0
  source_image_id     = data.azurerm_image.webserver.id
  vm_size             = "Standard_B1ls"
  name                = "webserver"
}

# Call the module from a GitHub repository
module "github_module" {
  source = "github.com/sparks-tf-training/blob-module"

  name                = "module240708"
  resource_group_name = data.azurerm_resource_group.rg.name
}