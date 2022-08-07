#Deploy a single server

provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "example" {
  ami = "ami-02f3416038bdb17fb"
  instance_type = "t2.micro"
  subnet_id = "subnet-0f9c3ced536139c0c"
  tags={
    Name= "terraform.example"
  }

}