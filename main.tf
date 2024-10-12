terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.67.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# RSA key of size 4096 bits
resource "tls_private_key" "rsa_4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key" {
  key_name     = var.key_name
  public_key   = tls_private_key.rsa_4096.public_key_openssh
}

resource "local_file" "private_key" {
  content = tls_private_key.rsa_4096.private_key_pem
  filename = var.key_name
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.availability_zone

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.default.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.default.id
}

resource "aws_route" "public_route" {
  route_table_id     = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id         = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_instance" "public_instance" {
  ami              = "ami-0e86e20dae9224db8"
  instance_type    = "t2.micro"
  key_name         = aws_key_pair.key.key_name
  subnet_id        = aws_subnet.public_subnet.id
  security_groups  = [aws_security_group.nginx_sg.id]
  user_data        = file("install_nginx.sh")

  associate_public_ip_address = true

  tags = {
    Name = "public_instance"
  }
}

resource "aws_security_group" "nginx_sg" {
  name        = "nginx-sg"
  description = "Security group for Nginx"
  vpc_id      = aws_vpc.default.id


# Inbound rule for Jenkins (port 8080)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Open to the world, restrict if needed
  }

  # Outbound traffic (for Internet access)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "ec2_instance_public_ip" {
  value = aws_instance.public_instance.public_ip
}
