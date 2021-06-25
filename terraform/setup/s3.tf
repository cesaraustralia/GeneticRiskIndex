data "aws_s3_bucket" "bucket" {
   bucket = var.s3_bucket
}

resource "aws_datasync_location_s3" "data" {
  s3_bucket_arn = data.aws_s3_bucket.bucket.arn
  subdirectory  = "/data"
  s3_config {
    bucket_access_role_arn = aws_iam_role.aws_batch_service_role.arn
  }
}

# Command to use the datasync
# aws datasync start-task-execution --task-arn '$(terraform output efs-data-backup-arn)`
