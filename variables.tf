variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "aws_region" {
  description = "AWS region"
  type = string
  default = "us-east-1"
}

variable "vpc_id" {}

variable "subnet_id" {}

variable "root_volume_type" {
  description = "Type of root volume"
  type = string
  default = "gp2"
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type = number
  default = 35
}

variable "root_iops" {
  description = "Amount of provisioned IOPS"
  type = number
  default = 0
}

variable "delete_on_termination" {
  description = "Volume get destroyed on instance termination"
  type = bool
  default = true
}

variable "instance_name" {
  default = "win2019-sa1"
}

variable "instance_username" {
  default = "winadmin1"
}

variable "instance_password" {
  default = ""
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  default = "WindowsSQL1"
}

variable "local_public_ip" {
  default = "0.0.0.0/0"
}