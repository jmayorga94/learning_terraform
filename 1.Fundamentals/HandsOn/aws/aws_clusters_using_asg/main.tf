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

variable "private_subnet" {
  type    = list
  default = ["192.168.2.0/25", "192.168.2.128/25"]
}


variable "private_vpc" {
  type    = string
  default = "192.168.2.0/24"
}

resource "aws_vpc" "vpc" {
  cidr_block           = "${var.private_vpc}"
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
  count = "${length(var.private_subnet)}"
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "${var.private_subnet[count.index]}"
  tags = {
    Name = "terraform.example"
  }
}


data "aws_vpc" "vpc"{
  id = aws_vpc.vpc.id
}

data "aws_subnet_ids" "subnet"{
  vpc_id = data.aws_vpc.vpc.id
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


resource "aws_security_group" "alb" {
  name        = "terraform-allow-inbound-lb"
  description = "Allow inbound traffic"
  vpc_id      = "${aws_vpc.vpc.id}"

 ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "80"
    to_port     = "80"
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


resource "aws_launch_configuration" "cluster_config" {
  image_id  = "ami-02f3416038bdb17fb"
  instance_type = "t2.micro"
  security_groups = [ aws_security_group.instance.id ]
  user_data = <<-EOF
               #!/bin/bash
               echo "hello, world" > index.html
               nohup busybox httpd -f -p ${var.server_port} 
               EOF

  #Required when using a launch configuration with an autoscaling group

  lifecycle {
    create_before_destroy = true
  }
 
}

resource "aws_autoscaling_group" "asg_dev" {
 launch_configuration = aws_launch_configuration.cluster_config.name
 vpc_zone_identifier = data.aws_subnet_ids.subnet.ids
 target_group_arns = [ aws_lb_target_group.asg.arn ]
 health_check_type = "ELB"
 min_size = 2  
 max_size = 10

 tag {
   key = "Name"
   value = "terrform-asg-example"
   propagate_at_launch = true

 }

}

resource "aws_lb" "lb-dev" {
  name = "lb-dev"
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.subnet.ids
  security_groups = [  aws_security_group.alb.id ]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.lb-dev.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_lb_target_group" "asg" {
  name = "tg-dev"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = aws_vpc.vpc.id
  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = 200
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
  
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}
output "alb_dns_name" {
  value = aws_lb.lb-dev.dns_name
  description = "The Domain name of the load balancer"
}