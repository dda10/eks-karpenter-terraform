# AWS Configuration
aws_region = "ap-southeast-1"

# EKS Cluster Configuration
cluster_name       = "gpu-karpenter-cluster"
kubernetes_version = "1.33"

# Monitoring
enable_monitoring = true

# Bastion Host Configuration
# Replace with your actual SSH public key
bastion_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... your-email@example.com"
