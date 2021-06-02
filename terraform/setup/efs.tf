resource "aws_efs_file_system" "efs-storage" {
  creation_token = "efs-storage"

  tags = {
    Name = "efs-storage"
  }
}

resource "aws_efs_access_point" "efs-storage" {
  file_system_id = aws_efs_file_system.efs-storage.id
}

resource "aws_efs_file_system_policy" "policy" {
  file_system_id = aws_efs_file_system.efs-storage.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "ExamplePolicy01",
    "Statement": [
        {
            "Sid": "ExampleStatement01",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Resource": "${aws_efs_file_system.efs-storage.arn}",
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "true"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_efs_mount_target" "efs-storage" {
  file_system_id = aws_efs_file_system.efs-storage.id
  subnet_id = aws_subnet.subnet.id
  security_groups = [aws_security_group.security.id]
}

resource "aws_vpc" "efs-storage" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.efs-storage.id
  availability_zone = var.aws_availability_zone
  cidr_block        = "10.0.1.0/24"
}

