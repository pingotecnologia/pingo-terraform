/*
   Copyright 2023 - Pingo Tecnologia
   Register a DNS record for Odoo based on the value provided by the user
   with the Odoo Application Load Balance as target
*/
resource "aws_route53_record" "odoo_a_record" {
  zone_id = data.aws_route53_zone.odoo.zone_id
  name    = var.odoo_domain_name
  type    = "A"
  alias {
    name                   = aws_lb.odoo.dns_name
    zone_id                = aws_lb.odoo.zone_id
    evaluate_target_health = false
  }
}
