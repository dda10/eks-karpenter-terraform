variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1" # Changed to us-east-1 for G5 instance availability
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
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

variable "bastion_key_name" {
  description = "Existing EC2 key pair name for bastion host SSH access"
  type        = string
}
