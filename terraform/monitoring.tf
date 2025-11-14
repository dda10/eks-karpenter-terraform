# Prometheus and Grafana Stack
resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  version          = "65.0.0"
  timeout          = 600
  wait             = true

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention = "30d"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp3"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "50Gi"
                  }
                }
              }
            }
          }
        }
      }
      grafana = {
        adminPassword = "admin"
        persistence = {
          enabled          = true
          storageClassName = "gp3"
          size             = "10Gi"
        }
        service = {
          type = "LoadBalancer"
        }
      }
      alertmanager = {
        alertmanagerSpec = {
          storage = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp3"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "10Gi"
                  }
                }
              }
            }
          }
        }
      }
    })
  ]

  depends_on = [module.eks]
}

# NVIDIA Device Plugin Helm Chart
resource "helm_release" "nvidia_device_plugin" {
  name       = "nvdp"
  repository = "https://nvidia.github.io/k8s-device-plugin"
  chart      = "nvidia-device-plugin"
  version    = "0.17.1"
  namespace  = "nvidia-device-plugin"

  create_namespace = true

  values = [
    yamlencode({
      gfd = {
        enabled = true
      }
      nfd = {
        enabled = true
      }
      affinity = {
        nodeAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = {
            nodeSelectorTerms = [
              {
                matchExpressions = [
                  {
                    key      = "karpenter.k8s.aws/instance-gpu-manufacturer"
                    operator = "In"
                    values   = ["nvidia"]
                  }
                ]
              }
            ]
          }
        }
      }
    })
  ]

  depends_on = [
    module.eks,
    module.karpenter
  ]
}

# Karpenter GPU NodeClass
resource "kubectl_manifest" "gpu_nodeclass" {
  yaml_body = templatefile("${path.module}/../manifest/karpenter/karpenter-nodeclass-gpu.yaml", {
    cluster_name       = var.cluster_name
    node_iam_role_name = module.karpenter.node_iam_role_name
  })

  depends_on = [
    module.karpenter,
    helm_release.nvidia_device_plugin
  ]
}

# Karpenter GPU NodePool
resource "kubectl_manifest" "gpu_nodepool" {
  yaml_body = file("${path.module}/../manifest/karpenter/karpenter-nodepool-gpu.yaml")

  depends_on = [
    kubectl_manifest.gpu_nodeclass
  ]
}


# NVIDIA DCGM Exporter for GPU Metrics
resource "helm_release" "dcgm_exporter" {
  name             = "dcgm-exporter"
  repository       = "https://nvidia.github.io/dcgm-exporter/helm-charts"
  chart            = "dcgm-exporter"
  namespace        = "monitoring"
  create_namespace = false
  version          = "3.4.2"
  timeout          = 300
  wait             = true

  values = [
    yamlencode({
      serviceMonitor = {
        enabled = true
      }
      nodeSelector = {
        "nvidia.com/gpu" = "true"
      }
    })
  ]

  depends_on = [helm_release.kube_prometheus_stack, helm_release.nvidia_device_plugin]
}
