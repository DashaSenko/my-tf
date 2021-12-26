data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["*VPC*"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}

data "aws_lb_target_group" "tg" {
  name = "tf-lb-targetgroup"
}

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

resource "aws_security_group" "ec2_sg" {
  vpc_id      = data.aws_vpc.vpc.id
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
  user_data = templatefile(
    "./init.tftpl",
    {}
  )
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  launch_configuration = aws_launch_configuration.lc.id
  vpc_zone_identifier  = data.aws_subnets.public.ids
  min_size             = 2
  max_size             = 2

  target_group_arns = [data.aws_lb_target_group.tg.arn]
  health_check_type = "ELB"

  tag {
    key                 = "Name"
    value               = "terraform-asg-ec2"
    propagate_at_launch = true
  }
}
