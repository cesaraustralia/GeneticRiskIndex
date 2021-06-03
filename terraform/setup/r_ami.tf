resource "aws_instance" "r-ami-template" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.r_instance_type
  key_name = aws_key_pair.aws_key.key_name
  associate_public_ip_address = true
  subnet_id = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.security.id]

  tags = { Name = "${var.project}-r-ami-template" }

  connection {
    host        = self.public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key)
  }

  # Mount the shared EFS hard drive using nfs.
  # EFS is not as easy to mount as EBS, but allows 
  # connecting many instances to the same drive later.
  # TODO make this into an ansible playbook
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y install nfs-common ",
      "sudo apt-get update",
      "sudo apt-get -y install git binutils",
      "git clone https://github.com/aws/efs-utils",
      "cd efs-utils",
      "./build-deb.sh",
      "sudo apt-get -y install ./build/amazon-efs-utils*deb",
      "cd ~/",
      "sudo rm -R efs-utils",
      "mkdir data",
      "sudo mount -t efs -o tls ${aws_efs_file_system.efs-storage.id} data",
      "sudo chown -R ubuntu data",
      "echo '${aws_efs_file_system.efs-storage.id}:/ /home/ubuntu/data/ efs uid=1000,vers=4.1,rw,tls,_netdev,relatime,acl,nofail 0 0' | sudo tee -a /etc/fstab"
    ]
  }

  # Run ansible to install r on the instance
  # We need `sleep 120` to let the instance start
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -i '${self.public_ip},' --private-key ${var.private_key} -e 'pub_key=${var.public_key}' ../../ansible/r/r.yml"
  }
}

# Create an ami image from the 
resource "aws_ami_from_instance" "r-ami" {
  name = "${var.project}-r-ami"
  depends_on = [aws_instance.r-ami-template]
  source_instance_id = aws_instance.r-ami-template.id
}
