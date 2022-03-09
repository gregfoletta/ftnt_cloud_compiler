variable "site_name" {}
variable "site_vars" {}
variable "public_key" {}

data "azurerm_dns_zone" "root" {
    name         = var.site_vars.dns_root
}
