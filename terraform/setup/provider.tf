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
   # key    = "state"
 # }
}

# aws_access_key and aws_secret_key must be in your main.tfvars file
provider "aws" {
  region = var.aws_region
}
