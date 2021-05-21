
# Default variables
# Override in your main.tfvars file in this directory

variable "project" {
  type = string
  default = "unnamed"
}

variable "taxon_ids" {
  type = list(number)
  default = [1001]
}

variable "r_instance_type" {
  type = string
  default = "t2.micro"
}

variable "julia_instance_type" {
  type = string
  default = "t2.micro"
}

variable "julia_project_dir" {
  type = string
  default = "~/"
}

variable "julia_cpus" {
  type = number
  default = 1
}

variable "julia_instance_memory" {
  type = number
  default = 1024
}

variable "julia_instance_count" {
  type = number
  default = 1
}

variable "aws_region" {
  type = string
  default = "ap-southeast-2"
}

variable "aws_access_key" {
  type = string
  default = ""
}

variable "aws_secret_key" {
  type = string
  default = ""
}

variable "pvt_key" {
  type = string
  default = ""
}

variable "pub_key" {
  type = string
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
