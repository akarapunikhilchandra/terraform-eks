provider "aws" {
  region = "us-east-1"
}

locals {
  name   = "eks-spot-cluster"
  region = "us-east-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = ["us-east-1a", "us-east-1b"]

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]

  tags = {
    Example = local.name
  }
}

# Create ACM Certificate
resource "aws_acm_certificate" "eks_cluster_certificate" {
  domain_name       = "joindevops.cloud"
  validation_method = "DNS"

  tags = local.tags
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  public_subnets  = local.public_subnets

  enable_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.1"

  cluster_name                   = local.name
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.public_subnets

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type       = "ami-0f3c7d07486cad139"
    instance_types = ["m5.large"]

    attach_cluster_primary_security_group = true
  }

  eks_managed_node_groups = {
    eks-spot-cluster = {
      min_size     = 1
      max_size     = 2
      desired_size = 1

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"

      tags = {
        ExtraTag = "helloworld"
      }
    }
  }

  tags = local.tags
}
# Create ACM Certificate Validation Record
resource "aws_route53_record" "acm_validation" {
  count   = length(aws_acm_certificate.eks_cluster_certificate.domain_validation_options)

  name    = element(aws_acm_certificate.eks_cluster_certificate.domain_validation_options[*].resource_record_name, 0)
  type    = element(aws_acm_certificate.eks_cluster_certificate.domain_validation_options[*].resource_record_type, 0)
  zone_id = "Z0686921XP2M57OZO3Y7"
  records = [element(aws_acm_certificate.eks_cluster_certificate.domain_validation_options[*].resource_record_value, 0)]
  ttl     = 60
}

# Wait for ACM Certificate Validation
resource "aws_acm_certificate_validation" "eks_cluster_certificate_validation" {
  certificate_arn         = aws_acm_certificate.eks_cluster_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}

# Output ACM Certificate ARN
output "acm_certificate_arn" {
  value = aws_acm_certificate.eks_cluster_certificate.arn
}
