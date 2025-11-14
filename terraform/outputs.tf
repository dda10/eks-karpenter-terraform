output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "bastion_public_ip" {
  description = "Bastion host public IP"
  value       = aws_instance.bastion.public_ip
}

output "kubeconfig_command" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "grafana_info" {
  description = "Grafana access information"
  value       = "Run: kubectl get svc -n monitoring kube-prometheus-stack-grafana | Default credentials: admin/admin"
}

output "nvidia_device_plugin_status" {
  description = "NVIDIA Device Plugin deployment status"
  value       = helm_release.nvidia_device_plugin.status
}

output "gpu_test_command" {
  description = "Command to test GPU workload"
  value       = "kubectl apply -f ../manifest/test-workload/gpu-test-pod.yaml && kubectl logs gpu-test"
}
