data "aws_availability_zones" "available" {
  state = "available"
}

locals {
    name_suffix = "${var.site_name}.${data.aws_route53_zone.root.name}"
}


resource "aws_vpc" "ftnt_hub" {
    cidr_block           = var.site_vars.vpc_cidr
    enable_dns_support   = true
    enable_dns_hostnames = true
    enable_classiclink   = false
    tags = {
        Name = "vpc.${local.name_suffix}"
    }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ftnt_hub.id

  tags = {
    Name = "public.${local.name_suffix}"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.ftnt_hub.id

  tags = {
    Name = "private.${local.name_suffix}"
  }
}

resource "aws_route_table" "igw" {
  vpc_id = aws_vpc.ftnt_hub.id

  tags = {
    Name = "igw.${local.name_suffix}"
  }
}


resource "aws_subnet" "public_subnets" {
    for_each = var.site_vars.networks.public
    vpc_id            = aws_vpc.ftnt_hub.id
    availability_zone = data.aws_availability_zones.available.names[0]
    cidr_block        = cidrsubnet( var.site_vars.vpc_cidr, each.value[0], each.value[1] )
    tags = {
        Name = "${each.key}.public.${local.name_suffix}"
    }
}

resource "aws_subnet" "private_subnets" {
    for_each = var.site_vars.networks.private
    vpc_id            = aws_vpc.ftnt_hub.id
    availability_zone = data.aws_availability_zones.available.names[0]
    cidr_block        = cidrsubnet( var.site_vars.vpc_cidr, each.value.subnet[0], each.value.subnet[1] )
    map_public_ip_on_launch = try( each.value.public_ipv4, "false" ) 
    tags = {
        Name = "${each.key}.private.${local.name_suffix}"
    }
}


resource "aws_route_table_association" "public_associate" {
    for_each = aws_subnet.public_subnets

    subnet_id      = each.value.id
    route_table_id = aws_route_table.public.id
}


resource "aws_route_table_association" "private_associate" {
    for_each = aws_subnet.private_subnets

    subnet_id      = each.value.id
    route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "igw_associate" {
    gateway_id = aws_internet_gateway.gw.id
    route_table_id = aws_route_table.igw.id
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.ftnt_hub.id
  tags = {
    Name = "igw.${local.name_suffix}"
  }
}

locals {
    first_fgt = module.fortigate[ keys(local.fgt)[0] ]
}

resource "aws_route" "internal_route" {
  depends_on             = [module.fortigate]
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = local.first_fgt.internal_interface.id
}


resource "aws_route" "external_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}


resource "aws_route" "igw_internal_routes" {
  depends_on             = [module.fortigate]
  for_each = { for name, network in var.site_vars.networks.private : name => network if network.public_ipv4 == true }
  route_table_id         = aws_route_table.igw.id
  destination_cidr_block = cidrsubnet( var.site_vars.vpc_cidr, each.value.subnet[0], each.value.subnet[1] )
  network_interface_id   = local.first_fgt.external_interface.id
}


resource "aws_security_group" "fgt_external" {
  name        = "external.sg.${local.name_suffix}"
  vpc_id      = aws_vpc.ftnt_hub.id

    ingress {
        protocol = "icmp"
        from_port = 8
        to_port = 0
        cidr_blocks = ["0.0.0.0/0"]
    }
    

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "external.sg.${local.name_suffix}"
  }
}

resource "aws_security_group" "fgt_internal" {
  name        = "internal.sg.${local.name_suffix}"
  vpc_id      = aws_vpc.ftnt_hub.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "internal.sg.${local.name_suffix}"
  }
}

