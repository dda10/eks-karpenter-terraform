data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# VPC Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = var.cluster_name
  }
}


# VPC Endpoints
module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.0"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service = "s3"
      tags    = { Name = "s3-vpc-endpoint" }
    }
    ec2 = {
      service            = "ec2"
      vpc_endpoint_type  = "Interface"
      subnet_ids         = module.vpc.private_subnets
      security_group_ids = [aws_security_group.vpc_endpoints.id]
      tags               = { Name = "ec2-vpc-endpoint" }
    }
    ecr_api = {
      service            = "ecr.api"
      vpc_endpoint_type  = "Interface"
      subnet_ids         = module.vpc.private_subnets
      security_group_ids = [aws_security_group.vpc_endpoints.id]
      tags               = { Name = "ecr-api-vpc-endpoint" }
    }
    ecr_dkr = {
      service            = "ecr.dkr"
      vpc_endpoint_type  = "Interface"
      subnet_ids         = module.vpc.private_subnets
      security_group_ids = [aws_security_group.vpc_endpoints.id]
      tags               = { Name = "ecr-dkr-vpc-endpoint" }
    }
  }
}

# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.cluster_name}-vpc-endpoints-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-vpc-endpoints-sg"
  }
}
