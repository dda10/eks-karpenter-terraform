# EKS Module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Enable OIDC for IRSA
  enable_irsa = true

  # Cluster access entry
  enable_cluster_creator_admin_permissions = true

  # Access entries for bastion host
  access_entries = {
    bastion = {
      principal_arn = aws_iam_role.bastion_role.arn
      type          = "STANDARD"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # Initial managed node group for Karpenter controller
  eks_managed_node_groups = {

    system-nodegroup = {
      use_name_prefix = false
      name            = "initial-nodegroup"
      instance_types  = ["t3.medium"]
      min_size        = 1
      max_size        = 3
      desired_size    = 2
      subnet_ids      = module.vpc.private_subnets

      labels = {
        "karpenter.sh/controller" = "true"
      }

      taints = {
        karpenter = {
          key    = "karpenter.sh/controller"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  # Tag node security group for Karpenter
  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }

  # Cluster endpoint configuration
  cluster_endpoint_public_access = true
  # Cluster logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # EKS Addons
  cluster_addons = {
    vpc-cni = {
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    kube-proxy = {
      before_compute = true
      most_recent    = true
    }
    coredns = {
      most_recent = true
      configuration_values = jsonencode({
        tolerations = [{
          key    = "karpenter.sh/controller"
          value  = "true"
          effect = "NoSchedule"
        }]
      })
    }
    aws-ebs-csi-driver = {
      addon_version = "v1.52.1-eksbuild.1"
    }
    aws-efs-csi-driver = {
      addon_version = "v2.1.13-eksbuild.1"
    }
    eks-pod-identity-agent = {
      before_compute = true
      most_recent    = true
    }
    metrics-server = {
      addon_version = "v0.8.0-eksbuild.3"
    }
    cert-manager = {
      addon_version = "v1.19.1-eksbuild.1"
    }
  }

  tags = {
    Environment                                 = "production"
    Terraform                                   = "true"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# EBS CSI Driver Pod Identity
resource "aws_eks_pod_identity_association" "ebs_csi" {
  cluster_name    = module.eks.cluster_name
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa"

  role_arn = aws_iam_role.ebs_csi_pod_identity.arn
}

resource "aws_iam_role" "ebs_csi_pod_identity" {
  name = "${var.cluster_name}-ebs-csi-pod-identity-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  role       = aws_iam_role.ebs_csi_pod_identity.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# EFS CSI Driver Pod Identity
resource "aws_eks_pod_identity_association" "efs_csi" {
  cluster_name    = module.eks.cluster_name
  namespace       = "kube-system"
  service_account = "efs-csi-controller-sa"

  role_arn = aws_iam_role.efs_csi_pod_identity.arn
}

resource "aws_iam_role" "efs_csi_pod_identity" {
  name = "${var.cluster_name}-efs-csi-pod-identity-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "efs_csi_policy" {
  role       = aws_iam_role.efs_csi_pod_identity.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
}


