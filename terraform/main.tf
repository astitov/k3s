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

resource "aws_vpc" "my-vpc" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "my-pubnet" {
  vpc.id                  = aws_vpc.my-vpc.id
  cidr_block              = var.pub_cidr
  map_public_ip_on_launch = true
}

resource "aws_subnet" "my-privnet" {
  vpc.id      = aws_vpc.my-vpc.id
  cidr_block  = var.priv_cidr
}

resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.my-vpc.id
}

resource "aws_route_table" "my-igw-rt" {
  vpc_id = aws_vpc.my-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw.id
  }
}

resource "aws_route_table_association" "my-rt-pubnet-assoc" {
  subnet_id       = aws_subnet.my-pubnet
  route_table_id  = aws_route_table.my-igw-rt.id
}


resource "aws_instance" "my-vm" {
  ami                    = "ami-07eeacb3005b9beae"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.my-sgroup.id]
  count                  = 5

  tags = {
    Name = random_pet.name.id
  }
}

resource "aws_security_group" "my-sgroup" {
  name = "${random_pet.name.id}-sgroup"
  ingress {
    from_port   = 80
    to_port     = 80
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
