variable "site_name" {}
variable "fgt_vars" {}
variable "external_subnet_id" {}
variable "external_security_group" {}
variable "internal_subnet_id" {}
variable "internal_security_group" {}
variable "dns_root" {}
variable "az" {}
variable "key_name" {}

locals {
    name_suffix = "${var.fgt_vars.hostname}.${var.site_name}.${var.dns_root.name}"
    fortios = try(var.fgt_vars.fortios, "7.0.3")
    instance_type = try(var.fgt_vars.instance_type, "t2.small")
    license_file = try(var.fgt_vars.license_file, "licenses/${var.dns_root.name}/${var.site_name}/${var.fgt_vars.hostname}")
}

data "aws_region" "current" {}

resource "aws_network_interface" "external" {
    subnet_id   = var.external_subnet_id
    source_dest_check = "false"
    tags = {
        Name = "ext.${local.name_suffix}"
    }
}


resource "aws_network_interface" "internal" {
    subnet_id   = var.internal_subnet_id
    source_dest_check = "false"
    tags = {
        Name = "int.${local.name_suffix}"
    }
}

output "external_interface" { value = aws_network_interface.external }
output "internal_interface" { value = aws_network_interface.internal }

resource "aws_eip" "fgt_external" {
    depends_on        = [aws_instance.fgt]
    vpc               = true
    network_interface = aws_network_interface.external.id
    tags = {
        Name = "${local.name_suffix}"
    }
}

resource "aws_route53_record" "fgt_external" {
  zone_id = var.dns_root.zone_id
  name    = "${local.name_suffix}"
  type    = "A"
  ttl     = "60"
  records = [aws_eip.fgt_external.public_ip]
}


resource "aws_network_interface_sg_attachment" "fgt_external" {
  depends_on           = [aws_network_interface.external]
  security_group_id    = var.external_security_group.id
  network_interface_id = aws_network_interface.external.id
}

resource "aws_network_interface_sg_attachment" "fgt_internal" {
  depends_on           = [aws_network_interface.internal]
  security_group_id    = var.internal_security_group.id
  network_interface_id = aws_network_interface.internal.id
}

data "template_file" "fgt_init_config" {
  template = file("${path.module}/fgt_init.conf")
  vars = {
    license =   file(local.license_file)
    hostname = local.name_suffix
  }
}

resource "aws_instance" "fgt" {
    ami               = local.amis[data.aws_region.current.name][local.fortios]
    instance_type     = local.instance_type
    availability_zone = var.az
    key_name          = var.key_name
    user_data         = data.template_file.fgt_init_config.rendered

    root_block_device {
        volume_type = "standard"
        volume_size = "2"
    }

    ebs_block_device {
        device_name = "/dev/sdb"
        volume_size = "30"
        volume_type = "standard"
    }

    network_interface {
        network_interface_id = aws_network_interface.external.id
        device_index         = 0
    }

    network_interface {
        network_interface_id = aws_network_interface.internal.id
        device_index         = 1
    }

    tags = {
        Name = "${local.name_suffix}"
    }
}

output "fgt" { value = aws_instance.fgt }
