# AWS settings ###########
#
terraform {
 required_providers {
   aws = {
     source  = "hashicorp/aws"
     version = "~> 3.0"
   }
 }
 # backend "s3" {
   # bucket = "YOUR_BUCKET_NAME"
   # key    = "ari-state"
 # }
}

# aws_access_key and aws_secret_key must be in your main.tfvars file
provider "aws" {
  region = var.aws_region
}
 
data "aws_ami" "ubuntu" {
 most_recent = true
 filter {
   name   = "name"
   values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
 }
 filter {
   name   = "virtualization-type"
   values = ["hvm"]
 }
 owners = ["099720109477"]
}
