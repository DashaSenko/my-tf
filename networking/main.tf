# Data source to receive a list of AZs in a region
data "aws_availability_zones" "available" {
  state = "available"
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
    "Name" = format("%s", var.aws_subnets[count.index].name)
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


