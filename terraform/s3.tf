data "aws_s3_bucket" "bucket" {
  bucket = var.s3_bucket
}

resource "aws_iam_role" "s3_datasync_role" {
  name = "${var.project}-s3-datasync-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "s3_datasync_role" {
  role       = aws_iam_role.s3_datasync_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_datasync_location_s3" "data" {
  s3_bucket_arn = data.aws_s3_bucket.bucket.arn
  subdirectory = "/data"
  s3_config {
    bucket_access_role_arn = aws_iam_role.s3_datasync_role.arn
  }
}

# See https://aws.amazon.com/blogs/security/writing-iam-policies-how-to-grant-access-to-an-amazon-s3-bucket/
 
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = <<POLICY
 {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": [${aws_s3_bucket.bucket.arn}]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["${aws_s3_bucket.bucket.arn}/*"]
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_policy" "bucket_user_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketLocation",
        "s3:ListAllMyBuckets"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": [${aws_s3_bucket.bucket.arn}]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["${aws_s3_bucket.bucket.arn}/*"]
    }
  ]
}
POLICY
}
