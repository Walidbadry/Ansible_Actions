# Define AWS provider and region
provider "aws" {
  region = "eu-west-3"  # Set your desired AWS region
  access_key = ""
  secret_key = ""
}

#variable 
variable vpc_sider_block {}
variable subnet_sider_block {}
variable avail_zone {}
variable enviromint {}
variable my_ip {}
variable instance_type{}
variable public_key_location{}
variable privet_key_location{}
variable "ssh_private_key" {}
# Define a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_sider_block  # Set your desired CIDR block for the VPC

  tags = {
    Name = "${var.enviromint}-vbc"   
  }
}

 
# Define a subnet within the VPC
resource "aws_subnet" "my_subnet" {
  vpc_id  = aws_vpc.my_vpc.id  # Reference the VPC created above
  cidr_block = var.subnet_sider_block  # Set your desired CIDR block for the VPC
  availability_zone = var.avail_zone  # Set your desired availability zone

  tags = {
    Name = "${var.enviromint}-subnet-1"  # Set your desired name for the VPC
  }
}

resource "aws_internet_gateway" "myapp_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "${var.enviromint}-igw-1"  # Set your desired name for the VPC
  }
}

//use defulte route table recource insted to creat one 
resource "aws_default_route_table" "main_rtb" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp_igw.id  # Replace with your Internet Gateway ID
  }

  tags = {
    Name = "main-route-table"
  }
}

 
resource "aws_default_security_group" "myapp_sg" {
  description = "Example security group"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks =  var.my_ip //evry one can access you should put one 178.191.192.1.1/32 
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks =["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # "-1" means all protocols
    cidr_blocks = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "de-security-group"
  }
}

data "aws_ami" "latest_amazon_linux_image"{
  most_recent = true
  owners = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

   filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}

output "aws_ami_id" {
  value  = data.aws_ami.latest_amazon_linux_image.id

}


# Output instance details
output "instance_public_ip" {
  value = aws_instance.my_instance.public_ip
}

# Create an AWS key pair using the generated public key
resource "aws_key_pair" "ssh-key" {
  key_name   = "deployer-key"
  //on termunal>@#ssh-keygen
  //on termunal>@$cat .ssh/id_rsa.pub
  //copy and past txt to public_key

  #public_key = var.my_pub_key
  //best_practice
  public_key = file(var.public_key_location)
    }




# Create an EC2 Instance
resource "aws_instance" "myapp_server" {
  ami           = data.aws_ami.latest_amazon_linux_image.id # Replace with your desired AMI ID
  instance_type = var.instance_type
  subnet_id              = aws_subnet.my_subnet.id 
  vpc_security_group_ids        = [aws_security_group.myapp_sg.id]
  associate_public_ip_address = true
  availability_zone = var.avail_zone
  #key_name =""  //for ssh you should downlode .pem file and put it in ~/ and do son restrection
  key_name = aws_key_pair.ssh-key.key_name
  
  tags = {
    Name = "main-instance"
  }
}
//to show ec2 attribute @#terraform state show aws_instance.myapp_server
output "aws_instance" {
  value  =aws_instance.myapp_server.public_ip

}


resource "null_recource" "configure_server" {
  triggers{
    trigger = aws_instance.myapp_server.public_ip
  }
  provisioner "local-exec" {
      working_dir = "I:\\DevOps Training\\Week 22 - 23 Configuration Management\\ansible\\_Run_Docker_applications_\\EC2_Ansible\\"
      command = "ansible_playbook --inventory ${aws_instance.myapp_server.public_ip}, --private_key = ${var.ssh_private_key} --user = ec2-user deploy_docker.yaml"
  
  }
}





//terraform plain >>to see the errors 
//terraform applay