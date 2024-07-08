# Terraform Modules

This guide will walk you through creating and testing a Terraform configuration that sets up Azure resources using remote and local modules. 

Create a new file named `main.tf` inside this directory. This file will contain your main Terraform configuration.

In your `main.tf` file, add the following code to configure the Azure provider:

```hcl
provider "azurerm" {
  features {}
}
```

Create a `variables.tf` file to define the variables used in your configuration:

```hcl
variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}
```

Add the following code to your `main.tf` file to retrieve the resource group:

```hcl
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}
```

Add the following code to call the VNet module:

```hcl
module "vnet" {
  source  = "Azure/network/azurerm"
  version = "4.0.0"

  resource_group_name = data.azurerm_resource_group.rg.name
  vnet_name           = "module-vnet"
  address_space       = "10.1.0.0/20"
  subnet_prefixes     = ["10.1.0.0/24"]
  subnet_names        = ["sub1"]
}
```

Add the following code to retrieve the webserver image that we build on the previous labs:

```hcl
data "azurerm_image" "webserver" {
  name                = "webserver"
  resource_group_name = data.azurerm_resource_group.rg.name
}
```

We call the future module in the `modules/webserver` directory, add the following code:

```hcl
module "webservers" {
  source              = "./modules/webserver"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  vnet_subnet_id      = module.vnet.vnet_subnets[0].id
  source_image_id     = data.azurerm_image.webserver.id
  vm_size             = "Standard_B1ls"
  name                = "webserver"
}
```

Add the following code to call a module from a GitHub repository:

```hcl
module "github_module" {
  source = "github.com/sparks-tf-training/blob-storage"

  name                = "blobstorage"
  resource_group_name = data.azurerm_resource_group.rg.name
}
```

Write the module configuration in the `modules/webserver` directory. Create a `main.tf` file inside the `modules/webserver` directory. It should:

* Create a network interface with a public IP address.
* Create a virtual machine using the specified image and network interface.

Run the following command to initialize Terraform. This will download the necessary provider plugins and modules:

```bash
terraform init
```

Run the following command to apply the configuration. Terraform will prompt you to confirm before making any changes:

```bash
terraform apply
```

After the `terraform apply` command completes, verify that the resources have been created in the Azure portal.

We can now create multiple webserver by simply changing the `count` variable in the `main.tf` file:

```hcl
module "webservers" {
  source              = "./modules/webserver"
  count               = 2
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  vnet_subnet_id      = module.vnet.vnet_subnets[0].id
  source_image_id     = data.azurerm_image.webserver.id
  vm_size             = "Standard_B1ls"
  name                = "webserver"
}
```

We can also modulate the `vm_size` variable to create different sizes of virtual machines:

```hcl
locals {
  vm_sizes = ["Standard_B1ls", "Standard_B1ms"]
}

module "webservers" {
  source              = "./modules/webserver"
  count               = length(local.vm_sizes)
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  vnet_subnet_id      = module.vnet.vnet_subnets[0].id
  source_image_id     = data.azurerm_image.webserver.id
  vm_size             = local.vm_sizes[count.index]
  name                = "webserver"
}
```

After making these changes, run `terraform apply` to create the new resources.

---

## Summary

In this lab, you learned how to create and use Terraform modules to manage Azure resources. You created a main configuration file that called a VNet module and a webserver module. You also learned how to create multiple instances of a module by using the `count` parameter and how to pass different values to a module using variables.

