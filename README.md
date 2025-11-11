# EKS with Karpenter for GPU Workloads (Using terraform-aws-modules)

This Terraform project deploys EKS with Karpenter using the official terraform-aws-modules for cost-optimized GPU instances (g5g.2xlarge).

## Key Features

- **Official EKS Module**: Uses terraform-aws-modules/eks/aws
- **Built-in Karpenter**: Automatically configured with the module
- **Spot Instance Support**: Up to 70% cost savings
- **Mixed Instance Types**: g5g.xlarge, g5g.2xlarge, g5g.4xlarge
- **Fast Scaling**: Provisions nodes in ~30 seconds
- **Auto-termination**: Removes unused nodes after 30s

## Prerequisites

- AWS CLI configured
- Terraform >= 1.0
- kubectl installed

## Deployment

1. **Deploy infrastructure:**
   ```bash
   cd eks-karpenter-terraform
   terraform init
   terraform plan
   terraform apply
   ```

2. **Configure kubectl:**
   ```bash
   aws eks update-kubeconfig --region ap-southeast-1 --name gpu-karpenter-cluster
   ```

3. **Verify Karpenter:**
   ```bash
   kubectl get pods -n karpenter
   kubectl get nodepool
   kubectl get ec2nodeclass
   ```

4. **Deploy GPU workload:**
   ```bash
   kubectl apply -f gpu-workload-example.yaml
   ```

5. **Watch nodes scale:**
   ```bash
   kubectl get nodes -w
   ```


## Pod Identity vs IRSA

**Pod Identity Benefits:**
- ✅ **Simpler Setup**: No OIDC provider annotations needed
- ✅ **Better Security**: Temporary credentials per pod
- ✅ **Easier Management**: Direct IAM role to ServiceAccount mapping
- ✅ **No Token Files**: No mounted JWT tokens in pods

**Configuration:**
```yaml
# With Pod Identity - Simple ServiceAccount
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-service-account
  # No annotations needed!

# vs IRSA - Requires annotations
metadata:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/MyRole
```

**Creating Pod Identity Associations:**
```bash
# Via AWS CLI
aws eks create-pod-identity-association \
  --cluster-name gpu-karpenter-cluster \
  --namespace default \
  --service-account my-service-account \
  --role-arn arn:aws:iam::ACCOUNT:role/MyRole
```

## Monitoring

```bash
# Check Karpenter logs
kubectl logs -f -n karpenter -l app.kubernetes.io/name=karpenter

# Check node provisioning
kubectl describe nodepool gpu-nodepool

# Check GPU availability
kubectl get nodes -o custom-columns=NAME:.metadata.name,GPU:.status.allocatable."nvidia\.com/gpu"
```

## Cleanup

```bash
kubectl delete -f gpu-workload-example.yaml
terraform destroy
```
