//basically creating a module so that this is reusable and not everything is cramped in the main file



data "aws_subnet" "private_subnet" {
  id = "subnet-04f024821ad29e4ee"
}

# Security group that allows HTTP from that subnet
resource "aws_security_group" "ec2_sg" {
  vpc_id = data.aws_subnet.private_subnet.vpc_id

  ingress {
    cidr_blocks = [data.aws_subnet.private_subnet.cidr_block]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
}

//fetches the ami image
data "aws_ssm_parameter" "al2023_x86" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}
# EC2 instance that uses the SG
resource "aws_instance" "vm" {
  ami           = data.aws_ssm_parameter.al2023_x86.value
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  tags = {
    Name = "My first EC2 instance"
  }
}