data "aws_region" "current" {}
 
resource "aws_vpc" "main" {
 cidr_block = "10.0.0.0/16"
}
 
resource "aws_internet_gateway" "gw" {
 vpc_id = aws_vpc.main.id
}
 
resource "aws_subnet" "main" {
 vpc_id            = aws_vpc.main.id
 cidr_block        = aws_vpc.main.cidr_block
 availability_zone = "${data.aws_region.current.name}a"
}
 
resource "aws_route_table" "rt" {
 vpc_id = aws_vpc.main.id
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.gw.id
 }
}
 
resource "aws_route_table_association" "mfi_route_table_association" {
 subnet_id      = aws_subnet.main.id
 route_table_id = aws_route_table.rt.id
}
 
resource "aws_key_pair" "aws_key" {
 key_name   = "ssh-key"
 public_key = file(var.public_key)
}
 
resource "aws_security_group" "allow_http" {
 name        = "allow_http"
 description = "Allow HTTP traffic"
 vpc_id      = aws_vpc.main.id
 ingress {
   description = "HTTP"
   from_port   = 80
   to_port     = 80
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
 
resource "aws_security_group" "allow_ssh" {
 name        = "allow_ssh"
 description = "Allow SSH traffic"
 vpc_id      = aws_vpc.main.id
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
