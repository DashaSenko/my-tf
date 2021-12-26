aws_sg = {
  loadbalancer = {
    name        = "tf-lb"
    description = "Allow all incoming http(s) traffic for loadbalancer"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

aws_lb = {
  name = "tf-loadbalancer"
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
