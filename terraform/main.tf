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

resource "aws_vpc" "my-vpc" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "my-pubnet" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = var.pub_cidr
  map_public_ip_on_launch = true
}

resource "aws_subnet" "my-privnet" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = var.priv_cidr
}

# Gateways

resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.my-vpc.id
}

resource "aws_eip" "my-elastic-ip" {
  vpc = true
}

resource "aws_nat_gateway" "my-natgw" {
  allocation_id = aws_eip.my-elastic-ip.id
  subnet_id     = aws_subnet.my-pubnet.id
}

# Routing tables

resource "aws_route_table" "my-igw-rt" {
  vpc_id = aws_vpc.my-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw.id
  }
}

resource "aws_route_table" "my-natgw-rt" {
  vpc_id = aws_vpc.my-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.my-natgw.id
  }
}

resource "aws_route_table_association" "my-rt-pubnet-assoc" {
  subnet_id      = aws_subnet.my-pubnet.id
  route_table_id = aws_route_table.my-igw-rt.id
}

resource "aws_route_table_association" "my-rt-privnet-assoc" {
  subnet_id      = aws_subnet.my-privnet.id
  route_table_id = aws_route_table.my-natgw-rt.id
}

# Firewall

resource "aws_security_group" "my-pub-sg" {
  vpc_id = aws_vpc.my-vpc.id

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


#
#   VM instances
#

resource "aws_instance" "my-vm" {
  ami                    = "ami-07eeacb3005b9beae"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.my-pub-sg.id]
  subnet_id              = aws_subnet.my-pubnet.id
}

