provider "aws" {
  alias  = "apse2"
  region = "ap-southeast-2"
}

module "aws_ftnt_sites" {
    sites = var.sites   
    providers = { aws = aws.apse2 }
    source = "./ftnt_cloud_compiler/aws_ftnt_sites"
}

output "rsa_private_key" { 
    value = module.aws_ftnt_sites.rsa_private_key
    sensitive = true
}
