#  NETWORKS 

resource "aws_subnet" "my_privnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = var.priv_cidr
}

# NAT GATEWAY

resource "aws_eip" "my_elastic_ip" {
  vpc = true
}

resource "aws_nat_gateway" "my_natgw" {
  allocation_id = aws_eip.my_elastic_ip.id
  subnet_id     = aws_subnet.my_pubnet.id
}

# Routing tables

resource "aws_route_table" "my_natgw_rt" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.my_natgw.id
  }
}

resource "aws_route_table_association" "my_rt_privnet_assoc" {
  subnet_id      = aws_subnet.my_privnet.id
  route_table_id = aws_route_table.my_natgw_rt.id
}

# Firewall

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

resource "aws_instance" "my_worker" {
  ami                    = var.my_ami
  instance_type          = "t2.micro"
  count                  = 1
  depends_on             = [aws_instance.my_master]
  vpc_security_group_ids = [aws_security_group.my_priv_sg.id]
  subnet_id              = aws_subnet.my_privnet.id
  #user_data              = ${data.template_file.k3s_agent.rendered}
  user_data              = "curl -sfL https://get.k3s.io | sh - agent --token=k3s --server https://${aws_instance.my_master.private_ip}:6443"
}
