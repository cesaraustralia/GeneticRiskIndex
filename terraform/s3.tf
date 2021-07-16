# add an s3 bucket resource created manually

data "aws_s3_bucket" "bucket" {
  bucket = var.s3_bucket
}

output "s3-bucket-url" {
  description = "URL for the s3 bucket"
  value = "https://${data.aws_s3_bucket.bucket.bucket_regional_domain_name}"
}

