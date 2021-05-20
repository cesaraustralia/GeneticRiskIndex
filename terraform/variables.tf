
# Default variables
# Override in your main.tfvars file in this directory

variable "project" {
  default = "unnamed"
}

variable "r_instance_type" {
  default = "t2.micro"
}

variable "julia_instance_type" {
  default = "t2.micro"
}

variable "julia_project_dir" {
  default = "~/"
}

variable "julia_cpus" {
  default = "1"
}

variable "julia_instance_memory" {
  default = 1024
}

variable "julia_instance_count" {
  default = 1
}

variable "aws_region" {
  default = "ap-southeast-2"
}

variable "aws_access_key" {
  default = ""
}

variable "aws_secret_key" {
  default = ""
}

variable "pvt_key" {
  default = ""
}

variable "pub_key" {
  default = ""
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
