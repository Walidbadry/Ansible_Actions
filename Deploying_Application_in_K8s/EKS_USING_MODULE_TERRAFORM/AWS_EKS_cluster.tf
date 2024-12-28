provider "kubernetes" {
  host = data.aws_eks_cluster.myapp_cluster.endpoint
  token = data.aws_eks_cluster_auth.myapp_cluster
  cluster_ca_certificate =base64decode(data.aws_eks_cluster.myapp_cluster.certeficat_authority.0.data)

}

data "aws_eks_cluster" "myapp_cluster" {
  name = module.eks.cluster_id
}
data "aws_eks_cluster_auth" "myapp_cluster" {
  name = module.eks.cluster_id
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "13.2.3"

  cluster_name    = "myapp-eks-cluster"
  cluster_version = "1.30"
  subnets = module.myapp_vpc.private_subnets
  vbc_id = module.myapp_vpc.vbc_id



  tags = {
    Environment = "dev"
    application   = "myapp"
  }

  worker_groups = [
    {
      instance_type = "t2.small"
      name = "worker-group-1"
      asg_max_size  = 2
    },
    {
      instance_type = "t2.medium"
      name = "worker-group-2"
      asg_max_size  = 1

    }
  ]





}