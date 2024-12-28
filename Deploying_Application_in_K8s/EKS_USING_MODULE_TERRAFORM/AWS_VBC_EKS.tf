provider "aws" {
  region = "eu-west-1"
}

variable vpc_sider_block {}
variable private_subnets_cidr_blocks {}
variable public_subnets_cidr_blocks {}

data "aws_avilability_zones" "azs" {
  
}

module "myapp_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name = "my-vpc"
  cidr = var.vpc_sider_block
  azs             = data.aws_avilability_zones.azs.names
  private_subnets = var.private_subnets_cidr_blocks
  public_subnets  = var.public_subnets_cidr_blocks
 
  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
     "kubernetes.io/role/elb" = 1

  }

  private_subnet_tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
     "kubernetes.io/role/internal-elb" = 1
  
  }



}