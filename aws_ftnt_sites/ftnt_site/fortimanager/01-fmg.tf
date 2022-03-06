variable "site_name" {}
variable "fmg_vars" {}
variable "subnet_id" {}
variable "dns_root" {}
variable "az" {}
variable "key_name" {}

locals {
    name_suffix = "${var.fmg_vars.hostname}.${var.site_name}.${var.dns_root.name}"
    fortios = try(var.fmg_vars.fortios, "7.0.3")
    instance_type = try(var.fmg_vars.fortios, "m4.large")
    license_file = try(var.fmg_vars.license_file, "licenses/${var.dns_root.name}/${var.site_name}/${var.fmg_vars.hostname}")
}

data "aws_region" "current" {}

resource "aws_network_interface" "fmg_mgmt" {
    subnet_id   = var.subnet_id
    tags = {
        Name = "mgmt.${local.name_suffix}"
    }
}

data "aws_network_interface" "fmg_mgmt" {
    depends_on           = [aws_instance.fmg]
    id = aws_network_interface.fmg_mgmt.id
}


resource "aws_route53_record" "fgt_external" {
  zone_id = var.dns_root.zone_id
  name    = "${local.name_suffix}"
  type    = "A"
  ttl     = "60"
  records = [data.aws_network_interface.fmg_mgmt.association[0].public_ip]
}

#resource "aws_network_interface_sg_attachment" "fmg_external" {
#  depends_on           = [aws_network_interface.fmg_mgmt]
#  security_group_id    = var.security_group.id
#  network_interface_id = aws_network_interface.fmg_mgmt.id
#}

data "template_file" "fmg_init_config" {
  template = file("${path.module}/fmg_init.conf")
  vars = {
    license =   file(local.license_file)
    hostname = "${local.name_suffix}"
  }
}

resource "aws_instance" "fmg" {
    ami               = local.amis[data.aws_region.current.name][local.fortios]
    instance_type     = local.instance_type
    availability_zone = var.az
    key_name          = var.key_name
    user_data         = data.template_file.fmg_init_config.rendered

    root_block_device {
        volume_type = "standard"
        volume_size = "6"
    }

    ebs_block_device {
        device_name = "/dev/sdb"
        volume_size = "80"
        volume_type = "standard"
    }

    network_interface {
        network_interface_id = aws_network_interface.fmg_mgmt.id
        device_index         = 0
    }

    tags = {
        Name = "${local.name_suffix}"
    }
}
