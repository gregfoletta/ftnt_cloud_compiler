provider "aws" {
  alias  = "apse2"
  region = "ap-southeast-1"
}

module "aws_ftnt_sites" {
    sites = var.sites   
    providers = { aws = aws.apse2 }
    source = "./aws_ftnt_sites"
}

output "rsa_private_key" { 
    value = module.aws_ftnt_sites.rsa_private_key
    sensitive = true
}
