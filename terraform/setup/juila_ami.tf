# This instance will be the image we use in our Fargate
# container later on. For now we just install julia on it.
resource "aws_instance" "julia-ami-template" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.julia_instance_type
  key_name = aws_key_pair.aws_key.key_name
  associate_public_ip_address = true
  subnet_id = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.allow_http.id, aws_security_group.allow_ssh.id]

  tags = {
    Name = "${var.project}-julia"
  }

  # Run ansible to install julia on the instance
  # We need `sleep 120` to let the instance start
  provisioner "local-exec" {
    command = "sleep 120; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -i '${self.public_ip},' --private-key ${var.private_key} -e 'pub_key=${var.public_key}' ../../ansible/julia/julia.yml"
  }
}

# Create an ami image from the 
resource "aws_ami_from_instance" "julia-ami" {
  name = "julia-ami"
  depends_on = [aws_instance.julia-ami-template]
  source_instance_id = aws_instance.julia-ami-template.id
}
