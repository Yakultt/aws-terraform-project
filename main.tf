//basically telling terraform what cloud service we are going to Use 
//cause terraform is kinda dumb
terraform {
  required_version = ">= 1.13.0"
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
