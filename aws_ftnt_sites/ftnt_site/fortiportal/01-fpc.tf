variable "site_name" {}
variable "vars" {}
variable "subnet_id" {}
variable "dns_root" {}
variable "az" {}
variable "key_name" {}

locals {
    device_fqdn = "${var.vars.hostname}.${var.site_name}.${var.dns_root.name}"
    fortios = try(var.vars.fortios, "6.0.9")
    instance_type = try(var.vars.fortios, "m4.large")
    disk_sizes = [ local.defaults[ var.config.type ].disks[0], local.defaults[ var.config.type ].disks[1] ]
    license_file = try(var.vars.license_file, "licenses/${var.dns_root.name}/${var.site_name}/${var.vars.hostname}")
}

data "aws_region" "current" {}

// We need the data from the subnets to get the 'cidr_block' (which is not
// in the resource itself. We use this as part of the calculation for the
// host IP address on the network interface
data "aws_subnet" "subnets" {
  for_each = var.site_subnets
  id = each.value.id
}

resource "aws_network_interface" "interfaces" {
    for_each = { 
        for idx, int in var.config.interfaces : idx => int
    }
    subnet_id   = var.site_subnets[ each.value.subnet ].id

    // This is a bit of a mouthful, but we get the 'cidr_block' from the aws_subnet data
    // (Keyed by the subnet name. We then use the 'ipv4_index' from the configuration to
    // determine the address of the network itnerface. 
    // This is required for devices like the FMG or FAZ which are licensed based on the 
    // interface IP address
    //
    // If there is no 'ipv4_index' variable present, an empty list is provided and 
    // a random IP address will be assigned

    private_ips = try( [ cidrhost(data.aws_subnet.subnets[ each.value.subnet ].cidr_block, each.value.ipv4_index), ], [ ]) 


    tags = {
        Name = "${each.value.name}.${local.device_fqdn}"
    }
}

// We attach the first interface statically in the 'aws_instance' section
// otherwise we get the error: "VPCResourceNotSpecified: The specified 
// instance type can only be used in a VPC. A subnet ID or network interface ID 
// is required to carry out the request."

data "aws_network_interface" "fpc" {
    depends_on           = [aws_instance.fpc]
    id = aws_network_interface.interfaces["0"].id
}

resource "aws_network_interface_attachment" "nic_attach" {
  for_each = {
    for k, v in aws_network_interface.interfaces : k => v if k > 0
  }
  instance_id          = aws_instance.ftnt_dev.id
  network_interface_id = each.value.id
  device_index         = each.key
}

resource "aws_route53_record" "external" {
  zone_id = var.dns_root.zone_id
  name    = "${local.device_fqdn}"
  type    = "A"
  ttl     = "60"
  records = [data.aws_network_interface.fpc.association[0].public_ip]
}

resource "aws_network_interface_sg_attachment" "internal" {
  for_each = {
    for idx, v in aws_network_interface.interfaces : idx => v
  }
  security_group_id    = var.security_group.id
  network_interface_id = each.value.id
}

data "template_file" "init_config" {
  template = file("${path.module}/init.conf")
  vars = {
    license =   file(local.license_file)
    db_hostname = "db.${local.device_fqdn}"
  }
}

data "template_file" "init_config" {
  template = file("${path.module}/init.conf")
  vars = {
    license =   file(local.license_file)
    hostname = local.device_fqdn
  }
}

resource "aws_instance" "dev" {
    ami               = local.amis["fpc"][data.aws_region.current.name][local.fortios]
    instance_type     = local.instance_type
    availability_zone = var.az
    key_name          = var.key_name
    user_data         = data.template_file.init_config.rendered

    root_block_device {
        volume_type = "standard"
        volume_size = "10"
    }

    ebs_block_device {
        device_name = "/dev/sdb"
        volume_size = "80"
        volume_type = "standard"
    }

    network_interface {
        network_interface_id = aws_network_interface.interfaces["0"].id
        device_index         = 0
    }

    tags = {
        Name = "${local.device_fqdn}"
    }
}
