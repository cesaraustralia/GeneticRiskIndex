# AWS settings ###########

# aws_access_key and aws_secret_key must be in your main.tfvars file
provider "aws" {
  region = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_key_pair" "cesar" {
  key_name   = "cesar"
  public_key = var.pub_key
}
