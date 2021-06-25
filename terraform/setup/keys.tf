resource "tls_private_key" "key" {
  algorithm = "RSA"
}

# Saving Key Pair for ssh login for client
resource "local_file" "public_key_openssh" {
  content = "${tls_private_key.key.public_key_openssh}"
  filename = "${var.public_key_openssh}"
}
resource "local_file" "public_key" {
  content = "${tls_private_key.key.public_key_pem}"
  filename = "${var.public_key}"
}
resource "local_file" "private_key" {
  content = "${tls_private_key.key.private_key_pem}"
  filename = "${var.private_key}"
  file_permission = "0400"
}

resource "aws_key_pair" "aws_key" {
  key_name   = "key"
  public_key = tls_private_key.key.public_key_openssh
}
