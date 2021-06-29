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

# resource "aws_s3_bucket_policy" "b" {
#   bucket = aws_s3_bucket.b.id
#   # Terraform's "jsonencode" function converts a
#   # Terraform expression's result to valid JSON syntax.
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Id      = "MYBUCKETPOLICY"
#     Statement = [
#       {
#         Sid       = "IPAllow"
#         Effect    = "Deny"
#         Principal = "*"
#         Action    = "s3:*"
#         Resource = [
#           aws_s3_bucket.b.arn,
#           "${aws_s3_bucket.b.arn}/*",
 #         ]
 #         Condition = {
 #           IpAddress = {
 #             "aws:SourceIp" = "8.8.8.8/32"
 #           }
 #         }
 #       },
 #     ]
 #   })
 # }

 # Command to use the datasync
 # aws datasync start-task-execution --task-arn '$(terraform output efs-data-backup-arn)`
