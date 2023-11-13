/*
   Copyright 2023 - Pingo Tecnologia
   Creates the Application Load Balancer for Odoo
   Also creates the Target Group with the Odoo instance as target reaching
   the 80 port, because the SSL will be handled by the Load Balancer
   Also creates a 443 listener using the AWS ACM with the certificate
*/
resource "aws_lb" "odoo" {
  name               = "${var.name_prefix}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.odoo_sg.id]
  subnets            = [data.aws_subnets.default.ids[0], data.aws_subnets.default.ids[1]]

  enable_deletion_protection = true

  tags = {
    environment = var.tag_environment
    service     = var.tag_service
    Name        = "${var.name_prefix}-lb"
  }
}

resource "aws_lb_target_group" "odoo" {
  name     = "${var.name_prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_target_group_attachment" "odoo" {
  target_group_arn = aws_lb_target_group.odoo.arn
  target_id        = aws_instance.this.id
  port             = 80
}

resource "aws_lb_listener" "odoo_80" {
  load_balancer_arn = aws_lb.odoo.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "odoo_443" {
  load_balancer_arn = aws_lb.odoo.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.odoo.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.odoo.arn
  }
}

# resource "aws_lb_listener_certificate" "odoo" {
#   listener_arn    = aws_lb_listener.odoo_443.arn
#   certificate_arn = aws_acm_certificate.odoo.arn
# }
