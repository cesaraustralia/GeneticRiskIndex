resource "aws_vpc" "security" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = { Project = "${var.project}" }
}
 
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.security.id
  tags = { Project = "${var.project}" }
}
 
resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.security.id
  cidr_block        = aws_vpc.security.cidr_block
  availability_zone = var.aws_availability_zone
  tags = { Project = "${var.project}" }
}
 
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.security.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = { Project = "${var.project}" }
}
 
resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rt.id
}
 
resource "aws_security_group" "security" {
  name        = "${var.project}-security"
  description = "Allow SSH, HTTP and EFS connection"
  vpc_id      = aws_vpc.security.id
  tags = { Project = "${var.project}" }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "EFS mount target"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSHC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
