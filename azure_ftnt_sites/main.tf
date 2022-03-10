variable "sites" {} 

# Create a keypair for authentication to devices
resource "tls_private_key" "keypair" {
  algorithm   = "RSA"
  ecdsa_curve = "4096"
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

# For each site, create the site
module "ftnt_site" {
    for_each = var.sites
    source    = "./ftnt_site"
    site_name = each.key
    site_vars = each.value
    public_key = tls_private_key.keypair.public_key_openssh
}

output "rsa_private_key" { 
    value = tls_private_key.keypair.private_key_pem 
    sensitive = true
}

output "rsa_public_key" {
    value = tls_private_key.keypair.public_key_pem
    sensitive = true
}
