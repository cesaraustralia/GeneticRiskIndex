
# Default variables
# Override in your main.tfvars file in this directory

variable "project" {
  type = string
  default = "victoria-genetic-risk-index" 
}

variable "r_instance_type" {
  type = string
  default = "t2.micro"
}

variable "julia_instance_type" {
  type = string
  default = "t2.medium"
}

variable "aws_region" {
  type = string
  default = "ap-southeast-2"
}

variable "aws_credentials" {
  type = string
}

variable "private_key" {
  type = string
  default = "key"
}

variable "public_key" {
  type = string
  default = "key.pub"
}

# AMI names to match locations
# This is Ubuntu X ?
variable "ami" {
  type = map(string)

  # see https://cloud-images.ubuntu.com/locator/ec2/
  default = {
    "ap-southeast-2" = "ami-0ae0b19a90d6da41b" 
  }
}
