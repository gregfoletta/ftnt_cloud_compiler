locals {
    fgt = { for device in var.site_vars.devices : device.hostname => device if device.type == "fgt" }
    ftnt_dev = { for device in var.site_vars.devices : device.hostname => device if device.type != "fgt" }
}

# For each site, create the site
module "fortigate" {
    for_each = local.fgt
    source = "./fortigate"
    site_name = var.site_name
    fgt_vars = each.value
    site_subnets = aws_subnet.subnets
    external_security_group = aws_security_group.external
    internal_security_group = aws_security_group.internal
    dns_root = data.aws_route53_zone.root
    az = data.aws_availability_zones.available.names[0]
    key_name = var.key_name
}

module "ftnt_device" {
    for_each = local.ftnt_dev
    source = "./fortinet_device"
    site_name = var.site_name
    config = each.value
    site_subnets = aws_subnet.subnets
    security_group = aws_security_group.external
    dns_root = data.aws_route53_zone.root
    az = data.aws_availability_zones.available.names[0]
    key_name = var.key_name
}
