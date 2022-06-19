provider "aws" {
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
    region = var.aws_region
}

resource "aws_security_group" "winrm_sg" {
  name        = "win2019"
  description = "Used in the terraform"
  vpc_id = var.vpc_id

   ingress {
    description      = "RDP Access"
    from_port        = 3389
    to_port          = 3389
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "WinRM Access"
    from_port   = 5985
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

   egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "windows_server" {
    ami = data.aws_ami.windows-2019.id
    instance_type = "t2.micro"
    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.winrm_sg.id]
    subnet_id = var.subnet_id

    root_block_device {
      volume_type = var.root_volume_type
      volume_size = var.root_volume_size
      iops = var.root_iops
      delete_on_termination = var.delete_on_termination
    }

    user_data = data.template_file.windows-userdata.rendered

    connection {
        host = coalesce(self.public_ip, self.private_ip)
        type = "winrm"
        port = 5986
        user = var.instance_username
        password = var.instance_password
        https = true
        insecure = true
        timeout = "4m"
    }

    provisioner "file" {
      source = "sample.ps1"
      destination = "C:/sample.ps1"
    }

    provisioner "remote-exec" {
      inline = [         
          "powershell.exe -ExecutionPolicy Bypass -File C:/sample.ps1"
      ]
    }


    tags = {
      Name = "windows-server-vm"
      Environment = "test"
    }
}

resource "aws_eip" "windows_eip" {
  instance = aws_instance.windows_server.id
  vpc = true
}

resource "aws_eip_association" "eip_assoc" {
  instance_id = aws_instance.windows_server.id
  allocation_id = aws_eip.windows_eip.id
}