resource "aws_instance" "r" {
  ami           = lookup(var.ami, var.aws_region)
  instance_type = var.r_instance_type

  tags = {
    Name = "${var.project}-r"
  }

  # Dummy task to make local-exec wait until the instance is ready
  provisioner "remote-exec" {
    inline = ["echo Connedcted successfully!"]

    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "root"
      private_key = file(var.pvt_key)
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${self.public_ip},' --private-key ${var.pvt_key} -e 'pub_key=${var.pub_key}' ../ansible/r.yml"
  }
}
