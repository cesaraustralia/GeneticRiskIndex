
# Default variables
# Override in your main.tfvars file in this directory

variable "project" {
  type = string
  default = "genetic-risk-index" 
}

variable "project_repo" {
  type = string
  default = "https://github.com/cesaraustralia/GeneticRiskIndex"
}

variable "s3_bucket" {
  type = string
  default = "genetic-risk-index-bucket"
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
  default = "~/.aws/credentials"
}

variable "private_key" {
  type = string
  default = "key.pem"
}

variable "public_key" {
  type = string
  default = "key.pem.pub"
}

variable "public_key_openssh" {
  type = string
  default = "key.openssh.pub"
}

variable "julia_cpus" {
  type = number
  default = 1
}

variable "julia_memory" {
  type = number
  default = 4096
}
