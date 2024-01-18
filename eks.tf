resource "aws_eks_cluster" "eks_spot_cluster" {
  name     = "eks-spot-cluster"
  role_arn = "arn:aws:iam::767398108107:role/eks-spot-cluster"

  vpc_config {
    subnet_ids = ["subnet-0eff86e19581e95ec"]
  }
}

data "external" "eks_node_group" {
  program = ["sh", "-c", "eksctl get nodegroup --cluster=${aws_eks_cluster.eks_spot_cluster.name} -o json | jq -r '.[].NodeGroupArn'"]

  depends_on = [aws_eks_cluster.eks_spot_cluster]
}

resource "aws_eks_node_group" "spot" {
  cluster_name    = aws_eks_cluster.eks_spot_cluster.name
  node_group_name = "spot"

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  instance_types = ["m5.large"]
  capacity_type  = "SPOT"
  node_role_arn  = ["data.external.eks_node_group.result"]

  remote_access {
    ec2_ssh_key = "chandra"
  }

  subnet_ids = ["subnet-0eff86e19581e95ec"]

  depends_on = [aws_eks_cluster.eks_spot_cluster]
}