//basically telling terraform what cloud service we are going to Use 
//cause terraform is kinda dumb

terraform {
  required_version = ">= 1.6.0"
  //if you wanted to use azure or even like github you would put it here
  //in the required providers. the required providers is just basically telling
  //terraform which cloud tool you wanna use
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

//tells terraform configuration info about the aws provider 
//tells it when creating anything from the aws provider, you put it in the 
//region us-east-1

provider "aws" {
  region = "us-east-1"
}
//fetches the latest Amazon Linux 2023 x86_64 AMI
data "aws_ssm_parameter" "al2023_x86" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}
/*
// creates a tiny free-tier EC2 instance
resource "aws_instance" "vm" {
  ami           = data.aws_ssm_parameter.al2023_x86.value
  instance_type = "t3.micro"

  tags = {
    Name        = "tf-demo"
    Owner       = "Jay"
    Environment = "dev"
  }
}
*/
//this creates a remote backend where i can store my state file into a 
//s3 bucket so that this is a team-ready infrastructure.
//this makes it so that multiple people can safely use terraform at the same time.

terraform {
  backend "s3" {
    bucket = "jays-terraform-aws-state"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

//creates a subnet
data "aws_subnet" "private_subnet" {
  id = "subnet-04f024821ad29e4ee"
}

//basically creating a firewall that only allows 
//traffic on port 80 to reach my EC2 instance, 
//but only from within my subnet that i created above
resource "aws_security_group" "ec2_sg" {
  vpc_id = data.aws_subnet.private_subnet.vpc_id

  ingress {
    cidr_blocks = [data.aws_subnet.private_subnet.cidr_block]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
}

//attaching the firewall that we created to the ec2 instance that
//we created
resource "aws_instance" "vm" {
  ami           = data.aws_ssm_parameter.al2023_x86.value
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  tags = {
    Name = "My first EC2 instance"
  }
}
