# See https://github.com/asaphe/terraform-aws-datasync

data "aws_iam_policy_document" "cloudwatch_log_group" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
    ]
    resources = ["${aws_cloudwatch_log_group.this.arn}"]
    principals {
      identifiers = ["datasync.amazonaws.com"]
      type = "Service"
    }
  }
}

data "aws_iam_policy_document" "datasync_assume_role" {
  statement {
    actions = ["sts:AssumeRole",]
    principals {
      identifiers = ["datasync.amazonaws.com"]
      type = "Service"
    }
  }
}

data "aws_iam_policy_document" "bucket_access" {
  statement {
    actions = ["s3:*",]
    resources = [
      "${data.aws_s3_bucket.bucket.arn}",
      "${data.aws_s3_bucket.bucket.arn}:/*",
      "${data.aws_s3_bucket.bucket.arn}:job/*"
    ]
  }
}

resource "aws_iam_role" "datasync-s3-access-role" {
  name               = "${var.project}-datasync-s3-access-role"
  assume_role_policy = "${data.aws_iam_policy_document.datasync_assume_role.json}"
}

resource "aws_iam_role_policy" "datasync-s3-access-policy" {
  name   = "${var.project}-datasync-s3-access-policy"
  role   = "${aws_iam_role.datasync-s3-access-role.name}"
  policy = "${data.aws_iam_policy_document.bucket_access.json}"
}

resource "aws_datasync_location_efs" "this" {
  # The below example uses aws_efs_mount_target as a reference to ensure a mount target already exists when resource creation occurs.
  # You can accomplish the same behavior with depends_on or an aws_efs_mount_target data source reference.
  efs_file_system_arn = aws_efs_mount_target.efs-storage.file_system_arn

  ec2_config {
    security_group_arns = [aws_security_group.security.arn, aws_security_group.datasync-security.arn]
    subnet_arn = aws_subnet.subnet.arn
  }
}

resource "aws_datasync_location_s3" "this" {
  s3_bucket_arn = "${data.aws_s3_bucket.bucket.arn}"
  subdirectory  = "${var.datasync_location_s3_subdirectory}"

  s3_config {
    bucket_access_role_arn = "${aws_iam_role.datasync-s3-access-role.arn}"
  }

  tags = {
    Name = "${var.project}-datasync-location-s3"
  }
}

resource "aws_cloudwatch_log_resource_policy" "this" {
  policy_document = "${data.aws_iam_policy_document.cloudwatch_log_group.json}"
  policy_name     = "${var.project}-datasync-clw-policy"
}

resource "aws_cloudwatch_log_group" "this" {
  name = "${var.project}-datasync-log-group"
  retention_in_days = 14
}

resource "aws_security_group" "datasync-security" {
  name        = "${var.project}-datasync-security"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${aws_vpc.vpc.cidr_block}"]
    description = "SSH"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${aws_vpc.vpc.cidr_block}"]
    description = "HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${aws_vpc.vpc.cidr_block}"]
    description = "HTTPS"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for Datasync agent to AWS Service endpoint"
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS"
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS"
  }

  egress {
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "NTP"
  }

  egress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "EFS/NFS"
  }

  tags = {
    Name = "${var.project}-datasync-agent",
  }
}

resource "aws_datasync_task" "backup" {
  name                     = "${var.project}-datasync-backup"
  source_location_arn      = "${aws_datasync_location_efs.this.arn}"
  destination_location_arn = "${aws_datasync_location_s3.this.arn}"
  cloudwatch_log_group_arn = "${join("", split(":*", aws_cloudwatch_log_group.this.arn))}"

  options {
    bytes_per_second       = -1
    verify_mode            = "${var.datasync_task_options["verify_mode"]}"
    posix_permissions      = "${var.datasync_task_options["posix_permissions"]}"
    preserve_deleted_files = "${var.datasync_task_options["preserve_deleted_files"]}"
    uid                    = "${var.datasync_task_options["uid"]}"
    gid                    = "${var.datasync_task_options["gid"]}"
    atime                  = "${var.datasync_task_options["atime"]}"
    mtime                  = "${var.datasync_task_options["mtime"]}"
  }
}

resource "aws_datasync_task" "restore" {
  name                     = "${var.project}-datasync-restore"
  source_location_arn      = "${aws_datasync_location_s3.this.arn}"
  destination_location_arn = "${aws_datasync_location_efs.this.arn}"
  cloudwatch_log_group_arn = "${join("", split(":*", aws_cloudwatch_log_group.this.arn))}"

  options {
    bytes_per_second       = -1
    verify_mode            = "${var.datasync_task_options["verify_mode"]}"
    posix_permissions      = "${var.datasync_task_options["posix_permissions"]}"
    preserve_deleted_files = "${var.datasync_task_options["preserve_deleted_files"]}"
    uid                    = "${var.datasync_task_options["uid"]}"
    gid                    = "${var.datasync_task_options["gid"]}"
    atime                  = "${var.datasync_task_options["atime"]}"
    mtime                  = "${var.datasync_task_options["mtime"]}"
  }
}

output "backup-arn" {
  description = "ARB for data backup task"
  value = aws_datasync_task.backup.arn
}

output "restore-arn" {
  description = "ARB for data restore task"
  value = aws_datasync_task.restore.arn
}
