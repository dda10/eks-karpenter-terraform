variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-1" # Singapore region from your calculator
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "gpu-karpenter-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.33"
}

variable "enable_monitoring" {
  description = "Enable comprehensive monitoring stack"
  type        = bool
  default     = true
}

variable "bastion_public_key" {
  description = "Public key for bastion host SSH access"
  type        = string
  default     = "" # Add your public key here or via terraform.tfvars
}
