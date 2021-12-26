data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["*VPC*"]
  }
}

data "aws_acm_certificate" "cert" {
  domain   = "*.satoru.ml"
  statuses = ["ISSUED"]
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}

resource "aws_security_group" "lb_sg" {
  vpc_id      = data.aws_vpc.vpc.id
  name        = var.aws_sg.loadbalancer.name
  description = var.aws_sg.loadbalancer.description

  ingress {
    description = "Open port 80 for HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.aws_sg.loadbalancer.cidr_blocks
  }

  ingress {
    description = "Open port 443 for HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.aws_sg.loadbalancer.cidr_blocks
  }

  egress {
    description = "Outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = {
    "Name" = var.aws_sg.loadbalancer.name
  }
}

resource "aws_lb" "lb" {
  name                       = var.aws_lb.name
  load_balancer_type         = "application"
  internal                   = false
  enable_deletion_protection = false
  idle_timeout               = 60
  security_groups            = [aws_security_group.lb_sg.id]
  subnets                    = data.aws_subnets.public.ids

  tags = {
    "Name" = var.aws_lb.name
  }
}

resource "aws_lb_target_group" "tg" {
  vpc_id               = data.aws_vpc.vpc.id
  name                 = var.aws_lb_tg.name
  port                 = var.aws_lb_tg.port
  protocol             = var.aws_lb_tg.protocol
  target_type          = var.aws_lb_tg.target_type
  deregistration_delay = var.aws_lb_tg.deregistration_delay

  health_check {
    port                = var.aws_lb_tg_health_check.port
    protocol            = var.aws_lb_tg_health_check.protocol
    path                = var.aws_lb_tg_health_check.path
    interval            = var.aws_lb_tg_health_check.interval
    timeout             = var.aws_lb_tg_health_check.timeout
    matcher             = var.aws_lb_tg_health_check.matcher
    healthy_threshold   = var.aws_lb_tg_health_check.healthy_threshold
    unhealthy_threshold = var.aws_lb_tg_health_check.unhealthy_threshold
  }

  tags = {
    "Name" = var.aws_lb_tg.name
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
  certificate_arn   = data.aws_acm_certificate.cert.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "path not found"
      status_code  = "503"
    }
  }
}

resource "aws_lb_listener_rule" "forward" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

  condition {
    host_header {
      values = ["my-tf.satoru.ml"]
    }
  }
}

resource "aws_route53_record" "satoru" {
  zone_id = "Z09882201OF75I5PO0UV9"
  name    = "my-tf.satoru.ml"
  type    = "A"

  alias {
    name                   = aws_lb.lb.dns_name
    zone_id                = aws_lb.lb.zone_id
    evaluate_target_health = false
  }
}
