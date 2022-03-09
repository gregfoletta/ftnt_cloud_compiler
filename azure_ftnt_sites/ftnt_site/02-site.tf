
locals {
    fgt = { for device in var.site_vars.devices : device.hostname => device if device.type == "fgt" }
    fmg = { for device in var.site_vars.devices : device.hostname => device if device.type == "fmg" }
    faz = { for device in var.site_vars.devices : device.hostname => device if device.type == "faz" }
    fts = { for device in var.site_vars.devices : device.hostname => device if device.type == "fts" }
    fml = { for device in var.site_vars.devices : device.hostname => device if device.type == "fml" }
    fwb = { for device in var.site_vars.devices : device.hostname => device if device.type == "fwb" }
    fac = { for device in var.site_vars.devices : device.hostname => device if device.type == "fac" }
}

# For each site, create the site
module "fortigate" {
    for_each = local.fgt
    source = "./fortigate"
    site_name = var.site_name
    location = var.site_vars.location
    resource_group = azurerm_resource_group.site_rg.name
    vars = each.value
    external_subnet_id = azurerm_subnet.public_subnets[ each.value.interfaces.external.subnet ].id
    external_security_group = azurerm_network_security_group.fgt_external
    internal_subnet_id   = azurerm_subnet.private_subnets[ each.value.interfaces.internal.subnet ].id
    internal_security_group = azurerm_network_security_group.fgt_internal
    dns_root = data.azurerm_dns_zone.root
    public_key = var.public_key
}

#module "fortimanager" {
#    for_each = local.fmg
#    source = "./fortimanager"
#    site_name = var.site_name
#    fmg_vars = each.value
#    subnet_id = aws_subnet.private_subnets[ each.value.interfaces.mgmt.subnet ].id
#    dns_root = data.aws_route53_zone.root
#    az = data.aws_availability_zones.available.names[0]
#    key_name = var.key_name
#}
#
#module "fortianalyzer" {
#    for_each = local.faz
#    source = "./fortianalyzer"
#    site_name = var.site_name
#    faz_vars = each.value
#    subnet_id = aws_subnet.private_subnets[ each.value.interfaces.mgmt.subnet ].id
#    dns_root = data.aws_route53_zone.root
#    az = data.aws_availability_zones.available.names[0]
#    key_name = var.key_name
#}
#
#module "fortitester" {
#    for_each = local.fts
#    source = "./fortitester"
#    site_name = var.site_name
#    fts_vars = each.value
#    subnet_id = aws_subnet.private_subnets[ each.value.interfaces.mgmt.subnet ].id
#    dns_root = data.aws_route53_zone.root
#    az = data.aws_availability_zones.available.names[0]
#    key_name = var.key_name
#}
#
#module "fortimail" {
#    for_each = local.fml
#    source = "./fortimail"
#    site_name = var.site_name
#    vars = each.value
#    subnet_id = aws_subnet.private_subnets[ each.value.interfaces.mgmt.subnet ].id
#    dns_root = data.aws_route53_zone.root
#    az = data.aws_availability_zones.available.names[0]
#    key_name = var.key_name
#}
#
#module "fortiweb" {
#    for_each = local.fwb
#    source = "./fortiweb"
#    site_name = var.site_name
#    vars = each.value
#    subnet_id = aws_subnet.private_subnets[ each.value.interfaces.mgmt.subnet ].id
#    dns_root = data.aws_route53_zone.root
#    az = data.aws_availability_zones.available.names[0]
#    key_name = var.key_name
#}
#
#module "fortiauth" {
#    for_each = local.fac
#    source = "./fortiauth"
#    site_name = var.site_name
#    vars = each.value
#    subnet_id = aws_subnet.private_subnets[ each.value.interfaces.mgmt.subnet ].id
#    dns_root = data.aws_route53_zone.root
#    az = data.aws_availability_zones.available.names[0]
#    key_name = var.key_name
#}
