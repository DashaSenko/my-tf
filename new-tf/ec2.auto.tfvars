aws_sg = {
  ec2 = {
    name        = "tf-ec2"
    description = "Allow incoming http(s) traffic from loadbalancer and limited SSH"
    cidr_blocks = ["10.0.0.0/22", "46.53.251.151/32", "46.53.243.176/32", "82.209.240.102/32"]
  }
  loadbalancer = {
    name        = "tf-lb"
    description = "Allow all incoming http(s) traffic for loadbalancer"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

aws_ec2 = {
  count         = 2
  name          = "tf-ec2"
  instance_type = "t3.micro"
  key_name      = "dasha-eu-central-1"
}

aws_asg = {
  min_size = 2
  max_size = 2
  ec2_name = "tf-asg-ec2"
}