terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      configuration_aliases = [ aws ]
    }
  }
}

variable "sites" {} 

# Create a keypair for authentication to devices
resource "tls_private_key" "keypair" {
  algorithm   = "RSA"
  rsa_bits = "4096"
}

resource "local_file" "private_key" {
    content = tls_private_key.keypair.private_key_pem
    filename = "id_rsa"
    file_permission = "600"
}

resource "local_file" "public_key" {
    content = tls_private_key.keypair.public_key_pem
    filename = "id_rsa.pub"
}

resource "random_string" "random" {
  length           = 8 
  special          = false 
  override_special = "/@£$"
}

resource "aws_key_pair" "key" {
  key_name   = "key_${random_string.random.result}"
  public_key = tls_private_key.keypair.public_key_openssh
}


# For each site, create the site
module "ftnt_site" {
    for_each = var.sites
    source    = "./ftnt_site"
    site_name = each.key
    site_vars = each.value
    key_name = aws_key_pair.key.key_name
}

output "rsa_private_key" { 
    value = tls_private_key.keypair.private_key_pem 
    sensitive = true
}

output "rsa_public_key" {
    value = tls_private_key.keypair.public_key_pem
    sensitive = true
}
