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

# data "aws_iam_policy_document" "ec2_assume_role" {
#   statement {
#     actions = ["sts:AssumeRole",]
#     principals {
#       identifiers = ["ec2.amazonaws.com"]
#       type = "Service"
#     }
#   }
# }

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
  # policy = <<POLICY
# {
  #   "Version": "2012-10-17",
  #   "Statement": [
  #       {
  #         "Sid":"PolicyForAllowUploadWithACL",
  #         "Effect":"Allow",
  #         "Action":"s3:*",
  #         "Resource":"arn:aws:s3:::genetic-risk-index-bucket/*",
  #         "Condition": {
  #              "StringEquals": {"s3:x-amz-acl":"bucket-owner-full-control"}
  #         }
  #       }
  #   ]
# }
# POLICY
}

# resource "aws_datasync_location_efs" "this" {
  # depends_on = [aws_instance.datasync-instance]

  # server_hostname = aws_efs_file_system.efs-storage.dns_name
  # subdirectory  = "${var.datasync_location_s3_subdirectory}"

  # on_prem_config {
    # agent_arns = ["${aws_datasync_agent.datasync-agent.arn}"]
  # }
# }

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

# resource "aws_iam_role" "datasync-instance-role" {
#   name = "${var.project}-instance-role"
#   assume_role_policy = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#     {
#         "Action": "sts:AssumeRole",
#         "Effect": "Allow",
#         "Principal": {
#             "Service": "ec2.amazonaws.com"
#         }
#     }
#     ]
# }
# EOF
# }

# resource "aws_iam_role_policy_attachment" "instance_role" {
  # role       = aws_iam_role.datasync-instance-role.name
  # policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
# }

# resource "aws_iam_role_policy" "datasync-instance-policy" {
#   name   = "${var.project}-datasync-policy"
#   role   = "${aws_iam_role.datasync-instance-role.name}"
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": "datasync:*",
#       "Resource": "*"
#     },
#     {
#       "Effect": "Allow",
#       "Action": "ec2:*",
#       "Resource": "*"
#     },
#     {
#       "Effect": "Allow",
#       "Action": "elasticfilesystem:Describe*",
#       "Resource": "${aws_efs_file_system.efs-storage.arn}"
#     }
#   ]
# }
# EOF
#       # ${aws_datasync_task.this.arn}"
# }

resource "aws_cloudwatch_log_resource_policy" "this" {
  policy_document = "${data.aws_iam_policy_document.cloudwatch_log_group.json}"
  policy_name     = "${var.project}-datasync-clw-policy"
}

resource "aws_cloudwatch_log_group" "this" {
  name = "${var.project}-datasync-log-group"
  retention_in_days = 14
}

# resource "aws_iam_instance_profile" "datasync-instance-profile" {
#   name = "${var.project}-datasync-instance-profile"
#   role = "${aws_iam_role.datasync-instance-role.name}"

#   lifecycle {
#     create_before_destroy = false
#   }
# }

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

# data "aws_ami" "datasync-ami" {
#   most_recent = true
#   owners = ["633936118553"] # AMZN
#   filter {
#     name   = "name"
#     values = ["aws-datasync-*"]
#   }
# }

# resource "aws_instance" "datasync-instance" {
#   ami = "${data.aws_ami.datasync-ami.id}"
#   instance_type = "t3.micro"
#   instance_initiated_shutdown_behavior = "stop"
#   iam_instance_profile = aws_iam_instance_profile.datasync-instance-profile.name

#   disable_api_termination = false
#   key_name = aws_key_pair.aws_key.key_name

#   vpc_security_group_ids = ["${aws_security_group.datasync-instance.id}"]
#   subnet_id = aws_subnet.subnet.id
#   associate_public_ip_address = true

#   tags = {
#     Name = "${var.project}-datasync-agent-instance"
#   }
# }

# resource "aws_datasync_agent" "datasync-agent" {
#   depends_on = [aws_instance.datasync-instance]
#   ip_address = aws_instance.datasync-instance.public_ip
#   name       = "${var.project}-datasync-agent"
#   subnet_arns = [aws_subnet.subnet.arn,]
#   lifecycle {
#     create_before_destroy = false
#   }
# }

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
  destination_location_arn = "${aws_datasync_location_efs.this.arn}"
  source_location_arn      = "${aws_datasync_location_s3.this.arn}"
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
