variable "site_name" {}
variable "site_vars" {}
variable "key_name" {}

data "aws_route53_zone" "root" {
  name         = var.site_vars.dns_root
}

