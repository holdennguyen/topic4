terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~>3.0"
      }
    }
}

# Configure the AWS provider 
provider "aws" {
    region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "Topic4-VPC"{
    cidr_block = var.cidr_block[0]
    tags = {
        Name = "Topic4-VPC"
    }
}

# Create Subnet (Public) for EC2 Ansible Controller
resource "aws_subnet" "Topic4-Subnet1" {
    vpc_id = aws_vpc.Topic4-VPC.id
    cidr_block = var.cidr_block[1]
    tags = {
        Name = "Topic4-Subnet1"
    }
}

# Create Subnet (Public) for EC2 Deploy Nginx
resource "aws_subnet" "Topic4-Subnet2" {
    vpc_id = aws_vpc.Topic4-VPC.id
    cidr_block = var.cidr_block[2]
    tags = {
        Name = "Topic4-Subnet2"
    }
}

# Create Internet Gateway
resource "aws_internet_gateway" "Topic4-IGW" {
    vpc_id = aws_vpc.Topic4-VPC.id
    tags = {
        Name = "Topic4-IGW"
    }
}

# Create Security Group
resource "aws_security_group" "Topic4-SG" {
    name = "Topic4-SG"
    description = "To allow inbound and outbount traffic to Topic4"
    vpc_id = aws_vpc.Topic4-VPC.id
    dynamic ingress {
        iterator = port
        for_each = var.ports
            content {
              from_port = port.value
              to_port = port.value
              protocol = "tcp"
              cidr_blocks = ["0.0.0.0/0"]
            }
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "allow traffic"
    }
}

# Create route table and association
resource "aws_route_table" "Topic4-rtb" {
    vpc_id = aws_vpc.Topic4-VPC.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.Topic4-IGW.id
    }
    tags = {
        Name = "Topic4-rtb"
    }
}

resource "aws_route_table_association" "Topic4-rtba" {
    subnet_id = aws_subnet.Topic4-Subnet1.id
    route_table_id = aws_route_table.Topic4-rtb.id
}

# Create an AWS EC2 Instance to host Jenkins
resource "aws_instance" "Jenkins" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name = "ec2"
  vpc_security_group_ids = [aws_security_group.Topic4-SG.id]
  subnet_id = aws_subnet.Topic4-Subnet1.id
  associate_public_ip_address = true
  user_data = file("./InstallJenkins.sh")

  tags = {
    Name = "Jenkins-Server"
  }
}

# Create an AWS EC2 Instance to host Ansible Controller (Control node)
resource "aws_instance" "Ansible-Controller" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name = "ec2"
  vpc_security_group_ids = [aws_security_group.Topic4-SG.id]
  subnet_id = aws_subnet.Topic4-Subnet1.id
  associate_public_ip_address = true
  user_data = file("./InstallAnsibleController.sh")

  tags = {
    Name = "Ansible-Controller"
  }
}

#Create an AWS EC2 Instance to host Apache Tomcat server (Ansible Manage Node) 
resource "aws_instance" "AnsibleMN-ApacheTomcat" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name = "ec2"
  vpc_security_group_ids = [aws_security_group.Topic4-SG.id]
  subnet_id = aws_subnet.Topic4-Subnet1.id
  associate_public_ip_address = true
  user_data = file("./InstallDocker.sh")

  tags = {
    Name = "AnsibleMN-DockerDev"
  }
}

#Create an AWS EC2 Instance to host Docker (Ansible Manage Node) 
resource "aws_instance" "AnsibleMN-DockerHost" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name = "ec2"
  vpc_security_group_ids = [aws_security_group.Topic4-SG.id]
  subnet_id = aws_subnet.Topic4-Subnet1.id
  associate_public_ip_address = true
  user_data = file("./InstallDocker.sh")

  tags = {
    Name = "AnsibleMN-DockerMain"
  }
}