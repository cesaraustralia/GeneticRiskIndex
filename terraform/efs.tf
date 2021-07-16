# Define an EFS drive to share between all containers

resource "aws_efs_file_system" "efs-storage" {
  creation_token = "efs-storage"
  availability_zone_name = var.aws_availability_zone

  tags = {
    Name = "efs-storage",
    Project = var.project
  }
}

resource "aws_efs_access_point" "efs-storage" {
  file_system_id = aws_efs_file_system.efs-storage.id
  tags = { Project = var.project }
}

resource "aws_efs_mount_target" "efs-storage" {
  file_system_id = aws_efs_file_system.efs-storage.id
  subnet_id = aws_subnet.subnet.id
  security_groups = [aws_security_group.security.id]
}

# Virtual private network details for efs connections (efs is a network drive)
resource "aws_vpc" "efs-storage" {
  cidr_block = "10.0.0.0/16"
  tags = { Project = var.project }
}
