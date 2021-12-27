aws_vpc = {
  cidr = "10.0.0.0/22"
  name = "TF-VPC"
}

aws_subnets = [
  {
    cidr = "10.0.1.0/24"
    name = "TF-Public-Subnet1"
  },
  {
    cidr = "10.0.2.0/24"
    name = "TF-Public-Subnet2"
  }
]