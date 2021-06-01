
# Instances #########################

# This instance will be the image we use in our Fargate
# container later on. For now we just install julia on it.
resource "aws_instance" "julia-ami-template" {
  ami           = lookup(var.ami, var.aws_region)
  key_name      = aws_key_pair.keys.key_name
  instance_type = var.julia_instance_type

  tags = {
    Name = "{var.project}-julia}"
  }

  provisioner "remote-exec" {
    inline = ["echo Connected successfully!"]
    connection {
      host = self.public_ip
      type = "ssh"
      user = "root"
      private_key = file(var.private_key)
    }
  }

  # Run ansible to install julia on the instance
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${self.public_ip},' --private-key ${var.private_key} -e 'pub_key=${var.public_key}' ../ansible/julia.yml"
  }
}

# Create an ami image from the 
resource "aws_ami_from_instance" "julia-ami" {
  name = "julia-ami"
  depends_on = [aws_instance.julia-ami-template]
  source_instance_id = aws_instance.julia-ami-template.id
}
