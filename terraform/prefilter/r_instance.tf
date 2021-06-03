provider "aws" {
  region = var.aws_region
}

data "aws_ami" "r" {
  most_recent = true
  owners = ["self"]
  filter {
    name   = "name"
    values = ["${var.project}-r-ami"]
  }
}

data "aws_subnet" "subnet" {
  tags = { Project = "${var.project}" }
}
 
data "aws_security_group" "security" {
  tags = { Project = "${var.project}" }
}

# We build the instance from our
# pre-made AMI so we can iterate more quikly 
# developing this one, without having to provision 
# everything every time.
resource "aws_instance" "r" {
  ami = data.aws_ami.r.id
  instance_type = var.r_instance_type
  key_name = "key"
  associate_public_ip_address = true
  availability_zone = var.aws_availability_zone
  subnet_id = data.aws_subnet.subnet.id

  vpc_security_group_ids = [data.aws_security_group.security.id]

  tags = {
    Name = "${var.project}-r"
  }

  # provisioner "local-exec" {
    # command = "link -s /etc/efs-storage/taxon/${each.key} ~/taxon_data"
  # }

}

output "instance_ip" {
  description = "The public ip for ssh access"
  value       = aws_instance.r.public_ip
}
