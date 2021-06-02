data "aws_ami" "r-ami" {
  most_recent = true
  owners = ["self"]
  filter {                       
    name = "tag:Application"     
    values = ["genetic-risk-index-r-ami"]
  }                              
}

# We build the instance from our
# pre-made AMI so we can iterate more quikly 
# developing this one, without having to provision 
# everything every time.
resource "aws_instance" "r" {
  ami = aws_ami_from_instance.r-ami.id
  instance_type = var.r_instance_type
  key_name = aws_key_pair.aws_key.key_name
  associate_public_ip_address = true
  availability_zone = var.aws_availability_zone
  subnet_id = aws_subnet.subnet.id

  vpc_security_group_ids = [aws_security_group.security.id]

  tags = {
    Name = "${var.project}-r"
  }

  connection {
    host        = self.public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.key.private_key_pem
  }

  # Mount the shared EFS hard drive using nfs.
  # EFS is not as easy to mount as EBS, but allows 
  # connecting many instances to the same drive later.
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y install nfs-common",
      # make a mount point
      "sudo mkdir -p /mnt/efs2",
      # mount the efs volume
      "sudo mount ${aws_efs_mount_target.efs-storage.dns_name}:/ /mnt/efs2",
      # "sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_mount_target.efs-storage.dns_name}:/ /mnt/efs",
      # create fstab entry to ensure automount on reboots
      # https://docs.aws.amazon.com/efs/latest/ug/mount-fs-auto-mount-onreboot.html#mount-fs-auto-mount-on-creation
      # "sudo su -c \"echo '${aws_efs_mount_target.efs-storage.dns_name}:/ /mnt/efs nfs4 defaults,vers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0' >> /etc/fstab\"" #create fstab entry to ensure automount on reboots
    ]
  }

  # provisioner "remote-exec" {
    # command = "link -s /etc/efs-storage/taxon/${each.key} ~/taxon_data"
  # }

}

output "instance_ip" {
  description = "The public ip for ssh access"
  value       = aws_instance.r.public_ip
}
