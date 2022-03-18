variable "site_name" {}
variable "fgt_vars" {}
variable "site_subnets" {}
variable "external_security_group" {}
variable "internal_security_group" {}
variable "dns_root" {}
variable "az" {}
variable "key_name" {}

locals {
    device_fqdn = "${var.fgt_vars.hostname}.${var.site_name}.${var.dns_root.name}"
    fortios = try(var.fgt_vars.fortios, "7.0.3")
    instance_type = try(var.fgt_vars.instance_type, "t2.small")
    license_file = try(var.fgt_vars.license_file, "licenses/${var.dns_root.name}/${var.site_name}/${var.fgt_vars.hostname}")
}


data "aws_region" "current" {}

resource "aws_network_interface" "interfaces" {
    for_each = { 
        for idx, int in var.fgt_vars.interfaces : idx => int
    }
    subnet_id   = var.site_subnets[ each.value.subnet ].id
    source_dest_check = "false"

    tags = {
        Name = "${each.value.name}.${local.device_fqdn}"
    }
}

// We attach the first interface statically in the 'aws_instance' section
// otherwise we get the error: "VPCResourceNotSpecified: The specified 
// instance type can only be used in a VPC. A subnet ID or network interface ID 
// is required to carry out the request."

resource "aws_network_interface_attachment" "nic_attach" {
  for_each = {
    for k, v in aws_network_interface.interfaces : k => v if k > 0
  }
  instance_id          = aws_instance.fgt.id
  network_interface_id = each.value.id
  device_index         = each.key
}


// The external and internal interface are based on their place in the 
// list of interfaces. We return these from the module so that the routing
output "external_interface" { value = aws_network_interface.interfaces["0"] }
output "internal_interface" { value = aws_network_interface.interfaces["1"] }

resource "aws_eip" "fgt_external" {
    depends_on        = [aws_instance.fgt]
    vpc               = true
    network_interface = aws_network_interface.interfaces["0"].id
    tags = {
        Name = "${local.device_fqdn}"
    }
}

resource "aws_route53_record" "fgt_external" {
  zone_id = var.dns_root.zone_id
  name    = "${local.device_fqdn}"
  type    = "A"
  ttl     = "60"
  records = [aws_eip.fgt_external.public_ip]
}


resource "aws_network_interface_sg_attachment" "external" {
  depends_on           = [aws_network_interface.interfaces[0]]
  security_group_id    = var.external_security_group.id
  network_interface_id = aws_network_interface.interfaces[0].id
}

resource "aws_network_interface_sg_attachment" "internal" {
  for_each = {
    for idx, v in aws_network_interface.interfaces : idx => v if idx > 0
  }
  security_group_id    = var.internal_security_group.id
  network_interface_id = each.value.id
}

data "template_file" "fgt_init_config" {
  template = file("${path.module}/fgt_init.conf")
  vars = {
    license =   file(local.license_file)
    hostname = local.device_fqdn
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

        tags = {
            Name = "os.${local.device_fqdn}"
        }
    }

    ebs_block_device {
        device_name = "/dev/sdb"
        volume_size = "30"
        volume_type = "standard"

        tags = {
            Name = "secondary.${local.device_fqdn}"
        }
    }

    network_interface {
        network_interface_id = aws_network_interface.interfaces["0"].id
        device_index         = 0
    }

    tags = {
        Name = "${local.device_fqdn}"
    }
}

output "fgt" { value = aws_instance.fgt }
