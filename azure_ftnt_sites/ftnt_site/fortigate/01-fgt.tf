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
    instance_type = try(var.vars.instance_type, "Standard_F4")
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

#resource "azurerm_dns_a_record" "external" {
#  name                = "${var.vars.hostname}.${var.site_name}"
#  zone_name           = "az.foletta.org"
#  resource_group_name = var.resource_group
#  ttl                 = 300
#  records             = ["8.8.8.8"]
#}


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

output "internal_ip" { value = azurerm_network_interface.internal.private_ip_address }


# az vm image terms accept --publisher fortinet --offer fortinet_fortigate-vm_v5 --plan fortinet_fg-vm

resource "azurerm_virtual_machine" "dev" {
  name                         = local.device_fqdn
  location                     = var.location
  resource_group_name          = var.resource_group
  network_interface_ids        = [azurerm_network_interface.external.id, azurerm_network_interface.internal.id]
  primary_network_interface_id = azurerm_network_interface.external.id
  vm_size                      = local.instance_type

  storage_image_reference {
    publisher = "fortinet"
    offer     = "fortinet_fortigate-vm_v5"
    sku       = "fortinet_fg-vm"
    version   = local.fortios
  }

  plan {
    publisher = "fortinet"
    name      = "fortinet_fg-vm"
    product   = "fortinet_fortigate-vm_v5"
  }

  storage_os_disk {
    name              = "os.${local.device_fqdn}"
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option     = "FromImage"
  }

  # Log data disks
  storage_data_disk {
    name              = "data.${local.device_fqdn}"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "30"
  }

  os_profile {
    computer_name  = var.vars.hostname
    admin_username = "provision"
    admin_password = "ASDASDkljlkj!!!123"
    custom_data    = data.template_file.init.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
    ssh_keys {
        key_data = var.public_key
        path = "/home/provision/.ssh/authorized_keys"
    }
  }

  tags = {
    environment = local.site_fqdn
  }
}

data "template_file" "init" {
  template = file("${path.module}/fgt_init.conf")
  vars = {
    hostname = local.device_fqdn
    license = file(local.license_file)
  }
}

