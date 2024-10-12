variable "key_name" {}

variable "vpc_cidr_block" {
  type = string
  description = "CIDR block for the VPC"
  default = "10.0.0.0/16"
}

variable "subnet_cidr_block" {
  type = string
  description = "CIDR block for the public subnet"
  default = "10.0.1.0/24"
}

variable "availability_zone" {
  type = string
  description = "Availability zone for the public subnet"
  default = "us-east-1a"
}