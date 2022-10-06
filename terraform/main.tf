terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
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

# Gateways

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Routing tables

resource "aws_route_table" "my_igw_rt" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

resource "aws_route_table_association" "my_rt_pubnet_assoc" {
  subnet_id      = aws_subnet.my_pubnet.id
  route_table_id = aws_route_table.my_igw_rt.id
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
} #   SSH key

resource "aws_key_pair" "my_ssh_key" {
  key_name   = "ssh_key"
  public_key = file(".ssh/id_rsa.pub")
}

#
#   VM instances
#

resource "aws_instance" "my_master" {
  ami                    = var.my_ami
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.my_pub_sg.id]
  subnet_id              = aws_subnet.my_pubnet.id
  key_name               = aws_key_pair.my_ssh_key.key_name
#  user_data              = "curl -sfL https://get.k3s.io | sh - server --token=k3s"
}
