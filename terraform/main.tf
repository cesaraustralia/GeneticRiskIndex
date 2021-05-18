provider "aws" {
  region = "ap-southeast-2" 
}

variable "ami" {
  type = "map"

  default = {
    "ap-southeast-2" = "ami-0ae0b19a90d6da41b" # see https://cloud-images.ubuntu.com/locator/ec2/
  }
}

variable "instance_count" {
  default = "200"
}

variable "instance_type" {
  default = "t2.small"
}

variable "aws_region" {
  default = "ap-southeast-2"
}

resource "aws_key_pair" "cesar_aws" {
  key_name   = "cesar_aws"
  public_key = file("cesar_aws.pub")
}

resource "aws_instance" "r_gis" {
  ami           = lookup(var.ami, var.aws_region)
  instance_type = var.instance_type

  tags = {
    Name = "risk-index-gis"
  }

  provisioner "remote-exec" {
    inline = ["sudo apt update", "sudo apt install python3 -y", "echo Done!"]

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = file(var.pvt_key)
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${self.ipv4_address},' --private-key ${var.pvt_key} -e 'pub_key=${var.pub_key}' r_instance.yml"
  }
}

resource "aws_instance" "julia_circuitscape" {
  count         = var.instance_count
  ami           = lookup(var.ami, var.aws_region)
  key_name      = aws_key_pair.cesar_aws.key_name
  instance_type = var.instance_type
  user_data     = file("run_julia.sh")

  tags = {
    Name = "risk-index-circuitscape-${count.index + 1}"
  }

  provisioner "remote-exec" {
    inline = ["sudo apt update", "sudo apt install python3 -y", "echo Done!"]

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = file(var.pvt_key)
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${self.ipv4_address},' --private-key ${var.pvt_key} -e 'pub_key=${var.pub_key}' julia_instance.yml"
  }
}
