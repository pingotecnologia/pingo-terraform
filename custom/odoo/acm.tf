/*
   Copyright 2023 - Pingo Tecnologia
   Creates a ACM certificate based on Odoo Domain Name provided by the user
   Also creates the route53 records for Odoo and validates it
*/
resource "aws_acm_certificate" "odoo" {
  domain_name       = var.odoo_domain_name
  validation_method = "DNS"

  tags = {
    environment = var.tag_environment
    service     = var.tag_service
    repo        = var.tag_repo
  }
}

resource "aws_route53_record" "odoo_acm" {
  for_each = {
    for dvo in aws_acm_certificate.odoo.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.odoo.zone_id
}

resource "aws_acm_certificate_validation" "odoo_acm_validation" {
  certificate_arn         = aws_acm_certificate.odoo.arn
  validation_record_fqdns = [for record in aws_route53_record.odoo_acm : record.fqdn]
}
