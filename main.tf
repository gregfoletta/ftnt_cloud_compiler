provider "aws" {
  alias  = "apse2"
  region = "ap-southeast-1"
}

module "ftnt_sites" {
    sites = var.sites   
    providers = { aws = aws.apse2 }
    source = "./ftnt_sites"
}

output "rsa_private_key" { 
    value = module.ftnt_sites.rsa_private_key
    sensitive = true
}
