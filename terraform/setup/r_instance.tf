



resource "aws_instance" "r" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.r_instance_type
  key_name = aws_key_pair.aws_key.key_name
  associate_public_ip_address = true
  subnet_id = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.allow_http.id, aws_security_group.allow_ssh.id]

  tags = {
    Name = "${var.project}-r"
  }

  # Run ansible to install R on the instance
  # We need `sleep 120` to let the instance start
  provisioner "local-exec" {
    command = "sleep 120; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -i '${self.public_ip},' --private-key ${var.private_key} -e 'pub_key=${var.public_key}' ../../ansible/r.yml"
  }
}
