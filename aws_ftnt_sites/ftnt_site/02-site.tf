
locals {
    fgt = { for device in var.site_vars.devices : device.hostname => device if device.type == "fgt" }
    fmg = { for device in var.site_vars.devices : device.hostname => device if device.type == "fmg" }
    faz = { for device in var.site_vars.devices : device.hostname => device if device.type == "faz" }
    fts = { for device in var.site_vars.devices : device.hostname => device if device.type == "fts" }
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
