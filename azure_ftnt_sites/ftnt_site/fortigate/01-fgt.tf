variable "site_name" {}
variable "location" {}
variable "resource_group" {}
variable "vars" {}
variable "external_subnet_id" {}
variable "external_security_group" {}
variable "internal_subnet_id" {}
variable "internal_security_group" {}
variable "dns_root" {}
variable "public_key" {}

locals {
    device_fqdn = "${var.vars.hostname}.${var.site_name}.${var.dns_root.name}"
    site_fqdn = "${var.site_name}.${var.dns_root.name}"
    fortios = try(var.vars.fortios, "7.0.3")
    instance_type = try(var.vars.instance_type, "t2.small")
    license_file = try(var.vars.license_file, "licenses/${var.dns_root.name}/${var.site_name}/${var.vars.hostname}")
}


resource "azurerm_public_ip" "external" {
  name                = "ext.${local.device_fqdn}"
  location            = var.location
  resource_group_name = var.resource_group
  allocation_method   = "Static"

  tags = {
    environment = local.site_fqdn
  }
}

resource "azurerm_dns_a_record" "external" {
  name                = local.device_fqdn
  zone_name           = var.dns_root.name
  resource_group_name = var.resource_group
  ttl                 = 300
  records             = [azurerm_public_ip.external.ip_address]
}


resource "azurerm_network_interface" "external" {
  name                = "ext.${local.device_fqdn}"
  location            = var.location
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "ext.${local.device_fqdn}"
    subnet_id                     = var.external_subnet_id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.external.id
  }

  tags = {
    environment = local.site_fqdn
  }
}

resource "azurerm_network_interface" "internal" {
  name                 = "int.${local.device_fqdn}"
  location             = var.location
  resource_group_name  = var.resource_group
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "int.${local.device_fqdn}"
    subnet_id                     = var.internal_subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = local.site_fqdn
  }
}


#resource "azurerm_virtual_machine" "dev" {
#  name                         = "fgtvm"
#  location                     = var.location
#  resource_group_name          = azurerm_resource_group.myterraformgroup.name
#  network_interface_ids        = [azurerm_network_interface.fgtport1.id, azurerm_network_interface.fgtport2.id]
#  primary_network_interface_id = azurerm_network_interface.fgtport1.id
#  vm_size                      = var.size
#  storage_image_reference {
#    publisher = var.publisher
#    offer     = var.fgtoffer
#    sku       = var.license_type == "byol" ? var.fgtsku["byol"] : var.fgtsku["payg"]
#    version   = var.fgtversion
#  }
#
#  plan {
#    publisher = "fortinet"
#    name      = var.license_type == "byol" ? var.fgtsku["byol"] : var.fgtsku["payg"]
#    product   = var.fgtoffer
#  }
#
#  storage_os_disk {
#    name              = "osDisk"
#    caching           = "ReadWrite"
#    managed_disk_type = "Standard_LRS"
#    create_option     = "FromImage"
#  }
#
#  # Log data disks
#  storage_data_disk {
#    name              = "fgtvmdatadisk"
#    managed_disk_type = "Standard_LRS"
#    create_option     = "Empty"
#    lun               = 0
#    disk_size_gb      = "30"
#  }
#
#  os_profile {
#    computer_name  = "fgtvm"
#    admin_username = var.adminusername
#    admin_password = var.adminpassword
#    custom_data    = data.template_file.fgtvm.rendered
#  }
#
#  os_profile_linux_config {
#    disable_password_authentication = false
#  }
#
#  boot_diagnostics {
#    enabled     = true
#    storage_uri = azurerm_storage_account.fgtstorageaccount.primary_blob_endpoint
#  }
#
#  tags = {
#    environment = "Terraform Demo"
#  }
#}
#
#data "template_file" "fgtvm" {
#  template = file(var.bootstrap-fgtvm)
#  vars = {
#    type         = var.license_type
#    license_file = var.license
#  }
#}
#
