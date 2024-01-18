# provider "aws" {
#   region = "us-west-2" # Change this to your desired AWS region
# }

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "eks-spot-cluster"
  subnets         = "subnet-0eff86e19581e95ec"
  vpc_id          = "vpc-021a2ac87501570e4" # Replace with your VPC ID
  cluster_version = "1.27"

  node_groups = {
    eks_nodes_spot = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1
      key_name         = "chandra" # Replace with your EC2 key pair name
      instance_type    = "m5.large"     # Replace with your desired instance type
      spot_price       = "0.0835"        # Replace with your desired spot price
    }
  }
}
