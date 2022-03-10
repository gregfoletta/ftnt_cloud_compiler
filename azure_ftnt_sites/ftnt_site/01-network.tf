locals {
    site_fqdn = "${var.site_name}.${data.azurerm_dns_zone.root.name}"
}

resource "azurerm_resource_group" "site_rg" {
  name     = local.site_fqdn
  location = var.site_vars.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = local.site_fqdn
  address_space       = [var.site_vars.cidr]
  location            = var.site_vars.location
  resource_group_name = azurerm_resource_group.site_rg.name

  tags = {
    site = local.site_fqdn
  }
}

resource "azurerm_route_table" "private" {
  resource_group_name = azurerm_resource_group.site_rg.name
  location            = var.site_vars.location
  depends_on          = [module.fortigate]
  name                = "private.${local.site_fqdn}"
}

locals {
    first_fgt = module.fortigate[ keys(local.fgt)[0] ]
}

resource "azurerm_route" "default" {
  resource_group_name = azurerm_resource_group.site_rg.name
  name                   = "default.private.${local.site_fqdn}"
  route_table_name       = azurerm_route_table.private.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.first_fgt.internal_ip
}


resource "azurerm_subnet" "public_subnets" {
  for_each = var.site_vars.networks.public
  resource_group_name = azurerm_resource_group.site_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  name                 = "${each.key}.public.${local.site_fqdn}"
  address_prefixes     = [cidrsubnet( var.site_vars.cidr, each.value[0], each.value[1] )]
}

resource "azurerm_subnet" "private_subnets" {
  for_each = var.site_vars.networks.private
  resource_group_name = azurerm_resource_group.site_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  name                 = "${each.key}.private.${local.site_fqdn}"
  address_prefixes     = [ cidrsubnet( var.site_vars.cidr, each.value.subnet[0], each.value.subnet[1] ) ]
}

resource "azurerm_subnet_route_table_association" "private_associate" {
   for_each = azurerm_subnet.private_subnets
   subnet_id      = each.value.id
   route_table_id = azurerm_route_table.private.id
}


resource "azurerm_network_security_group" "fgt_external" {
  name        = "external.sg.${local.site_fqdn}"
  location            = var.site_vars.location
  resource_group_name = azurerm_resource_group.site_rg.name
}


resource "azurerm_network_security_rule" "fgt_external_outbound" {
  name                       = "Outbound"
  priority                   = 256 
  direction                  = "Outbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "*"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name = azurerm_resource_group.site_rg.name
  network_security_group_name = azurerm_network_security_group.fgt_external.name
}


resource "azurerm_network_security_rule" "fgt_external_inbound" {
  name                       = "Inbound"
  priority                   = 256 
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "*"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name = azurerm_resource_group.site_rg.name
  network_security_group_name = azurerm_network_security_group.fgt_external.name
}


// Internal security group
resource "azurerm_network_security_group" "fgt_internal" {
  name        = "external.sg.${local.site_fqdn}"
  location            = var.site_vars.location
  resource_group_name = azurerm_resource_group.site_rg.name
}

resource "azurerm_network_security_rule" "fgt_internal_outbound" {
  name                       = "Outbound"
  priority                   = 256 
  direction                  = "Outbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "*"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name = azurerm_resource_group.site_rg.name
  network_security_group_name = azurerm_network_security_group.fgt_internal.name
}


resource "azurerm_network_security_rule" "fgt_internal_inbound" {
  name                       = "Inbound"
  priority                   = 256 
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "*"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name = azurerm_resource_group.site_rg.name
  network_security_group_name = azurerm_network_security_group.fgt_internal.name
}
