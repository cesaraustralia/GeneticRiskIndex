
# Default variables
# Override in your main.tfvars file in this directory

variable "project" {
  type = string
  default = "genetic-risk-index" 
}

variable "r_instance_type" {
  type = string
  default = "t2.small"
}

variable "aws_region" {
  type = string
  default = "ap-southeast-2"
}

variable "aws_availability_zone" {
  type = string
  default = "ap-southeast-2a"
}

variable "aws_credentials" {
  type = string
}

variable "private_key" {
  type = string
  default = "../key.pem"
}

variable "public_key" {
  type = string
  default = "../key.pem.pub"
}

variable "public_key_openssh" {
  type = string
  default = "../key.pem.pub"
}
