resource "aws_instance" "r" {
  ami           = lookup(var.ami, var.aws_region)
  instance_type = var.r_instance_type

  tags = {
    Name = "${var.project}-r"
  }

  # Dummy task to make local-exec wait until the instance is ready
  provisioner "remote-exec" {
    inline = ["echo Connected successfully!"]

    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "root"
      private_key = file(var.private_key)
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${self.public_ip},' --private-key ${var.private_key} -e 'pub_key=${var.public_key}' ../ansible/r.yml"
  }
}
