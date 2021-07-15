data "aws_s3_bucket" "bucket" {
  bucket = var.s3_bucket
}

# See https://aws.amazon.com/blogs/security/writing-iam-policies-how-to-grant-access-to-an-amazon-s3-bucket/

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = data.aws_s3_bucket.bucket.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject"],
      "Resource": "${data.aws_s3_bucket.bucket.arn}/*"
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:PutObject", 
        "s3:GetObject", 
        "s3:DeleteObject"
      ],
      "Resource": [
        "${data.aws_s3_bucket.bucket.arn}",
        "${data.aws_s3_bucket.bucket.arn}/*",
        "${data.aws_s3_bucket.bucket.arn}/job/*"
      ]
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": [
        "${data.aws_s3_bucket.bucket.arn}/habitat.tif",
        "${data.aws_s3_bucket.bucket.arn}/fire_severity.tif",
        "${data.aws_s3_bucket.bucket.arn}/batch_taxa.csv",
        "${data.aws_s3_bucket.bucket.arn}/config.toml"
      ]
    }
  ]
}
  POLICY
}

    # resource "aws_s3_bucket_policy" "bucket_user_policy" {
    #   bucket = data.aws_s3_bucket.bucket.id
    #   policy = <<POLICY
    # {
    #   "Version": "2012-10-17",
    #   "Statement": [
    #     {
    #       "Effect": "Allow",
    #       "Action": [
    #         "s3:GetBucketLocation",
    #         "s3:ListAllMyBuckets"
    #       ],
    #       "Resource": "*"
    #     },
    #     {
    #       "Effect": "Allow",
    #       "Action": ["s3:ListBucket"],
    #       "Resource": ["${data.aws_s3_bucket.bucket.arn}"]
    #     },
    #     {
    #       "Effect": "Allow",
    #       "Action": [
    #         "s3:PutObject",
    #         "s3:GetObject",
    #         "s3:DeleteObject"
    #       ],
    #       "Resource": ["${data.aws_s3_bucket.bucket.arn}/*"]
     #     }
     #   ]
     # }
     # POLICY
     # }

     output "s3-bucket-url" {
       description = "URL for the s3 bucket"
       value = "https://${data.aws_s3_bucket.bucket.bucket_regional_domain_name}"
     }

