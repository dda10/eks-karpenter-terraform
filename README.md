# EKS with Karpenter for GPU Workloads

This Terraform project deploys EKS with Karpenter for cost-optimized GPU instances using spot pricing.

## Key Features

- **Official EKS Module**: Uses terraform-aws-modules/eks/aws
- **Built-in Karpenter**: Automatically configured with the module
- **Spot Instance Support**: Up to 70% cost savings
- **GPU Instance Types**: g5.xlarge, g5.2xlarge, g5.4xlarge (AMD64 only)
- **Fast Scaling**: Provisions nodes in ~30 seconds
- **Auto-termination**: Removes unused nodes after 5 minutes
- **Bottlerocket AMI**: Container-optimized OS with pre-installed NVIDIA components

## Prerequisites

- AWS CLI configured
- Terraform >= 1.0
- kubectl installed
- Helm installed

## Deployment

1. **Deploy everything with Terraform:**
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

2. **Configure kubectl:**
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name gpu-cluster
   ```

3. **Verify deployment:**
   ```bash
   # Check all components
   kubectl get pods -A
   kubectl get nodes -o wide
   kubectl get nodepool
   kubectl get ec2nodeclass
   
   # Check GPU resources (after nodes are provisioned)
   kubectl get nodes -o custom-columns="NAME:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu"
   ```

4. **Test GPU workload:**
   ```bash
   # Simple test pod
   kubectl apply -f manifest/test-workload/gpu-test-pod.yaml
   kubectl logs gpu-test
   
   # Or deployment with multiple replicas
   kubectl apply -f manifest/test-workload/gpu-workload-example.yaml
   ```

5. **Watch nodes scale:**
   ```bash
   kubectl get nodes -w
   ```

## GPU Node Configuration

**Bottlerocket AMI (Default):**
- Pre-includes NVIDIA device plugin, driver, toolkit
- No additional GPU operators needed
- Container-optimized, immutable OS
- Faster boot times and better security

**Alternative: AL2023 NVIDIA AMI:**
- Requires GPU Operator installation
- More flexible but needs additional setup
- To use: Change `karpenter-nodeclass-gpu-bottlerocket.yaml` to `karpenter-nodeclass-gpu-al2023.yaml` in `terraform/karpenter.tf`

## Kubernetes Version Compatibility

- **Kubernetes v1.34**: Compatible with NVIDIA device plugin v0.18.0+ when NFD is enabled
- **GPU AMI**: Uses latest Amazon EKS GPU-optimized AMI
- **CUDA Runtime**: Supports CUDA 12.0+ workloads

## Monitoring

```bash
# Check Karpenter logs
kubectl logs -f -n karpenter -l app.kubernetes.io/name=karpenter

# Check node provisioning
kubectl describe nodepool gpu-node-pool

# Check GPU availability
kubectl get nodes -o custom-columns=NAME:.metadata.name,GPU:.status.allocatable."nvidia\.com/gpu"
```

## Troubleshooting

**GPU resources not showing:**
1. Check if nodes are using Bottlerocket NVIDIA AMI
2. Verify GPU instance types are provisioned: `kubectl get nodes -o wide`
3. Check node labels: `kubectl get nodes --show-labels | grep nvidia`

**Pods stuck in Pending:**
1. Check node taints: `kubectl describe nodes | grep Taints`
2. Ensure tolerations are correct in pod spec
3. Check resource requests vs available GPU resources
4. Verify GPU nodes are properly provisioned

## Cleanup

```bash
kubectl delete -f manifest/test-workload/
terraform destroy
```
