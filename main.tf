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

//creating the acutal resource
resource "aws_instance" "first_ec2_instance" {
  ami           = data.aws_ssm_parameter.al2023_x86.value
  instance_type = "t3.micro"

  tags = {
    Name        = "tf-demo"
    Owner       = "Jay"
    Environment = "dev"
  }
}
