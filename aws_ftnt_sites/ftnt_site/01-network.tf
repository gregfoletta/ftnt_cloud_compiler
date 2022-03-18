data "aws_availability_zones" "available" {
  state = "available"
}

locals {
    site_fqdn = "${var.site_name}.${data.aws_route53_zone.root.name}"
}

// Each site exists within its own VPC
resource "aws_vpc" "ftnt_hub" {
    cidr_block           = var.site_vars.cidr
    enable_dns_support   = true
    enable_dns_hostnames = true
    enable_classiclink   = false
    tags = {
        Name = "vpc.${local.site_fqdn}"
    }
}

// Iterate across all the route tables for the site and create them
resource "aws_route_table" "route_tables" {
  for_each = {
    for route_table in var.site_vars.route_tables: route_table.name => route_table.subnets
  }
  vpc_id = aws_vpc.ftnt_hub.id

  tags = {
    Name = "${each.key}.${local.site_fqdn}"
  }
}


// igw is a special route table to allow us to do VPC ingress routing
resource "aws_route_table" "igw" {
  vpc_id = aws_vpc.ftnt_hub.id

  tags = {
    Name = "igw.${local.site_fqdn}"
  }
}

// Need to re-arrange the route tables and subnets so we
// can create the subnets in one resource for_each call
locals {
    flattened_rt_subnets = flatten([
        for route_table in var.site_vars.route_tables : [
            for subnet in route_table.subnets : {
                route_table = route_table.name
                subnet_name = subnet.name 
                ipv4_subnet = subnet.ipv4_subnet
                public_ipv4 = try(subnet.public_ipv4, false)
                az = try(subnet.az, 0)
            }
        ]
    ])
}

resource "aws_subnet" "subnets" {
    for_each = {
        for subnet in local.flattened_rt_subnets : subnet.subnet_name => subnet
    }
    vpc_id            = aws_vpc.ftnt_hub.id
    availability_zone = data.aws_availability_zones.available.names[ each.value.az ]
    cidr_block        = cidrsubnet( var.site_vars.cidr, each.value.ipv4_subnet[0], each.value.ipv4_subnet[1] )
    map_public_ip_on_launch = each.value.public_ipv4
    tags = {
        Name = "${each.key}.${local.site_fqdn}"
    }
}

// Then associate them with each routing table
resource "aws_route_table_association" "associate" {
    for_each = {
        for subnet in local.flattened_rt_subnets : subnet.subnet_name => subnet
    }

    subnet_id      = aws_subnet.subnets[ each.key ].id
    route_table_id = aws_route_table.route_tables[ each.value.route_table ].id
}



// IGW is special and gets associated separately
resource "aws_route_table_association" "igw_associate" {
    gateway_id = aws_internet_gateway.gw.id
    route_table_id = aws_route_table.igw.id
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.ftnt_hub.id
  tags = {
    Name = "igw.${local.site_fqdn}"
  }
}



resource "aws_security_group" "external" {
  name        = "external.sg.${local.site_fqdn}"
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
    Name        = "external.sg.${local.site_fqdn}"
  }
}

resource "aws_security_group" "internal" {
  name        = "internal.sg.${local.site_fqdn}"
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
    Name        = "internal.sg.${local.site_fqdn}"
  }
}

