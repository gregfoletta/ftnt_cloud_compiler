variable "db_subnet_id" {}

resource "aws_db_subnet_group" "fpc" {
  name       = "db.${local.name_suffix}"
  subnet_ids = [var.subnet_id, var.db_subnet_id]

  tags = {
    Name = "db.${local.name_suffix}"
  }
}


resource "aws_route53_record" "fpc_db" {
  zone_id = var.dns_root.zone_id
  name    = "db.${local.name_suffix}"
  type    = "CNAME"
  ttl     = "60"
  records = [resource.aws_db_instance.fpc.address]
}


resource "aws_db_instance" "fpc" {
  allocated_storage    = 20
  engine               = "mariadb"
  engine_version       = "10.6.7"
  instance_class       = "db.t3.micro"
  db_subnet_group_name = aws_db_subnet_group.fpc.id
  skip_final_snapshot = true
  username             = "root"
  password             = "tjzon6899Ezrrm4xYFu9bvp7"
  multi_az = false

  tags = {
    Name = "db.${local.name_suffix}"
  }
}
