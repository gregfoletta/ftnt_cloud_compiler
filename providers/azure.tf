terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 2.98.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "azure_ftnt_sites" {
    sites = var.sites   
    source = "./azure_ftnt_sites"
}

output "rsa_private_key" { 
    value = module.azure_ftnt_sites.rsa_private_key
    sensitive = true
}
