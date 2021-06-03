# This instance will be the image we use in our Fargate
# container later on. For now we just install julia on it.
resource "aws_instance" "julia-ami-template" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.julia_instance_type
  key_name = aws_key_pair.aws_key.key_name
  associate_public_ip_address = true
  subnet_id = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.security.id]

  tags = {
    Name = "${var.project}-julia-ami-template"
  }

  connection {
    host        = self.public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key)
  }

  # Mount the shared EFS hard drive using nfs.
  # EFS is not as easy to mount as EBS, but allows 
  # connecting many instances to the same drive later.
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y install nfs-common ",
      "sudo apt-get update",
      "sudo apt-get -y install git binutils",
      "git clone https://github.com/aws/efs-utils",
      "cd efs-utils",
      "./build-deb.sh",
      "sudo apt-get -y install ./build/amazon-efs-utils*deb",
      # "sudo mount -t efs -o tls ${var.file_system_id} /mnt/efs"
      "echo '${aws_efs_file_system.efs-storage.id}:/ /mnt/efs efs vers=4.1,rw,tls,_netdev,relatime,acl,nofail 0 0' | sudo tee -a /etc/fstab"
    ]
  }

  # Run ansible to install julia on the instance
  # We need `sleep 120` to let the instance start
  provisioner "local-exec" {
    command = "sleep 120; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -i '${self.public_ip},' --private-key ${var.private_key} -e 'pub_key=${var.public_key}' ../../ansible/julia/julia.yml"
  }
}

# Create an ami image for julia tasks
resource "aws_ami_from_instance" "julia-ami" {
  name = "${var.project}-julia-ami"
  depends_on = [aws_instance.julia-ami-template]
  source_instance_id = aws_instance.julia-ami-template.id
}
