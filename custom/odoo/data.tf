# Bash file to execute odoo instalation
data "template_file" "user_data" {
  template = file("${path.module}/user-data.tpl.sh")
  vars = {
    odoo_version     = var.odoo_version
    odoo_user        = var.odoo_user
    odoo_domain_name = var.odoo_domain_name
  }
}

# Get AWS subnets in the VPC provided by the user
# Needs to have at least two subnets in the VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "availability-zone"
    values = ["${var.region}a", "${var.region}b"]
  }
}

# Get the DNS Zone for Odoo based on the value provided by the user
data "aws_route53_zone" "odoo" {
  name         = var.dns_zone
  private_zone = false
}
