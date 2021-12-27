# Data source to receive a list of AZs in a region
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source to receive a data about existing ACM certificate
data "aws_acm_certificate" "cert" {
  domain   = "*.satoru.ml"
  statuses = ["ISSUED"]
}

# Data source to receive a data the latest available Ubuntu 20.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.aws_vpc.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    "Name" = var.aws_vpc.name
  }
}

resource "aws_subnet" "public_subnet" {
  count                   = length(var.aws_subnets)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.aws_subnets[count.index].cidr
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    "Name" = var.aws_subnets[count.index].name
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" = format("IGW-%s", var.aws_vpc.name)
  }
}

# Route table for the subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

# Route table association
resource "aws_route_table_association" "public-subnet-association" {
  count          = length(var.aws_subnets)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public_rt.id
}

# ----- LoadBalancing Part -----

resource "aws_security_group" "lb_sg" {
  vpc_id      = aws_vpc.vpc.id
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
  load_balancer_type         = var.aws_lb.type
  internal                   = false
  enable_deletion_protection = false
  idle_timeout               = 60
  security_groups            = [aws_security_group.lb_sg.id]
  subnets                    = aws_subnet.public_subnet.*.id

  tags = {
    "Name" = var.aws_lb.name
  }
}

resource "aws_lb_target_group" "tg" {
  vpc_id               = aws_vpc.vpc.id
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
      values = [var.aws_dns.website_name]
    }
  }
}

resource "aws_route53_record" "satoru" {
  zone_id = var.aws_dns.zone_id
  name    = var.aws_dns.website_name
  type    = var.aws_dns.record_type

  alias {
    name                   = aws_lb.lb.dns_name
    zone_id                = aws_lb.lb.zone_id
    evaluate_target_health = false
  }
}

# ----- EC2 Part -----

resource "aws_security_group" "ec2_sg" {
  vpc_id      = aws_vpc.vpc.id
  name        = var.aws_sg.ec2.name
  description = var.aws_sg.ec2.description

  ingress {
    description = "Open port 80 for HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.aws_sg.ec2.cidr_blocks
  }

  ingress {
    description = "Open port 22 for SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.aws_sg.ec2.cidr_blocks
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
    "Name" = var.aws_sg.ec2.name
  }
}

resource "aws_launch_configuration" "lc" {
  image_id                    = data.aws_ami.ubuntu.id
  key_name                    = var.aws_ec2.key_name
  instance_type               = var.aws_ec2.instance_type
  enable_monitoring           = false
  security_groups             = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true
  user_data                   = file("update.sh")
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  launch_configuration = aws_launch_configuration.lc.id
  vpc_zone_identifier  = aws_subnet.public_subnet.*.id
  min_size             = var.aws_asg.min_size
  max_size             = var.aws_asg.max_size

  target_group_arns = [aws_lb_target_group.tg.arn]
  health_check_type = "ELB"

  tag {
    key                 = "Name"
    value               = var.aws_asg.ec2_name
    propagate_at_launch = true
  }
}

