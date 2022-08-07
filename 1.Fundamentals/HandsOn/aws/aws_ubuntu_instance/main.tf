#Deploy a single server


provider "aws" {
  region = "us-east-2"
  shared_credentials_files = ["$Home/.aws/credentials"]

}

variable "server_port"{
  description = "The port the server will use for http request"
  type = number
  default = 8080

}
resource "aws_vpc" "vpc" {
  cidr_block           = "192.168.1.0/24"
  enable_dns_hostnames = true

  tags = {
    Name = "terraform.example"
  }
}

resource "aws_internet_gateway" "ig" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name = "terraform.example"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "192.168.1.0/24"

  tags = {
    Name = "terraform.example"
  }
}


resource "aws_route_table" "rt" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ig.id}"
  }
}


resource "aws_security_group" "instance" {
  name        = "allow_inbound"
  description = "Allow inbound traffic"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    description      = "Allow inbound from internet"
    from_port        = var.server_port
    to_port          = var.server_port
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

 ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "22"
    to_port     = "22"
  }

  egress {
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    to_port     = "0"
  }


  tags = {
    Name = "terraform.example"
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = "${aws_subnet.subnet.id}"
  route_table_id = "${aws_route_table.rt.id}"
}

resource "aws_instance" "example" {
  ami = "ami-02f3416038bdb17fb"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.subnet.id}"
  associate_public_ip_address = true
  vpc_security_group_ids = [ aws_security_group.instance.id ]
  user_data = <<-EOF
               # !/bin/bash
               echo "hello, world" > index.html
               nohup busybox httpd -f -p ${var.server_port} & 
              EOF

  tags={
    Name= "terraform.example"
  }

}

output "public_ip" {
  value = aws_instance.example.public_ip
  description = "The public IP address of the web server"
}