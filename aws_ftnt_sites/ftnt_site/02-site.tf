
locals {
    fgt = { for device in var.site_vars.devices : device.hostname => device if device.type == "fgt" }
    fmg = { for device in var.site_vars.devices : device.hostname => device if device.type == "fmg" }
    faz = { for device in var.site_vars.devices : device.hostname => device if device.type == "faz" }
    fts = { for device in var.site_vars.devices : device.hostname => device if device.type == "fts" }
    fml = { for device in var.site_vars.devices : device.hostname => device if device.type == "fml" }
    fwb = { for device in var.site_vars.devices : device.hostname => device if device.type == "fwb" }
    fac = { for device in var.site_vars.devices : device.hostname => device if device.type == "fac" }
    fpc = { for device in var.site_vars.devices : device.hostname => device if device.type == "fpc" }
}

# For each site, create the site
module "fortigate" {
    for_each = local.fgt
    source = "./fortigate"
    site_name = var.site_name
    fgt_vars = each.value
    external_subnet_id = aws_subnet.public_subnets[ each.value.interfaces.external.subnet ].id
    external_security_group = aws_security_group.fgt_external
    internal_subnet_id   = aws_subnet.private_subnets[ each.value.interfaces.internal.subnet ].id
    internal_security_group = aws_security_group.fgt_internal
    dns_root = data.aws_route53_zone.root
    az = data.aws_availability_zones.available.names[0]
    key_name = var.key_name
}

module "fortimanager" {
    for_each = local.fmg
    source = "./fortimanager"
    site_name = var.site_name
    fmg_vars = each.value
    subnet_id = aws_subnet.private_subnets[ each.value.interfaces.mgmt.subnet ].id
    dns_root = data.aws_route53_zone.root
    az = data.aws_availability_zones.available.names[0]
    key_name = var.key_name
}

module "fortianalyzer" {
    for_each = local.faz
    source = "./fortianalyzer"
    site_name = var.site_name
    faz_vars = each.value
    subnet_id = aws_subnet.private_subnets[ each.value.interfaces.mgmt.subnet ].id
    dns_root = data.aws_route53_zone.root
    az = data.aws_availability_zones.available.names[0]
    key_name = var.key_name
}

module "fortitester" {
    for_each = local.fts
    source = "./fortitester"
    site_name = var.site_name
    fts_vars = each.value
    subnet_id = aws_subnet.private_subnets[ each.value.interfaces.mgmt.subnet ].id
    dns_root = data.aws_route53_zone.root
    az = data.aws_availability_zones.available.names[0]
    key_name = var.key_name
}

module "fortimail" {
    for_each = local.fml
    source = "./fortimail"
    site_name = var.site_name
    vars = each.value
    subnet_id = aws_subnet.private_subnets[ each.value.interfaces.mgmt.subnet ].id
    dns_root = data.aws_route53_zone.root
    az = data.aws_availability_zones.available.names[0]
    key_name = var.key_name
}

module "fortiweb" {
    for_each = local.fwb
    source = "./fortiweb"
    site_name = var.site_name
    vars = each.value
    subnet_id = aws_subnet.private_subnets[ each.value.interfaces.mgmt.subnet ].id
    dns_root = data.aws_route53_zone.root
    az = data.aws_availability_zones.available.names[0]
    key_name = var.key_name
}

module "fortiauth" {
    for_each = local.fac
    source = "./fortiauth"
    site_name = var.site_name
    vars = each.value
    subnet_id = aws_subnet.private_subnets[ each.value.interfaces.mgmt.subnet ].id
    dns_root = data.aws_route53_zone.root
    az = data.aws_availability_zones.available.names[0]
    key_name = var.key_name
}

module "fortiportal" {
    for_each = local.fpc
    source = "./fortiportal"
    site_name = var.site_name
    vars = each.value
    subnet_id = aws_subnet.private_subnets[ each.value.interfaces.mgmt.subnet ].id
    db_subnet_id = aws_subnet.private_subnets[ each.value.interfaces.db_a.subnet ].id
    dns_root = data.aws_route53_zone.root
    az = data.aws_availability_zones.available.names[0]
    key_name = var.key_name
}
