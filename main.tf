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

#creates the network ip address
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}
#connects the vpc to the internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "main-igw"
  }
}

#creates a subnet within the network ip address that I
#created above so that the ec2 instances i launch will
#have this ip address
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  #makes sure that every ec2 instance gets internet access
  #whenever they launch
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_route_table" "public_rt" {
  #attaches the route table to my vpc
  vpc_id = aws_vpc.main_vpc.id

  route {
    #0.0.0.0/0 captures all traffic so any traffic going anywhere should
    #go to the internet gateway that i created
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

#attaching the route table to my subnet so that the subnet
#can actually use it
resource "aws_route_table_association" "public_rt_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

#attaching my public key to the ec2 instance so i can login
#via a ssh key and not password
resource "aws_key_pair" "existing_key" {
  key_name   = "harit-macbook-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

#creating firewall rules for ec2 instance
resource "aws_security_group" "allow_ssh_http_https" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8443
    to_port = 8443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-ssh-https-http"
  }
}

resource "aws_instance" "ubuntu_instance" {
  ami                         = "ami-0a0e5d9c7acc336f1"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh_http_https.id]
  key_name                    = aws_key_pair.existing_key.key_name
  associate_public_ip_address = true
  #makes sure that the firewall rules and the internet gateway is created before creating this instance
  depends_on = [
    aws_security_group.allow_ssh_http_https,
    aws_internet_gateway.igw
  ]
  #the startup script that runs automatically whenvever an instance is created
user_data = <<-EOF
#!/bin/bash
apt update -y
apt upgrade -y
apt install -y nginx git
useradd -m -s /bin/bash jay
usermod -aG sudo jay
#clone my ctf files repo
cd /tmp
git clone https://github.com/Yakultt/CTF-Blog-Post.git
#move the website files into nginx's root directory
cp -r /tmp/CTF-Blog-Post/* /var/www/html/
#editing the nginx config file so that nginx will make it so that the server name is haritsook
cat <<EOT > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name haritsook.com www.haritsook.com;

    root /var/www/html;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOT
systemctl restart nginx

EOF

  tags = {
    Name = "ubuntu-instance"
  }
}

#outputting the ip address address of the ec2 instance i made so that i can ssh into it right away
output "ubuntu_instance_public_ip" {
  value = aws_instance.ubuntu_instance.public_ip
}