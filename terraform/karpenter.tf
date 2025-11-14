# Karpenter Controller IAM Role
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.0"

  cluster_name          = module.eks.cluster_name
  enable_v1_permissions = true
  namespace             = "karpenter"

  create_node_iam_role            = true
  node_iam_role_name              = "karpenter-node-role"
  node_iam_role_use_name_prefix   = false
  create_pod_identity_association = true
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

# Karpenter Helm Release
resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.0.6"
  timeout    = 300
  wait       = true

  values = [
    <<-EOT
    nodeSelector:
      karpenter.sh/controller: 'true'
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    webhook:
      enabled: false
    EOT
  ]

  depends_on = [module.eks]
}

# GPU NodePool for Image Inference
resource "kubectl_manifest" "karpenter_nodepool_gpu" {
  yaml_body = file("${path.module}/../manifest/karpenter/karpenter-nodepool-gpu.yaml")

  depends_on = [helm_release.karpenter]
}

# GPU EC2NodeClass - Choose between AL2023 or Bottlerocket
resource "kubectl_manifest" "karpenter_nodeclass_gpu" {
  yaml_body = templatefile("${path.module}/../manifest/karpenter/karpenter-nodeclass-gpu-bottlerocket.yaml", {
    node_iam_role_name = module.karpenter.node_iam_role_name
    cluster_name       = var.cluster_name
  })

  depends_on = [helm_release.karpenter]
}
