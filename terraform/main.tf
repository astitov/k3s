terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  required_version = ">= 1.2.0"
}

provider "random" {}

provider "aws" {
  region = "us-west-2"
}

resource "random_pet" "name" {
  length = 2
}

#
#   VPC and networks
#

resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "my_pubnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.pub_cidr
  map_public_ip_on_launch = true
}

resource "aws_subnet" "my_privnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = var.priv_cidr
}

# Gateways

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_eip" "my_elastic_ip" {
  vpc = true
}

resource "aws_nat_gateway" "my_natgw" {
  allocation_id = aws_eip.my_elastic_ip.id
  subnet_id     = aws_subnet.my_pubnet.id
}

# Routing tables

resource "aws_route_table" "my_igw_rt" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw.id
  }
}

resource "aws_route_table" "my_natgw_rt" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.my_natgw.id
  }
}

resource "aws_route_table_association" "my_rt_pubnet_assoc" {
  subnet_id      = aws_subnet.my_pubnet.id
  route_table_id = aws_route_table.my_igw_rt.id
}

resource "aws_route_table_association" "my_rt_privnet_assoc" {
  subnet_id      = aws_subnet.my_privnet.id
  route_table_id = aws_route_table.my_natgw_rt.id
}

# Firewall

resource "aws_security_group" "my_pub_sg" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "my_priv_sg" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#
#   VM instances
#

resource "aws_instance" "my_master" {
  ami                    = "ami-07eeacb3005b9beae"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.my_pub_sg.id]
  subnet_id              = aws_subnet.my_pubnet.id
  user_data              = "curl -sfL https://get.k3s.io | sh -"
}

resource "aws_instance" "my-worker" {
  ami                    = "ami-07eeacb3005b9beae"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.my_priv_sg.id]
  subnet_id              = aws_subnet.my_privnet.id
}
