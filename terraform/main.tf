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

resource "aws_instance" "my-vm" {
  ami           = "ami-07eeacb3005b9beae"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.my-sgroup.id]

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
