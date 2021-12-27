aws_lb = {
  name = "tf-loadbalancer"
  type = "application"
}

aws_lb_tg = {
  name                 = "tf-lb-targetgroup"
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 30
  target_type          = "instance"
}

aws_lb_tg_health_check = {
  port                = 80
  protocol            = "HTTP"
  path                = "/"
  interval            = 30
  timeout             = 5
  matcher             = "200-299"
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

aws_dns = {
  website_name = "my-tf.satoru.ml"
  zone_id      = "Z09882201OF75I5PO0UV9"
  record_type  = "A"
}
