# AWS settings ###########

# aws_access_key and aws_secret_key must be in your main.tfvars file
provider "aws" {
  region = var.aws_region
}

resource "aws_key_pair" "keys" {
  key_name   = "keys"
  public_key = "keys.pub"
}
